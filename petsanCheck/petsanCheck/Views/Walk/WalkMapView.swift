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

    // GitHub Pages URL
    private let mapURL = "https://chabro2633.github.io/petsancheck/walk-map.html"

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

        // 원격 URL 로드 (초기 좌표 포함)
        if let url = URL(string: "\(mapURL)?lat=\(centerCoordinate.latitude)&lng=\(centerCoordinate.longitude)") {
            webView.load(URLRequest(url: url))
        }

        return webView
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
