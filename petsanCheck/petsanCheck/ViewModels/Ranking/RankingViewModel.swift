//
//  RankingViewModel.swift
//  petsanCheck
//
//  Created on 2025-12-06.
//

import Foundation
import SwiftUI
import Combine
import CoreLocation

/// 랭킹 범위 필터
enum RankingScope: String, CaseIterable {
    case global = "전체"
    case nearby = "내 주변"
    case friends = "친구"

    var icon: String {
        switch self {
        case .global: return "globe.asia.australia.fill"
        case .nearby: return "location.fill"
        case .friends: return "person.2.fill"
        }
    }
}

/// 랭킹 화면을 관리하는 ViewModel
@MainActor
class RankingViewModel: ObservableObject {
    @Published var rankings: [RankingUser] = []
    @Published var currentUser: RankingUser?
    @Published var myBadges: [Badge] = []
    @Published var allBadges: [BadgeType] = BadgeType.allCases
    @Published var isLoading = false
    @Published var selectedRankingType: RankingType = .distance
    @Published var selectedPeriod: RankingPeriod = .weekly
    @Published var selectedScope: RankingScope = .global
    @Published var nearbyRadius: Double = 5.0  // km
    @Published var newBadge: Badge?
    @Published var showBadgeAlert = false
    @Published var errorMessage: String?
    @Published var currentLocation: CLLocation?
    @Published var isKakaoLoggedIn = false
    @Published var showKakaoLoginPrompt = false

    private let coreDataService = CoreDataService.shared
    private let firebaseService = FirebaseService.shared
    private let kakaoService = KakaoService.shared
    private let locationManager = LocationManager()
    private var cancellables = Set<AnyCancellable>()

    init() {
        // 위치 업데이트 구독
        locationManager.$location
            .compactMap { $0 }
            .sink { [weak self] location in
                self?.currentLocation = location
            }
            .store(in: &cancellables)

        // 카카오 로그인 상태 구독
        kakaoService.$isLoggedIn
            .sink { [weak self] isLoggedIn in
                self?.isKakaoLoggedIn = isLoggedIn
            }
            .store(in: &cancellables)

        // 위치 업데이트 시작
        locationManager.startQuickLocationFetch()

        // 먼저 내 통계를 로드한 후 랭킹에 포함
        loadMyStats()
        loadRankings()
    }

    /// 랭킹 데이터 로드 (Firebase에서)
    func loadRankings() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                // 범위에 따라 다른 쿼리 사용
                let firebaseRankings: [RankingUser]

                switch selectedScope {
                case .global:
                    firebaseRankings = try await firebaseService.fetchRankings(
                        type: selectedRankingType,
                        limit: 50
                    )
                case .nearby:
                    guard let location = currentLocation else {
                        errorMessage = "위치를 찾을 수 없습니다."
                        loadLocalRankings()
                        return
                    }
                    firebaseRankings = try await firebaseService.fetchNearbyRankings(
                        type: selectedRankingType,
                        location: location,
                        radiusKm: nearbyRadius,
                        limit: 50
                    )
                case .friends:
                    // 카카오 로그인 확인
                    guard kakaoService.isLoggedIn else {
                        showKakaoLoginPrompt = true
                        isLoading = false
                        return
                    }
                    // 친구 목록으로 랭킹 조회
                    let friendIds = kakaoService.friendKakaoIds
                    if friendIds.isEmpty {
                        errorMessage = "연동된 친구가 없습니다."
                        loadLocalRankings()
                        return
                    }
                    firebaseRankings = try await firebaseService.fetchFriendsRankings(
                        type: selectedRankingType,
                        kakaoFriendIds: friendIds,
                        limit: 50
                    )
                }

                // 뱃지 계산 추가
                var rankingsWithBadges = firebaseRankings.map { user in
                    var updatedUser = user
                    if user.isCurrentUser {
                        // 현재 유저는 로컬 뱃지 사용
                        return RankingUser(
                            id: user.id,
                            name: user.name,
                            petName: user.petName,
                            petBreed: user.petBreed,
                            profileImageData: user.profileImageData,
                            totalDistance: user.totalDistance,
                            totalWalkCount: user.totalWalkCount,
                            totalDuration: user.totalDuration,
                            badges: myBadges,
                            rank: user.rank,
                            isCurrentUser: true
                        )
                    }
                    return user
                }

