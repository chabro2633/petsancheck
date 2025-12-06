//
//  WalkMapView.swift
//  petsanCheck
//
//  Created on 2025-11-30.
//

import SwiftUI
import WebKit
import CoreLocation

/// 산책 지도 WebView (카카오맵)
struct WalkMapView: UIViewRepresentable {
    @Binding var centerCoordinate: CLLocationCoordinate2D
    let routeCoordinates: [CLLocationCoordinate2D]

    // 카카오맵 JavaScript 키
    private let kakaoMapKey = APIKeys.kakaoMapKey

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
        configuration.userContentController.add(context.coordinator, name: "mapError")

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
        let urlString = "https://chabro2633.github.io/petsancheck/walk.html?key=\(kakaoMapKey)&lat=\(centerCoordinate.latitude)&lng=\(centerCoordinate.longitude)"
        if let url = URL(string: urlString) {
            webView.load(URLRequest(url: url))
        }

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // 지도가 로드되지 않았으면 무시
        guard context.coordinator.isMapReady else { return }

        // 현재 위치 마커 항상 업데이트
        let locationScript = "if(typeof setCurrentLocation === 'function') { setCurrentLocation(\(centerCoordinate.latitude), \(centerCoordinate.longitude)); }"
        webView.evaluateJavaScript(locationScript)

        // 경로 업데이트
        updateRoute(webView, context: context)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    private func updateRoute(_ webView: WKWebView, context: Context) {
        if routeCoordinates.isEmpty {
            webView.evaluateJavaScript("if(typeof clearRoute === 'function') { clearRoute(); }")
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
                    let script = "if(typeof setRoute === 'function') { setRoute('\(jsonString)'); }"
                    webView.evaluateJavaScript(script)
                }
            } else {
                // 새 포인트 추가
                let newCoordinates = Array(routeCoordinates.suffix(from: lastUpdateCount))
                for coord in newCoordinates {
                    let script = "if(typeof addRoutePoint === 'function') { addRoutePoint(\(coord.latitude), \(coord.longitude)); }"
                    webView.evaluateJavaScript(script)
                }
            }

            context.coordinator.lastRouteCount = routeCoordinates.count
        }
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: WalkMapView
        var isMapReady = false
        var lastRouteCount = 0

        init(_ parent: WalkMapView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("[WalkMap] Page loaded successfully")

            // 지도 로드 완료 후 초기화
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                guard let self = self else { return }
                self.isMapReady = true
                self.lastRouteCount = 0

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
                let script = "if(typeof setRoute === 'function') { setRoute('\(jsonString)'); }"
                webView.evaluateJavaScript(script)
                lastRouteCount = parent.routeCoordinates.count
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("[WalkMap] Navigation failed: \(error.localizedDescription)")
            isMapReady = false
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("[WalkMap] Provisional navigation failed: \(error.localizedDescription)")
            isMapReady = false
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "consoleLog" {
                print("[WalkMap JS] \(message.body)")
            } else if message.name == "mapReady" {
                print("[WalkMap] Map is ready")
                isMapReady = true
            } else if message.name == "mapError" {
                print("[WalkMap] Map error: \(message.body)")
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
