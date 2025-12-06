//
//  KakaoMapView.swift
//  petsanCheck
//
//  Created on 2025-11-30.
//

import SwiftUI
import WebKit
import CoreLocation

/// 카카오맵 WebView (병원용)
struct KakaoMapView: UIViewRepresentable {
    @Binding var centerCoordinate: CLLocationCoordinate2D
    let hospitals: [Hospital]
    let onMarkerTap: ((Hospital) -> Void)?
    var currentLocation: CLLocationCoordinate2D?

    // 카카오맵 JavaScript 키 (Info.plist에서 로드)
    private var kakaoMapKey: String {
        Bundle.main.object(forInfoDictionaryKey: "KAKAO_MAP_API_KEY") as? String ?? ""
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()

        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = preferences
        configuration.allowsInlineMediaPlayback = true

        // CORS 및 외부 리소스 로드 허용
        configuration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        configuration.setValue(true, forKey: "allowUniversalAccessFromFileURLs")

        // 메시지 핸들러 등록
        configuration.userContentController.add(context.coordinator, name: "markerTapped")
        configuration.userContentController.add(context.coordinator, name: "consoleLog")
        configuration.userContentController.add(context.coordinator, name: "mapReady")

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.isOpaque = false
        webView.backgroundColor = .clear

        // 디버깅 활성화
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }

        // GitHub Pages URL에서 로드
        let urlString = "https://chabro2633.github.io/petsancheck/hospital.html?key=\(kakaoMapKey)&lat=\(centerCoordinate.latitude)&lng=\(centerCoordinate.longitude)"
        if let url = URL(string: urlString) {
            webView.load(URLRequest(url: url))
        }

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard context.coordinator.isMapReady else { return }

        // 지도 중심 변경
        let script = "if(typeof setCenter === 'function') { setCenter(\(centerCoordinate.latitude), \(centerCoordinate.longitude)); }"
        webView.evaluateJavaScript(script)

        // 현재 위치 마커 업데이트
        if let location = currentLocation {
            let locationScript = "if(typeof setCurrentLocation === 'function') { setCurrentLocation(\(location.latitude), \(location.longitude)); }"
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
        var script = "if(typeof clearMarkers === 'function') { clearMarkers(); }\n"

        for hospital in hospitals {
            let title = hospital.name.replacingOccurrences(of: "'", with: "\\'")
            script += "if(typeof addMarker === 'function') { addMarker(\(hospital.latitude), \(hospital.longitude), '\(title)', '\(hospital.id)'); }\n"
        }

        webView.evaluateJavaScript(script)
        coordinator.lastHospitalCount = hospitals.count
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: KakaoMapView
        var isMapReady = false
        var lastHospitalCount = 0

        init(_ parent: KakaoMapView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("[HospitalMap] Page loaded successfully")

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                guard let self = self else { return }
                self.isMapReady = true

                // 초기 위치 설정
                let lat = self.parent.centerCoordinate.latitude
                let lng = self.parent.centerCoordinate.longitude

                var script = "if(typeof setCenter === 'function') { setCenter(\(lat), \(lng)); }"

                // 현재 위치 마커
                if let location = self.parent.currentLocation {
                    script += "if(typeof setCurrentLocation === 'function') { setCurrentLocation(\(location.latitude), \(location.longitude)); }"
                }

                webView.evaluateJavaScript(script)

                // 병원 마커 추가
                self.parent.updateMarkersWithCoordinator(webView, coordinator: self)
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("[HospitalMap] Navigation failed: \(error.localizedDescription)")
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("[HospitalMap] Provisional navigation failed: \(error.localizedDescription)")
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "consoleLog" {
                print("[HospitalMap JS] \(message.body)")
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
