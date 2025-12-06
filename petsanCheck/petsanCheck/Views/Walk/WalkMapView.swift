//
//  WalkMapView.swift
//  petsanCheck
//
//  Created on 2025-11-30.
//

import SwiftUI
import WebKit
import CoreLocation

/// 산책 지도 WebView (인라인 HTML 방식)
struct WalkMapView: UIViewRepresentable {
    @Binding var centerCoordinate: CLLocationCoordinate2D
    let routeCoordinates: [CLLocationCoordinate2D]

    // 카카오맵 JavaScript 키
    private let kakaoMapKey = "15f699809884fac6f0315c89eba0db32"

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()

        // JavaScript 설정
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = preferences
        configuration.allowsInlineMediaPlayback = true

        // 메시지 핸들러 등록
        configuration.userContentController.add(context.coordinator, name: "consoleLog")
        configuration.userContentController.add(context.coordinator, name: "mapReady")

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false

        // 디버깅 활성화
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }

        // 인라인 HTML 로드
        let html = createMapHTML()
        webView.loadHTMLString(html, baseURL: nil)

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // 지도가 로드되지 않았으면 무시
        guard context.coordinator.isMapReady else { return }

        // 현재 위치 마커 항상 업데이트
        let locationScript = "setCurrentLocation(\(centerCoordinate.latitude), \(centerCoordinate.longitude));"
        webView.evaluateJavaScript(locationScript)

        // 경로 업데이트
        updateRoute(webView, context: context)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    private func updateRoute(_ webView: WKWebView, context: Context) {
        if routeCoordinates.isEmpty {
            webView.evaluateJavaScript("clearRoute();")
            return
        }

        // 이전 경로와 비교하여 새로운 포인트만 추가 (성능 최적화)
        let lastUpdateCount = context.coordinator.lastRouteCount

        if routeCoordinates.count > lastUpdateCount {
            if lastUpdateCount == 0 {
                // 첫 경로 설정
                let coordinates = routeCoordinates.map { coord in
                    ["latitude": coord.latitude, "longitude": coord.longitude]
                }

                if let jsonData = try? JSONSerialization.data(withJSONObject: coordinates, options: []),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    let script = "setRoute('\(jsonString)');"
                    webView.evaluateJavaScript(script)
                }
            } else {
                // 새 포인트 추가
                let newCoordinates = Array(routeCoordinates.suffix(from: lastUpdateCount))
                for coord in newCoordinates {
                    let script = "addRoutePoint(\(coord.latitude), \(coord.longitude));"
                    webView.evaluateJavaScript(script)
                }
            }

            context.coordinator.lastRouteCount = routeCoordinates.count
        }
    }

    private func createMapHTML() -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <title>Walk Map</title>
            <style>
                * { margin: 0; padding: 0; }
                html, body { width: 100%; height: 100%; overflow: hidden; }
                #map { width: 100%; height: 100%; }

                /* 현재 위치 마커 스타일 */
                .current-location-marker {
                    width: 24px;
                    height: 24px;
                    position: relative;
                }
                .current-location-marker .pulse {
                    position: absolute;
                    width: 24px;
                    height: 24px;
                    border-radius: 50%;
                    background: rgba(66, 133, 244, 0.3);
                    animation: pulse 2s ease-out infinite;
                }
                .current-location-marker .dot {
                    position: absolute;
                    top: 50%;
                    left: 50%;
                    transform: translate(-50%, -50%);
                    width: 14px;
                    height: 14px;
                    background: #4285F4;
                    border: 3px solid white;
                    border-radius: 50%;
                    box-shadow: 0 2px 6px rgba(0,0,0,0.3);
                }
                @keyframes pulse {
                    0% { transform: scale(1); opacity: 1; }
                    100% { transform: scale(2.5); opacity: 0; }
                }
            </style>
        </head>
        <body>
            <div id="map"></div>
            <script src="https://dapi.kakao.com/v2/maps/sdk.js?appkey=\(kakaoMapKey)&autoload=false"></script>
            <script>
                var map = null;
                var currentLocationMarker = null;
                var routePolyline = null;
                var routeCoordinates = [];
                var startMarker = null;

                function log(msg) {
                    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.consoleLog) {
                        window.webkit.messageHandlers.consoleLog.postMessage(msg);
                    }
                }

                kakao.maps.load(function() {
                    log('Kakao Maps SDK loaded');

                    var container = document.getElementById('map');
                    var options = {
                        center: new kakao.maps.LatLng(37.5665, 126.9780),
                        level: 3
                    };

                    map = new kakao.maps.Map(container, options);
                    log('Map initialized');

                    // 맵 준비 완료 알림
                    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.mapReady) {
                        window.webkit.messageHandlers.mapReady.postMessage('ready');
                    }
                });

                // 지도 중심 이동
                function setCenter(lat, lng) {
                    if (!map) return;
                    var position = new kakao.maps.LatLng(lat, lng);
                    map.panTo(position);
                }

                // 현재 위치 마커 표시/업데이트
                function setCurrentLocation(lat, lng) {
                    if (!map) return;

                    var position = new kakao.maps.LatLng(lat, lng);

                    if (currentLocationMarker) {
                        currentLocationMarker.setPosition(position);
                    } else {
                        // 커스텀 오버레이로 현재 위치 마커 생성
                        var content = '<div class="current-location-marker">' +
                                      '<div class="pulse"></div>' +
                                      '<div class="dot"></div>' +
                                      '</div>';

                        currentLocationMarker = new kakao.maps.CustomOverlay({
                            position: position,
                            content: content,
                            yAnchor: 0.5,
                            xAnchor: 0.5
                        });
                        currentLocationMarker.setMap(map);
                        log('Current location marker created');
                    }
                }

                // 경로 설정
                function setRoute(coordsJson) {
                    if (!map) return;

                    try {
                        var coords = JSON.parse(coordsJson);
                        routeCoordinates = coords.map(function(c) {
                            return new kakao.maps.LatLng(c.latitude, c.longitude);
                        });

                        // 기존 폴리라인 제거
                        if (routePolyline) {
                            routePolyline.setMap(null);
                        }

                        // 새 폴리라인 생성
                        routePolyline = new kakao.maps.Polyline({
                            path: routeCoordinates,
                            strokeWeight: 5,
                            strokeColor: '#4285F4',
                            strokeOpacity: 0.8,
                            strokeStyle: 'solid'
                        });
                        routePolyline.setMap(map);

                        // 시작점 마커
                        if (coords.length > 0) {
                            if (startMarker) {
                                startMarker.setMap(null);
                            }
                            startMarker = new kakao.maps.Marker({
                                position: routeCoordinates[0],
                                map: map
                            });
                        }

                        log('Route set with ' + coords.length + ' points');
                    } catch (e) {
                        log('Error setting route: ' + e.message);
                    }
                }

                // 경로에 포인트 추가
                function addRoutePoint(lat, lng) {
                    if (!map) return;

                    var position = new kakao.maps.LatLng(lat, lng);
                    routeCoordinates.push(position);

                    if (routePolyline) {
                        routePolyline.setPath(routeCoordinates);
                    } else {
                        routePolyline = new kakao.maps.Polyline({
                            path: routeCoordinates,
                            strokeWeight: 5,
                            strokeColor: '#4285F4',
                            strokeOpacity: 0.8,
                            strokeStyle: 'solid'
                        });
                        routePolyline.setMap(map);
                    }
                }

                // 경로 지우기
                function clearRoute() {
                    if (routePolyline) {
                        routePolyline.setMap(null);
                        routePolyline = null;
                    }
                    if (startMarker) {
                        startMarker.setMap(null);
                        startMarker = null;
                    }
                    routeCoordinates = [];
                    log('Route cleared');
                }
            </script>
        </body>
        </html>
        """
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: WalkMapView
        var isMapReady = false
        var lastRouteCount = 0

        init(_ parent: WalkMapView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("Walk map loaded successfully")

            // 지도 로드 완료 후 초기화
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self = self else { return }
                self.isMapReady = true
                self.lastRouteCount = 0

                // 초기 위치 설정 및 현재 위치 마커 표시
                let lat = self.parent.centerCoordinate.latitude
                let lng = self.parent.centerCoordinate.longitude

                let script = """
                    setCenter(\(lat), \(lng));
                    setCurrentLocation(\(lat), \(lng));
                """
                webView.evaluateJavaScript(script)

                // 경로가 있으면 그리기
                if !self.parent.routeCoordinates.isEmpty {
                    self.initialRouteSetup(webView)
                }
            }
        }

        private func initialRouteSetup(_ webView: WKWebView) {
            let coordinates = parent.routeCoordinates.map { coord in
                ["latitude": coord.latitude, "longitude": coord.longitude]
            }

            if let jsonData = try? JSONSerialization.data(withJSONObject: coordinates, options: []),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                let script = "setRoute('\(jsonString)');"
                webView.evaluateJavaScript(script)
                lastRouteCount = parent.routeCoordinates.count
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("WalkMapView navigation failed: \(error.localizedDescription)")
            isMapReady = false
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("WalkMapView provisional navigation failed: \(error.localizedDescription)")
            isMapReady = false
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "consoleLog" {
                print("[WalkMap JS] \(message.body)")
            } else if message.name == "mapReady" {
                print("[WalkMap] Map is ready")
                isMapReady = true
            }
        }
    }
}

// MARK: - Preview
struct WalkMapView_Previews: PreviewProvider {
    static var previews: some View {
        WalkMapView(
            centerCoordinate: .constant(CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)),
            routeCoordinates: []
        )
    }
}
