//
//  petsanCheckApp.swift
//  petsanCheck
//
//  Created by 차형태 on 11/29/25.
//

import SwiftUI
import KakaoSDKAuth

@main
struct petsanCheckApp: App {

    init() {
        // Firebase 초기화
        FirebaseService.shared.configure()

        // Kakao SDK 초기화
        KakaoService.shared.initialize()
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .onOpenURL { url in
                    // 카카오 로그인 URL 스킴 처리
                    if AuthApi.isKakaoTalkLoginUrl(url) {
                        _ = AuthController.handleOpenUrl(url: url)
                    }
                }
        }
    }
}
