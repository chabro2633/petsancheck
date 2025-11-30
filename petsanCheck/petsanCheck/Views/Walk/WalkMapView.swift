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

    // Kakao Maps API Key
    private let apiKey = "7589dee627ab42200d739296c5c46df5"

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.preferences.javaScriptEnabled = true
        configuration.allowsInlineMediaPlayback = true

        // 메시지 핸들러 등록
        configuration.userContentController.add(context.coordinator, name: "consoleLog")

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false

        // 디버깅 활성화
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }

        // HTML 직접 로드
        let html = generateHTML()
        webView.loadHTMLString(html, baseURL: URL(string: "https://dapi.kakao.com"))

        return webView
    }

    private func generateHTML() -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
                * { margin: 0; padding: 0; }
                html, body { width: 100%; height: 100%; }
                #map { width: 100%; height: 100%; }
                #loading {
                    position: absolute;
                    top: 50%;
                    left: 50%;
                    transform: translate(-50%, -50%);
                    font-family: -apple-system;
                    color: #666;
                }
            </style>
        </head>
        <body>
            <div id="map"></div>
            <div id="loading">지도 로딩 중...</div>
            <script type="text/javascript" src="https://dapi.kakao.com/v2/maps/sdk.js?appkey=\(apiKey)"></script>
            <script>
                var map;
                var polyline;
                var currentMarker;

                window.addEventListener('load', function() {
                    try {
                        document.getElementById('loading').style.display = 'none';

                        var mapContainer = document.getElementById('map');
                        var mapOption = {
                            center: new kakao.maps.LatLng(\(centerCoordinate.latitude), \(centerCoordinate.longitude)),
                            level: 3
                        };

                        map = new kakao.maps.Map(mapContainer, mapOption);

                        polyline = new kakao.maps.Polyline({
                            path: [],
                            strokeWeight: 5,
                            strokeColor: '#0066FF',
                            strokeOpacity: 0.8,
                            strokeStyle: 'solid'
                        });
                        polyline.setMap(map);

                        console.log('Walk map initialized');

                        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.consoleLog) {
                            window.webkit.messageHandlers.consoleLog.postMessage('Walk map loaded successfully');
                        }
                    } catch (e) {
                        document.getElementById('loading').innerHTML = '지도 로딩 실패: ' + e.message;
                        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.consoleLog) {
                            window.webkit.messageHandlers.consoleLog.postMessage('Error: ' + e.message);
                        }
                    }
                });

                function setCenter(lat, lng) {
                    if (!map) return;
                    var moveLatLon = new kakao.maps.LatLng(lat, lng);
                    map.setCenter(moveLatLon);
                }

                function addRoutePoint(lat, lng) {
                    if (!map || !polyline) return;

                    try {
                        var path = polyline.getPath();
                        path.push(new kakao.maps.LatLng(lat, lng));
                        polyline.setPath(path);
                    } catch (e) {
                        console.log('Error adding route point: ' + e.message);
                    }
                }

                function clearRoute() {
                    if (!polyline) return;
                    polyline.setPath([]);
                }

                function setRoute(coordinatesJson) {
                    if (!map || !polyline) return;

                    try {
                        var coordinates = JSON.parse(coordinatesJson);
                        var path = coordinates.map(function(coord) {
                            return new kakao.maps.LatLng(coord.latitude, coord.longitude);
                        });
                        polyline.setPath(path);

                        if (path.length > 0) {
                            var bounds = new kakao.maps.LatLngBounds();
                            path.forEach(function(point) {
                                bounds.extend(point);
                            });
                            map.setBounds(bounds);
                        }
                    } catch (e) {
                        console.log('Error setting route: ' + e.message);
                    }
                }

                function setCurrentLocation(lat, lng) {
                    if (!map) return;

                    try {
                        if (currentMarker) {
                            currentMarker.setMap(null);
                        }

                        var position = new kakao.maps.LatLng(lat, lng);
                        var imageSrc = 'https://t1.daumcdn.net/localimg/localimages/07/mapapidoc/markerStar.png';
                        var imageSize = new kakao.maps.Size(24, 35);
                        var markerImage = new kakao.maps.MarkerImage(imageSrc, imageSize);

                        currentMarker = new kakao.maps.Marker({
                            position: position,
                            image: markerImage,
                            map: map
                        });
                    } catch (e) {
                        console.log('Error setting current location: ' + e.message);
                    }
                }
            </script>
        </body>
        </html>
        """
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // 지도 중심 변경
        let script = "setCenter(\(centerCoordinate.latitude), \(centerCoordinate.longitude));"
        webView.evaluateJavaScript(script)

        // 경로 업데이트
        updateRoute(webView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    private func updateRoute(_ webView: WKWebView) {
        guard !routeCoordinates.isEmpty else {
            webView.evaluateJavaScript("clearRoute();")
            return
        }

        // 좌표 배열을 JSON으로 변환
        let coordinates = routeCoordinates.map { coord in
            ["latitude": coord.latitude, "longitude": coord.longitude]
        }

        if let jsonData = try? JSONSerialization.data(withJSONObject: coordinates, options: []),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            let script = "setRoute('\(jsonString)');"
            webView.evaluateJavaScript(script)
        }

        // 현재 위치 마커 표시
        if let last = routeCoordinates.last {
            let script = "setCurrentLocation(\(last.latitude), \(last.longitude));"
            webView.evaluateJavaScript(script)
        }
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: WalkMapView

        init(_ parent: WalkMapView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("Walk map loaded successfully from remote URL")
            // 지도 로드 완료 후 경로 업데이트
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.parent.updateRoute(webView)
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("WalkMapView navigation failed: \(error.localizedDescription)")
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("WalkMapView provisional navigation failed: \(error.localizedDescription)")
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "consoleLog" {
                print("[WalkMap JS] \(message.body)")
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