                // 랭킹에 내 데이터가 없으면 추가
                if !rankingsWithBadges.contains(where: { $0.isCurrentUser }), let myUser = currentUser {
                    rankingsWithBadges.append(myUser)
                    // 다시 정렬
                    switch selectedRankingType {
                    case .distance:
                        rankingsWithBadges.sort { $0.totalDistance > $1.totalDistance }
                    case .walkCount:
                        rankingsWithBadges.sort { $0.totalWalkCount > $1.totalWalkCount }
                    case .duration:
                        rankingsWithBadges.sort { $0.totalDuration > $1.totalDuration }
                    }
                    // 순위 재할당
                    rankingsWithBadges = rankingsWithBadges.enumerated().map { index, user in
                        RankingUser(
                            id: user.id,
                            name: user.name,
                            petName: user.petName,
                            petBreed: user.petBreed,
                            profileImageData: user.profileImageData,
                            totalDistance: user.totalDistance,
                            totalWalkCount: user.totalWalkCount,
                            totalDuration: user.totalDuration,
                            badges: user.badges,
                            rank: index + 1,
                            isCurrentUser: user.isCurrentUser
                        )
                    }
                }

                self.rankings = rankingsWithBadges

                // 현재 유저 순위 업데이트
                if let myRanking = rankings.first(where: { $0.isCurrentUser }) {
                    currentUser = myRanking
                }

