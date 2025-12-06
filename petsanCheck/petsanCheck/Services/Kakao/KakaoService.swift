//
//  KakaoService.swift
//  petsanCheck
//
//  Created on 2025-12-06.
//

import Foundation
import Combine
import KakaoSDKCommon
import KakaoSDKAuth
import KakaoSDKUser
import KakaoSDKTalk
import KakaoSDKFriend

/// 카카오 친구 정보
struct KakaoFriend: Identifiable {
    let id: String
    let profileNickname: String?
    let profileThumbnailImage: URL?
    let isFavorite: Bool
}

/// 카카오 SDK 연동을 담당하는 서비스
@MainActor
class KakaoService: ObservableObject {
    static let shared = KakaoService()

    @Published var isLoggedIn = false
    @Published var currentUser: KakaoUser?
    @Published var friends: [KakaoFriend] = []
    @Published var friendKakaoIds: [String] = []
    @Published var errorMessage: String?

    private var isInitialized = false

    private init() {}

    // MARK: - 초기화

    /// 카카오 SDK 초기화 (앱 시작 시 호출)
    func initialize() {
        guard !isInitialized else { return }

        KakaoSDK.initSDK(appKey: APIKeys.kakaoNativeAppKey)
        isInitialized = true
        print("[Kakao] SDK 초기화 완료")

        // 기존 토큰 확인
        checkLoginStatus()
    }

    /// 로그인 상태 확인
    private func checkLoginStatus() {
        if AuthApi.hasToken() {
            UserApi.shared.accessTokenInfo { [weak self] tokenInfo, error in
                if let error = error {
                    print("[Kakao] 토큰 검증 실패: \(error.localizedDescription)")
                    Task { @MainActor in
                        self?.isLoggedIn = false
                    }
                } else {
                    print("[Kakao] 토큰 유효함: \(tokenInfo?.id ?? 0)")
                    Task { @MainActor in
                        self?.isLoggedIn = true
                        self?.fetchUserInfo()
                    }
                }
            }
        }
    }

    // MARK: - 로그인/로그아웃

    /// 카카오 로그인
    func login() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            // 카카오톡 앱이 설치되어 있으면 앱으로 로그인
            if UserApi.isKakaoTalkLoginAvailable() {
                UserApi.shared.loginWithKakaoTalk { [weak self] oauthToken, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    Task { @MainActor in
                        self?.isLoggedIn = true
                        self?.fetchUserInfo()
                        self?.fetchFriends()
                        continuation.resume()
                    }
                }
            } else {
                // 카카오톡이 없으면 웹으로 로그인
                UserApi.shared.loginWithKakaoAccount { [weak self] oauthToken, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    Task { @MainActor in
                        self?.isLoggedIn = true
                        self?.fetchUserInfo()
                        self?.fetchFriends()
                        continuation.resume()
                    }
                }
            }
        }
    }

    /// 카카오 로그아웃
    func logout() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            UserApi.shared.logout { [weak self] error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                Task { @MainActor in
                    self?.isLoggedIn = false
                    self?.currentUser = nil
                    self?.friends = []
                    self?.friendKakaoIds = []
                    continuation.resume()
                }
            }
        }
    }

    // MARK: - 사용자 정보

    /// 현재 사용자 정보 조회
    private func fetchUserInfo() {
        UserApi.shared.me { [weak self] user, error in
            if let error = error {
                print("[Kakao] 사용자 정보 조회 실패: \(error.localizedDescription)")
                return
            }

            guard let user = user else { return }

            Task { @MainActor in
                self?.currentUser = KakaoUser(
                    id: user.id ?? 0,
                    nickname: user.kakaoAccount?.profile?.nickname,
                    profileImageUrl: user.kakaoAccount?.profile?.profileImageUrl
                )
                print("[Kakao] 사용자 정보: \(user.kakaoAccount?.profile?.nickname ?? "Unknown")")
            }
        }
    }

    // MARK: - 친구 목록

    /// 카카오톡 친구 목록 조회
    func fetchFriends() {
        // 친구 목록 조회 (피커 없이 직접 조회)
        TalkApi.shared.friends { [weak self] friends, error in
            if let error = error {
                print("[Kakao] 친구 목록 조회 실패: \(error.localizedDescription)")
                Task { @MainActor in
                    self?.errorMessage = "친구 목록을 불러올 수 없습니다."
                }
                return
            }

            guard let friendList = friends?.elements else {
                print("[Kakao] 친구 목록이 비어있음")
                return
            }

            Task { @MainActor in
                self?.friends = friendList.map { friend in
                    KakaoFriend(
                        id: String(friend.id ?? 0),
                        profileNickname: friend.profileNickname,
                        profileThumbnailImage: friend.profileThumbnailImage,
                        isFavorite: friend.favorite ?? false
                    )
                }
                self?.friendKakaoIds = friendList.compactMap { String($0.id ?? 0) }
                print("[Kakao] 친구 \(friendList.count)명 조회됨")
            }
        }
    }

    /// 친구 수
    var friendCount: Int {
        friends.count
    }
}

// MARK: - 카카오 사용자 모델
struct KakaoUser {
    let id: Int64
    let nickname: String?
    let profileImageUrl: URL?

    var kakaoId: String {
        String(id)
    }
}

// MARK: - URL Scheme 처리
extension KakaoService {
    /// 카카오 로그인 URL 스킴 처리
    func handleOpenUrl(_ url: URL) -> Bool {
        if AuthApi.isKakaoTalkLoginUrl(url) {
            return AuthController.handleOpenUrl(url: url)
        }
        return false
    }
}
