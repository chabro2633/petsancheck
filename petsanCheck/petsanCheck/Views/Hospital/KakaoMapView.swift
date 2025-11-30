//
//  KakaoMapView.swift
//  petsanCheck
//
//  Created on 2025-11-30.
//

import SwiftUI
import WebKit
import CoreLocation

/// 카카오맵 WebView (원격 호스팅 방식)
struct KakaoMapView: UIViewRepresentable {
    @Binding var centerCoordinate: CLLocationCoordinate2D
    let hospitals: [Hospital]
    let onMarkerTap: ((Hospital) -> Void)?

    // Kakao Maps API Key
    private let apiKey = "7589dee627ab42200d739296c5c46df5"

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.preferences.javaScriptEnabled = true
        configuration.allowsInlineMediaPlayback = true

        // 메시지 핸들러 등록
        configuration.userContentController.add(context.coordinator, name: "markerTapped")
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
                var markers = [];
                var currentMarker;

                window.addEventListener('load', function() {
                    try {
                        document.getElementById('loading').style.display = 'none';

                        var mapContainer = document.getElementById('map');
                        var mapOption = {
                            center: new kakao.maps.LatLng(\(centerCoordinate.latitude), \(centerCoordinate.longitude)),
                            level: 5
                        };

                        map = new kakao.maps.Map(mapContainer, mapOption);
                        console.log('Hospital map initialized');

                        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.consoleLog) {
                            window.webkit.messageHandlers.consoleLog.postMessage('Map loaded successfully');
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

                function clearMarkers() {
                    if (!map) return;
                    markers.forEach(marker => marker.setMap(null));
                    markers = [];
                }

                function addMarker(lat, lng, title, id) {
                    if (!map) return;

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

        // 마커 업데이트
        updateMarkers(webView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
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
            print("Hospital map loaded successfully from remote URL")
            // 지도 로드 완료 후 마커 업데이트
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
            centerCoordinate: .constant(CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)),
            hospitals: Hospital.previews,
            onMarkerTap: nil
        )
    }
}
