//
//  KakaoMapView.swift
//  petsanCheck
//
//  Created on 2025-11-30.
//

import SwiftUI
import WebKit
import CoreLocation

/// 카카오맵 WebView (인라인 HTML 방식)
struct KakaoMapView: UIViewRepresentable {
    @Binding var centerCoordinate: CLLocationCoordinate2D
    let hospitals: [Hospital]
    let onMarkerTap: ((Hospital) -> Void)?
    var currentLocation: CLLocationCoordinate2D?

    // 카카오맵 JavaScript 키
    private let kakaoMapKey = "15f699809884fac6f0315c89eba0db32"

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()

        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = preferences
        configuration.allowsInlineMediaPlayback = true

        // 메시지 핸들러 등록
        configuration.userContentController.add(context.coordinator, name: "markerTapped")
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
        guard context.coordinator.isMapReady else { return }

        // 지도 중심 변경
        let script = "setCenter(\(centerCoordinate.latitude), \(centerCoordinate.longitude));"
        webView.evaluateJavaScript(script)

        // 현재 위치 마커 업데이트
        if let location = currentLocation {
            let locationScript = "setCurrentLocation(\(location.latitude), \(location.longitude));"
            webView.evaluateJavaScript(locationScript)
        }

        // 마커 업데이트 (병원 목록이 변경된 경우에만)
        if context.coordinator.lastHospitalCount != hospitals.count {
            updateMarkers(webView, context: context)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    private func updateMarkers(_ webView: WKWebView, context: Context) {
        updateMarkersWithCoordinator(webView, coordinator: context.coordinator)
    }

    private func updateMarkersWithCoordinator(_ webView: WKWebView, coordinator: Coordinator) {
        var script = "clearMarkers();\n"

        for hospital in hospitals {
            let title = hospital.name.replacingOccurrences(of: "'", with: "\\'")
            script += "addMarker(\(hospital.latitude), \(hospital.longitude), '\(title)', '\(hospital.id)');\n"
        }

        webView.evaluateJavaScript(script)
        coordinator.lastHospitalCount = hospitals.count
    }

    private func createMapHTML() -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <title>Hospital Map</title>
            <style>
                * { margin: 0; padding: 0; }
                html, body { width: 100%; height: 100%; overflow: hidden; }
                #map { width: 100%; height: 100%; }

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
                var markers = [];
                var currentLocationMarker = null;

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
                        level: 5
                    };

                    map = new kakao.maps.Map(container, options);
                    log('Map initialized');

                    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.mapReady) {
                        window.webkit.messageHandlers.mapReady.postMessage('ready');
                    }
                });

                function setCenter(lat, lng) {
                    if (!map) return;
                    var position = new kakao.maps.LatLng(lat, lng);
                    map.panTo(position);
                }

                function setCurrentLocation(lat, lng) {
                    if (!map) return;

                    var position = new kakao.maps.LatLng(lat, lng);

                    if (currentLocationMarker) {
                        currentLocationMarker.setPosition(position);
                    } else {
                        var content = '<div class="current-location-marker">' +
                                      '<div class="pulse"></div>' +
                                      '<div class="dot"></div>' +
                                      '</div>';

                        currentLocationMarker = new kakao.maps.CustomOverlay({
                            position: position,
                            content: content,
                            yAnchor: 0.5,
                            xAnchor: 0.5,
                            zIndex: 10
                        });
                        currentLocationMarker.setMap(map);
                        log('Current location marker created');
                    }
                }

                function addMarker(lat, lng, title, id) {
                    if (!map) return;

                    var position = new kakao.maps.LatLng(lat, lng);

                    // 병원 마커 이미지
                    var imageSrc = 'https://t1.daumcdn.net/localimg/localimages/07/mapapidoc/markerStar.png';
                    var imageSize = new kakao.maps.Size(24, 35);
                    var markerImage = new kakao.maps.MarkerImage(imageSrc, imageSize);

                    var marker = new kakao.maps.Marker({
                        position: position,
                        title: title,
                        image: markerImage
                    });

                    marker.setMap(map);
                    markers.push(marker);

                    kakao.maps.event.addListener(marker, 'click', function() {
                        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.markerTapped) {
                            window.webkit.messageHandlers.markerTapped.postMessage(id);
                        }
                    });
                }

                function clearMarkers() {
                    for (var i = 0; i < markers.length; i++) {
                        markers[i].setMap(null);
                    }
                    markers = [];
                }
            </script>
        </body>
        </html>
        """
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: KakaoMapView
        var isMapReady = false
        var lastHospitalCount = 0

        init(_ parent: KakaoMapView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("Hospital map loaded successfully")

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self = self else { return }
                self.isMapReady = true

                // 초기 위치 설정
                let lat = self.parent.centerCoordinate.latitude
                let lng = self.parent.centerCoordinate.longitude

                var script = "setCenter(\(lat), \(lng));"

                // 현재 위치 마커
                if let location = self.parent.currentLocation {
                    script += "setCurrentLocation(\(location.latitude), \(location.longitude));"
                }

                webView.evaluateJavaScript(script)

                // 병원 마커 추가
                self.parent.updateMarkersWithCoordinator(webView, coordinator: self)
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
            } else if message.name == "mapReady" {
                isMapReady = true
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
            onMarkerTap: nil,
            currentLocation: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)
        )
    }
}