                isLoading = false
            } catch {
                print("[Ranking] Firebase 로드 실패: \(error.localizedDescription)")
                errorMessage = "랭킹을 불러올 수 없습니다."
                // 로컬 데이터로 폴백
                loadLocalRankings()
            }
        }
    }

    /// 로컬 랭킹 로드 (Firebase 실패 시 폴백)
    private func loadLocalRankings() {
        var users = RankingUser.otherUsers

        if let myUser = currentUser {
            users.append(myUser)
        }

        switch selectedRankingType {
        case .distance:
            users.sort { $0.totalDistance > $1.totalDistance }
        case .walkCount:
            users.sort { $0.totalWalkCount > $1.totalWalkCount }
        case .duration:
            users.sort { $0.totalDuration > $1.totalDuration }
        }

        rankings = users.enumerated().map { index, user in
            RankingUser(
                id: user.id,
                name: user.name,
                petName: user.petName,
                petBreed: user.petBreed,
                profileImageData: user.profileImageData,
                totalDistance: user.totalDistance,
                totalWalkCount: user.totalWalkCount,
                totalDuration: user.totalDuration,
                badges: user.badges,
                rank: index + 1,
                isCurrentUser: user.isCurrentUser
            )
        }

        if let myRanking = rankings.first(where: { $0.isCurrentUser }) {
            currentUser = myRanking
        }

        isLoading = false
    }

    /// 내 통계 로드 및 Firebase 동기화
    func loadMyStats() {
        let walkRecords = coreDataService.fetchAllWalkRecords()

        let totalDistance = walkRecords.reduce(into: 0.0) { $0 += $1.totalDistance }
        let totalWalkCount = walkRecords.count
        let totalDuration = walkRecords.reduce(into: 0.0) { $0 += $1.duration }

        // 연속 산책일 계산
        let streak = calculateStreak(from: walkRecords)

        // 획득한 뱃지 계산
        myBadges = calculateEarnedBadges(
            totalDistance: totalDistance,
            totalWalkCount: totalWalkCount,
            streak: streak
        )

        // 현재 유저 정보 업데이트
        if let dogs = coreDataService.fetchAllDogs().first {
            currentUser = RankingUser(
                name: "나",
                petName: dogs.name,
                petBreed: dogs.breed,
                profileImageData: dogs.profileImageData,
                totalDistance: totalDistance,
                totalWalkCount: totalWalkCount,
                totalDuration: totalDuration,
                badges: myBadges,
                rank: 0,
                isCurrentUser: true
            )

            // Firebase에 통계 동기화
            syncToFirebase(
                userName: "나",
                petName: dogs.name,
                petBreed: dogs.breed,
                totalDistance: totalDistance,
                totalWalkCount: totalWalkCount,
                totalDuration: totalDuration,
                profileImageData: dogs.profileImageData
            )
        }
    }

    /// Firebase에 내 통계 동기화
    private func syncToFirebase(
        userName: String,
        petName: String,
        petBreed: String,
        totalDistance: Double,
        totalWalkCount: Int,
        totalDuration: TimeInterval,
        profileImageData: Data?
    ) {
        Task {
            do {
                try await firebaseService.saveUserStats(
                    userName: userName,
                    petName: petName,
                    petBreed: petBreed,
                    totalDistance: totalDistance,
                    totalWalkCount: totalWalkCount,
                    totalDuration: totalDuration,
                    profileImageData: profileImageData
                )
                print("[Ranking] Firebase 동기화 완료")
            } catch {
                print("[Ranking] Firebase 동기화 실패: \(error.localizedDescription)")
            }
        }
    }

    /// 연속 산책일 계산
    private func calculateStreak(from records: [WalkSession]) -> Int {
        guard !records.isEmpty else { return 0 }

        let sortedRecords = records.sorted { $0.startTime > $1.startTime }
        let calendar = Calendar.current

        var streak = 1
        var currentDate = calendar.startOfDay(for: Date())

        // 오늘 산책했는지 확인
        let todayWalks = sortedRecords.filter { calendar.isDate($0.startTime, inSameDayAs: currentDate) }
        if todayWalks.isEmpty {
            // 오늘 안 했으면 어제부터 확인
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            let yesterdayWalks = sortedRecords.filter { calendar.isDate($0.startTime, inSameDayAs: currentDate) }
            if yesterdayWalks.isEmpty {
                return 0
            }
        }

        // 연속일 계산
        while true {
            let previousDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            let previousWalks = sortedRecords.filter { calendar.isDate($0.startTime, inSameDayAs: previousDate) }

            if previousWalks.isEmpty {
                break
            }

            streak += 1
            currentDate = previousDate
        }

        return streak
    }

    /// 획득한 뱃지 계산
    private func calculateEarnedBadges(totalDistance: Double, totalWalkCount: Int, streak: Int) -> [Badge] {
        var earnedBadges: [Badge] = []

        for badgeType in BadgeType.allCases {
            if badgeType.isEarned(totalDistance: totalDistance, totalWalkCount: totalWalkCount, streak: streak) {
                earnedBadges.append(Badge(type: badgeType))
            }
        }

        return earnedBadges
    }

    /// 랭킹 타입 변경
    func changeRankingType(_ type: RankingType) {
        selectedRankingType = type
        loadRankings()
    }

    /// 기간 변경
    func changePeriod(_ period: RankingPeriod) {
        selectedPeriod = period
        loadRankings()
    }

    /// 새로고침
    func refresh() async {
        loadRankings()
        loadMyStats()
    }

    /// 카카오 로그인
    func loginWithKakao() async {
        do {
            try await kakaoService.login()
            showKakaoLoginPrompt = false
            // 로그인 후 친구 랭킹 로드
            if selectedScope == .friends {
                loadRankings()
            }
        } catch {
            errorMessage = "카카오 로그인에 실패했습니다."
            print("[Ranking] 카카오 로그인 실패: \(error.localizedDescription)")
        }
    }

    /// 카카오 로그아웃
    func logoutFromKakao() async {
        do {
            try await kakaoService.logout()
        } catch {
            print("[Ranking] 카카오 로그아웃 실패: \(error.localizedDescription)")
        }
    }

    /// 뱃지 획득 여부 확인
    func isBadgeEarned(_ badgeType: BadgeType) -> Bool {
        myBadges.contains { $0.type == badgeType }
    }

    /// 다음 목표까지 진행률
    func progressToNextBadge(for type: RankingType) -> (current: Double, target: Double, badgeType: BadgeType?) {
        guard let user = currentUser else { return (0, 1, nil) }

        switch type {
        case .distance:
            let distance = user.totalDistance
            if distance < 1000 { return (distance, 1000, .distance1km) }
            if distance < 5000 { return (distance, 5000, .distance5km) }
            if distance < 10000 { return (distance, 10000, .distance10km) }
            if distance < 50000 { return (distance, 50000, .distance50km) }
            if distance < 100000 { return (distance, 100000, .distance100km) }
            if distance < 500000 { return (distance, 500000, .distance500km) }
            return (distance, distance, nil)

        case .walkCount:
            let count = Double(user.totalWalkCount)
            if count < 5 { return (count, 5, .walks5) }
            if count < 10 { return (count, 10, .walks10) }
            if count < 30 { return (count, 30, .walks30) }
            if count < 50 { return (count, 50, .walks50) }
            if count < 100 { return (count, 100, .walks100) }
            if count < 365 { return (count, 365, .walks365) }
            return (count, count, nil)

        case .duration:
            return (user.totalDuration, user.totalDuration, nil)
        }
    }
}
