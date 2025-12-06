//
//  WalkMapView.swift
//  petsanCheck
//
//  Created on 2025-11-30.
//

import SwiftUI
import WebKit
import CoreLocation

/// 산책 지도 WebView (원격 호스팅 방식)
struct WalkMapView: UIViewRepresentable {
    @Binding var centerCoordinate: CLLocationCoordinate2D
    let routeCoordinates: [CLLocationCoordinate2D]

    // GitHub Pages 호스팅 URL
    private let mapURL = "https://chabro2633.github.io/petsancheck/walk-map.html"

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

        // GitHub Pages에서 HTML 로드
        if let url = URL(string: mapURL) {
            webView.load(URLRequest(url: url))
        }

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // 지도가 로드되지 않았으면 무시
        guard context.coordinator.isMapReady else { return }

        // 지도 중심 변경 (부드러운 이동)
        let script = "setCenter(\(centerCoordinate.latitude), \(centerCoordinate.longitude));"
        webView.evaluateJavaScript(script)

        // 경로 업데이트
        updateRoute(webView, context: context)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    private func updateRoute(_ webView: WKWebView, context: Context) {
        guard !routeCoordinates.isEmpty else {
            webView.evaluateJavaScript("clearRoute();")
            return
        }

        // 이전 경로와 비교하여 새로운 포인트만 추가 (성능 최적화)
        let lastUpdateCount = context.coordinator.lastRouteCount

        if routeCoordinates.count > lastUpdateCount {
            // 새로운 포인트만 추가
            let newCoordinates = Array(routeCoordinates.suffix(from: lastUpdateCount))

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
                for coord in newCoordinates {
                    let script = "addRoutePoint(\(coord.latitude), \(coord.longitude));"
                    webView.evaluateJavaScript(script)
                }
            }

            context.coordinator.lastRouteCount = routeCoordinates.count
        }

        // 현재 위치 마커 표시
        if let last = routeCoordinates.last {
            let script = "setCurrentLocation(\(last.latitude), \(last.longitude));"
            webView.evaluateJavaScript(script)
        }
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: WalkMapView
        var isMapReady = false
        var lastRouteCount = 0
        private var webViewRef: WKWebView?

        init(_ parent: WalkMapView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("Walk map loaded successfully from remote URL")
            webViewRef = webView

            // 지도 로드 완료 후 초기화
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.isMapReady = true
                self?.lastRouteCount = 0

                // 초기 위치 설정
                let script = "setCenter(\(self?.parent.centerCoordinate.latitude ?? 37.5665), \(self?.parent.centerCoordinate.longitude ?? 126.9780));"
                webView.evaluateJavaScript(script)

                // 경로가 있으면 그리기
                if let coords = self?.parent.routeCoordinates, !coords.isEmpty {
                    self?.initialRouteSetup(webView)
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

            // 현재 위치 마커 표시
            if let last = parent.routeCoordinates.last {
                let script = "setCurrentLocation(\(last.latitude), \(last.longitude));"
                webView.evaluateJavaScript(script)
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
