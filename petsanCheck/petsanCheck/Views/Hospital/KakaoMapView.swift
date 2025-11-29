//
//  KakaoMapView.swift
//  petsanCheck
//
//  Created on 2025-11-30.
//

import SwiftUI
import WebKit
import CoreLocation

/// 카카오맵 WebView
struct KakaoMapView: UIViewRepresentable {
    let apiKey: String
    @Binding var centerCoordinate: CLLocationCoordinate2D
    let hospitals: [Hospital]
    let onMarkerTap: ((Hospital) -> Void)?

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.preferences.javaScriptEnabled = true

        // 인라인 미디어 재생 설정
        configuration.allowsInlineMediaPlayback = true

        // 메시지 핸들러 등록
        configuration.userContentController.add(context.coordinator, name: "markerTapped")
        configuration.userContentController.add(context.coordinator, name: "consoleLog")

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false

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
        }
        """
        webView.evaluateJavaScript(script)

        // 마커 업데이트
        updateMarkers(webView)
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
                var markers = [];
                var currentMarker;

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
                        console.log('Creating map...');
                        var mapContainer = document.getElementById('map');
                        var mapOption = {
                            center: new kakao.maps.LatLng(\(centerCoordinate.latitude), \(centerCoordinate.longitude)),
                            level: 5
                        };

                        map = new kakao.maps.Map(mapContainer, mapOption);
                        console.log('Map created successfully');
                    } catch (e) {
                        console.log('Error creating map: ' + e.message);
                    }
                }

                function clearMarkers() {
                    if (!map) {
                        console.log('clearMarkers: map not ready');
                        return;
                    }
                    markers.forEach(marker => marker.setMap(null));
                    markers = [];
                }

                function addMarker(lat, lng, title, id) {
                    if (!map) {
                        console.log('addMarker: map not ready');
                        return;
                    }

                    try {
                        var position = new kakao.maps.LatLng(lat, lng);
                        var marker = new kakao.maps.Marker({
                            position: position,
                            map: map
                        });

                        var infowindow = new kakao.maps.InfoWindow({
                            content: '<div style="padding:5px;font-size:12px;">' + title + '</div>'
                        });

                        kakao.maps.event.addListener(marker, 'mouseover', function() {
                            infowindow.open(map, marker);
                        });

                        kakao.maps.event.addListener(marker, 'mouseout', function() {
                            infowindow.close();
                        });

                        kakao.maps.event.addListener(marker, 'click', function() {
                            if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.markerTapped) {
                                window.webkit.messageHandlers.markerTapped.postMessage(id);
                            }
                        });

                        markers.push(marker);
                    } catch (e) {
                        console.log('Error adding marker: ' + e.message);
                    }
                }

                // 현재 위치 마커
                function setCurrentLocation(lat, lng) {
                    if (!map) {
                        console.log('setCurrentLocation: map not ready');
                        return;
                    }

                    try {
                        // 기존 마커 제거
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

    private func updateMarkers(_ webView: WKWebView) {
        var script = "clearMarkers();\n"

        for hospital in hospitals {
            let title = hospital.name.replacingOccurrences(of: "'", with: "\\'")
            script += "addMarker(\(hospital.latitude), \(hospital.longitude), '\(title)', '\(hospital.id)');\n"
        }

        script += "setCurrentLocation(\(centerCoordinate.latitude), \(centerCoordinate.longitude));"

        webView.evaluateJavaScript(script)
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: KakaoMapView

        init(_ parent: KakaoMapView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // 지도 로드 완료 후 마커 업데이트 (약간의 딜레이)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.parent.updateMarkers(webView)
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("KakaoMapView navigation failed: \(error.localizedDescription)")
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("KakaoMapView provisional navigation failed: \(error.localizedDescription)")
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "consoleLog" {
                print("[KakaoMap JS] \(message.body)")
            } else if message.name == "markerTapped",
                      let hospitalId = message.body as? String,
                      let hospital = parent.hospitals.first(where: { $0.id == hospitalId }) {
                parent.onMarkerTap?(hospital)
            }
        }
    }
}

// MARK: - Preview
struct KakaoMapView_Previews: PreviewProvider {
    static var previews: some View {
        KakaoMapView(
            apiKey: "9e8b18c55ec9d4441317124e6ecf84b6",
            centerCoordinate: .constant(CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)),
            hospitals: Hospital.previews,
            onMarkerTap: nil
        )
    }
}
