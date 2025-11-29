//
//  WalkMapView.swift
//  petsanCheck
//
//  Created on 2025-11-30.
//

import SwiftUI
import WebKit
import CoreLocation

/// 산책용 카카오맵 WebView (경로 추적 기능 포함)
struct WalkMapView: UIViewRepresentable {
    let apiKey: String
    @Binding var centerCoordinate: CLLocationCoordinate2D
    let routeCoordinates: [CLLocationCoordinate2D]

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.preferences.javaScriptEnabled = true

        // 인라인 미디어 재생 설정
        configuration.allowsInlineMediaPlayback = true

        // 메시지 핸들러 등록
        configuration.userContentController.add(context.coordinator, name: "consoleLog")

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = true
        webView.scrollView.bounces = true

        // 디버깅 활성화 (iOS 16.4+)
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }

        // HTML 로드
        let html = generateHTML()
        webView.loadHTMLString(html, baseURL: nil)

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // 지도 중심 변경
        let script = """
        if (typeof map !== 'undefined') {
            var moveLatLon = new kakao.maps.LatLng(\(centerCoordinate.latitude), \(centerCoordinate.longitude));
            map.setCenter(moveLatLon);

            // 현재 위치 마커 업데이트
            updateCurrentLocation(\(centerCoordinate.latitude), \(centerCoordinate.longitude));
        }
        """
        webView.evaluateJavaScript(script)

        // 경로 업데이트
        if !routeCoordinates.isEmpty {
            updateRoute(webView)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
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
            </style>
        </head>
        <body>
            <div id="map"></div>
            <script>
                // 콘솔 로그를 네이티브로 전달
                console.log = function(message) {
                    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.consoleLog) {
                        window.webkit.messageHandlers.consoleLog.postMessage(String(message));
                    }
                };

                console.error = console.log;

                window.onerror = function(msg, url, line, col, error) {
                    console.log('Error: ' + msg + ' at line ' + line);
                    return false;
                };
            </script>
            <script type="text/javascript" src="https://dapi.kakao.com/v2/maps/sdk.js?appkey=\(apiKey)&autoload=false"></script>
            <script>
                console.log('Kakao Maps SDK script tag loaded');

                var map;
                var polyline;
                var currentLocationMarker;

                // SDK 초기화 대기
                if (window.kakao && window.kakao.maps) {
                    console.log('kakao.maps already available, loading...');
                    kakao.maps.load(initializeMap);
                } else {
                    console.log('Waiting for kakao.maps to load...');
                    // SDK 로딩 재시도
                    var checkKakao = setInterval(function() {
                        if (window.kakao && window.kakao.maps) {
                            clearInterval(checkKakao);
                            console.log('kakao.maps now available, loading...');
                            kakao.maps.load(initializeMap);
                        }
                    }, 100);
                }

                function initializeMap() {
                    try {
                        console.log('Creating walk map...');
                        var mapContainer = document.getElementById('map');
                        var mapOption = {
                            center: new kakao.maps.LatLng(\(centerCoordinate.latitude), \(centerCoordinate.longitude)),
                            level: 3
                        };

                        map = new kakao.maps.Map(mapContainer, mapOption);
                        console.log('Walk map created successfully');

                        // 초기 폴리라인 생성
                        polyline = new kakao.maps.Polyline({
                            path: [],
                            strokeWeight: 5,
                            strokeColor: '#0066FF',
                            strokeOpacity: 0.8,
                            strokeStyle: 'solid'
                        });
                        polyline.setMap(map);
                        console.log('Polyline created');
                    } catch (e) {
                        console.log('Error creating walk map: ' + e.message);
                    }
                }

                // 경로 업데이트
                function updateRoute(coordinates) {
                    if (!map || !polyline) {
                        console.log('updateRoute: map or polyline not ready');
                        return;
                    }

                    try {
                        var path = coordinates.map(function(coord) {
                            return new kakao.maps.LatLng(coord.lat, coord.lng);
                        });

                        polyline.setPath(path);
                        console.log('Route updated with ' + coordinates.length + ' points');
                    } catch (e) {
                        console.log('Error updating route: ' + e.message);
                    }
                }

                // 현재 위치 마커 업데이트
                function updateCurrentLocation(lat, lng) {
                    if (!map) {
                        console.log('updateCurrentLocation: map not ready');
                        return;
                    }

                    try {
                        // 기존 마커 제거
                        if (currentLocationMarker) {
                            currentLocationMarker.setMap(null);
                        }

                        var position = new kakao.maps.LatLng(lat, lng);

                        // 파란색 원형 마커 생성
                        var imageSrc = 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjQiIGhlaWdodD0iMjQiIHZpZXdCb3g9IjAgMCAyNCAyNCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48Y2lyY2xlIGN4PSIxMiIgY3k9IjEyIiByPSIxMCIgZmlsbD0iIzAwNjZGRiIgZmlsbC1vcGFjaXR5PSIwLjMiLz48Y2lyY2xlIGN4PSIxMiIgY3k9IjEyIiByPSI2IiBmaWxsPSIjMDA2NkZGIi8+PGNpcmNsZSBjeD0iMTIiIGN5PSIxMiIgcj0iMyIgZmlsbD0id2hpdGUiLz48L3N2Zz4=';
                        var imageSize = new kakao.maps.Size(24, 24);
                        var markerImage = new kakao.maps.MarkerImage(imageSrc, imageSize);

                        currentLocationMarker = new kakao.maps.Marker({
                            position: position,
                            image: markerImage,
                            map: map
                        });
                    } catch (e) {
                        console.log('Error updating current location: ' + e.message);
                    }
                }
            </script>
        </body>
        </html>
        """
    }

    private func updateRoute(_ webView: WKWebView) {
        let coordinates = routeCoordinates.map { coord in
            "{lat: \(coord.latitude), lng: \(coord.longitude)}"
        }.joined(separator: ", ")

        let script = """
        if (typeof updateRoute !== 'undefined') {
            updateRoute([\(coordinates)]);
        }
        """

        webView.evaluateJavaScript(script)
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: WalkMapView

        init(_ parent: WalkMapView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // 지도 로드 완료 후 초기 위치 및 경로 설정 (약간의 딜레이)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if !self.parent.routeCoordinates.isEmpty {
                    self.parent.updateRoute(webView)
                }
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
            apiKey: "9e8b18c55ec9d4441317124e6ecf84b6",
            centerCoordinate: .constant(CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)),
            routeCoordinates: [
                CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
                CLLocationCoordinate2D(latitude: 37.5675, longitude: 126.9790),
                CLLocationCoordinate2D(latitude: 37.5685, longitude: 126.9800)
            ]
        )
    }
}
