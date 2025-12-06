//
//  Ranking.swift
//  petsanCheck
//
//  Created on 2025-12-06.
//

import Foundation
import SwiftUI

// MARK: - 랭킹 유저 모델
struct RankingUser: Identifiable {
    let id: UUID
    let name: String
    let petName: String
    let petBreed: String
    let profileImageData: Data?
    let totalDistance: Double  // 총 산책 거리 (미터)
    let totalWalkCount: Int    // 총 산책 횟수
    let totalDuration: TimeInterval  // 총 산책 시간 (초)
    let badges: [Badge]
    let rank: Int
    let isCurrentUser: Bool

    init(
        id: UUID = UUID(),
        name: String,
        petName: String,
        petBreed: String,
        profileImageData: Data? = nil,
        totalDistance: Double,
        totalWalkCount: Int,
        totalDuration: TimeInterval,
        badges: [Badge] = [],
        rank: Int = 0,
        isCurrentUser: Bool = false
    ) {
        self.id = id
        self.name = name
        self.petName = petName
        self.petBreed = petBreed
        self.profileImageData = profileImageData
        self.totalDistance = totalDistance
        self.totalWalkCount = totalWalkCount
        self.totalDuration = totalDuration
        self.badges = badges
        self.rank = rank
        self.isCurrentUser = isCurrentUser
    }

    /// 거리 표시 텍스트
    var distanceText: String {
        if totalDistance < 1000 {
            return String(format: "%.0fm", totalDistance)
        } else {
            return String(format: "%.1fkm", totalDistance / 1000)
        }
    }

    /// 시간 표시 텍스트
    var durationText: String {
        let hours = Int(totalDuration) / 3600
        let minutes = (Int(totalDuration) % 3600) / 60
        if hours > 0 {
            return "\(hours)시간 \(minutes)분"
        } else {
            return "\(minutes)분"
        }
    }
}

// MARK: - 뱃지 모델
struct Badge: Identifiable {
    let id: UUID
    let type: BadgeType
    let earnedAt: Date
    let isNew: Bool

    init(id: UUID = UUID(), type: BadgeType, earnedAt: Date = Date(), isNew: Bool = false) {
        self.id = id
        self.type = type
        self.earnedAt = earnedAt
        self.isNew = isNew
    }
}

// MARK: - 뱃지 타입
enum BadgeType: String, CaseIterable {
    // 거리 뱃지
    case distance1km = "distance_1km"
    case distance5km = "distance_5km"
    case distance10km = "distance_10km"
    case distance50km = "distance_50km"
    case distance100km = "distance_100km"
    case distance500km = "distance_500km"

    // 횟수 뱃지
    case walks5 = "walks_5"
    case walks10 = "walks_10"
    case walks30 = "walks_30"
    case walks50 = "walks_50"
    case walks100 = "walks_100"
    case walks365 = "walks_365"

    // 연속 뱃지
    case streak3days = "streak_3days"
    case streak7days = "streak_7days"
    case streak30days = "streak_30days"

    // 특별 뱃지
    case earlyBird = "early_bird"        // 아침 6시 전 산책
    case nightOwl = "night_owl"          // 밤 10시 이후 산책
    case rainWalker = "rain_walker"      // 비 오는 날 산책
    case weekendWarrior = "weekend_warrior"  // 주말 산책 10회

    var name: String {
        switch self {
        case .distance1km: return "첫 걸음"
        case .distance5km: return "동네 탐험가"
        case .distance10km: return "산책 러버"
        case .distance50km: return "마라토너"
        case .distance100km: return "산책 마스터"
        case .distance500km: return "레전드 워커"

        case .walks5: return "산책 입문"
        case .walks10: return "산책 습관"
        case .walks30: return "산책 전문가"
        case .walks50: return "산책 달인"
        case .walks100: return "산책 챔피언"
        case .walks365: return "1년 산책왕"

        case .streak3days: return "3일 연속"
        case .streak7days: return "일주일 연속"
        case .streak30days: return "한 달 연속"

        case .earlyBird: return "얼리버드"
        case .nightOwl: return "올빼미"
        case .rainWalker: return "비도 막지 못해"
        case .weekendWarrior: return "주말 전사"
        }
    }

    var description: String {
        switch self {
        case .distance1km: return "누적 1km 산책 달성"
        case .distance5km: return "누적 5km 산책 달성"
        case .distance10km: return "누적 10km 산책 달성"
        case .distance50km: return "누적 50km 산책 달성"
        case .distance100km: return "누적 100km 산책 달성"
        case .distance500km: return "누적 500km 산책 달성"

        case .walks5: return "5회 산책 완료"
        case .walks10: return "10회 산책 완료"
        case .walks30: return "30회 산책 완료"
        case .walks50: return "50회 산책 완료"
        case .walks100: return "100회 산책 완료"
        case .walks365: return "365회 산책 완료"

        case .streak3days: return "3일 연속 산책"
        case .streak7days: return "7일 연속 산책"
        case .streak30days: return "30일 연속 산책"

        case .earlyBird: return "아침 6시 전 산책"
        case .nightOwl: return "밤 10시 이후 산책"
        case .rainWalker: return "비 오는 날 산책"
        case .weekendWarrior: return "주말 산책 10회"
        }
    }

    var icon: String {
        switch self {
        case .distance1km: return "figure.walk"
        case .distance5km: return "map"
        case .distance10km: return "heart.fill"
        case .distance50km: return "flame.fill"
        case .distance100km: return "star.fill"
        case .distance500km: return "crown.fill"

        case .walks5: return "pawprint"
        case .walks10: return "pawprint.fill"
        case .walks30: return "medal"
        case .walks50: return "medal.fill"
        case .walks100: return "trophy"
        case .walks365: return "trophy.fill"

        case .streak3days: return "calendar"
        case .streak7days: return "calendar.badge.clock"
        case .streak30days: return "calendar.badge.checkmark"

        case .earlyBird: return "sunrise.fill"
        case .nightOwl: return "moon.stars.fill"
        case .rainWalker: return "cloud.rain.fill"
        case .weekendWarrior: return "flag.fill"
        }
    }

    var color: Color {
        switch self {
        case .distance1km, .walks5: return Color(red: 0.8, green: 0.5, blue: 0.2)  // 브론즈
        case .distance5km, .distance10km, .walks10, .walks30, .streak3days:
            return Color(red: 0.75, green: 0.75, blue: 0.8)  // 실버
        case .distance50km, .walks50, .streak7days, .earlyBird, .nightOwl:
            return Color(red: 1.0, green: 0.84, blue: 0)  // 골드
        case .distance100km, .walks100, .streak30days, .rainWalker, .weekendWarrior:
            return Color(red: 0.9, green: 0.4, blue: 0.9)  // 플래티넘
        case .distance500km, .walks365:
            return Color(red: 0.4, green: 0.8, blue: 1.0)  // 다이아몬드
        }
    }

    /// 뱃지 획득 조건 충족 여부 확인
    func isEarned(totalDistance: Double, totalWalkCount: Int, streak: Int) -> Bool {
        switch self {
        case .distance1km: return totalDistance >= 1000
        case .distance5km: return totalDistance >= 5000
        case .distance10km: return totalDistance >= 10000
        case .distance50km: return totalDistance >= 50000
        case .distance100km: return totalDistance >= 100000
        case .distance500km: return totalDistance >= 500000

        case .walks5: return totalWalkCount >= 5
        case .walks10: return totalWalkCount >= 10
        case .walks30: return totalWalkCount >= 30
        case .walks50: return totalWalkCount >= 50
        case .walks100: return totalWalkCount >= 100
        case .walks365: return totalWalkCount >= 365

        case .streak3days: return streak >= 3
        case .streak7days: return streak >= 7
        case .streak30days: return streak >= 30

        default: return false
        }
    }
}

// MARK: - 랭킹 타입
enum RankingType: String, CaseIterable {
    case distance = "거리"
    case walkCount = "횟수"
    case duration = "시간"

    var icon: String {
        switch self {
        case .distance: return "map.fill"
        case .walkCount: return "pawprint.fill"
        case .duration: return "clock.fill"
        }
    }
}

// MARK: - 랭킹 기간
enum RankingPeriod: String, CaseIterable {
    case weekly = "주간"
    case monthly = "월간"
    case allTime = "전체"
}

// MARK: - Preview Data
extension RankingUser {
    /// 다른 유저들 (나를 제외한 샘플 데이터)
    static var otherUsers: [RankingUser] {
        [
            RankingUser(
                name: "김민수",
                petName: "초코",
                petBreed: "포메라니안",
                totalDistance: 125000,
                totalWalkCount: 89,
                totalDuration: 108000,
                badges: [
                    Badge(type: .distance100km),
                    Badge(type: .walks50),
                    Badge(type: .streak7days)
                ],
                rank: 1
            ),
            RankingUser(
                name: "이지은",
                petName: "뽀삐",
                petBreed: "비숑 프리제",
                totalDistance: 98500,
                totalWalkCount: 76,
                totalDuration: 86400,
                badges: [
                    Badge(type: .distance50km),
                    Badge(type: .walks50),
                    Badge(type: .earlyBird)
                ],
                rank: 2
            ),
            RankingUser(
                name: "박준영",
                petName: "루이",
                petBreed: "골든 리트리버",
                totalDistance: 87200,
                totalWalkCount: 62,
                totalDuration: 75600,
                badges: [
                    Badge(type: .distance50km),
                    Badge(type: .walks50)
                ],
                rank: 3
            ),
            RankingUser(
                name: "최서연",
                petName: "콩이",
                petBreed: "시바견",
                totalDistance: 76800,
                totalWalkCount: 55,
                totalDuration: 64800,
                badges: [
                    Badge(type: .distance50km),
                    Badge(type: .walks50)
                ],
                rank: 4
            ),
            RankingUser(
                name: "정현우",
                petName: "몽이",
                petBreed: "말티즈",
                totalDistance: 65400,
                totalWalkCount: 48,
                totalDuration: 57600,
                badges: [
                    Badge(type: .distance50km),
                    Badge(type: .walks30)
                ],
                rank: 5
            )
        ]
    }

    /// 전체 프리뷰 (나 포함)
    static var previews: [RankingUser] {
        var users = otherUsers
        users.append(RankingUser(
            name: "나",
            petName: "깜지",
            petBreed: "믹스견",
            totalDistance: 45600,
            totalWalkCount: 34,
            totalDuration: 41400,
            badges: [
                Badge(type: .distance10km),
                Badge(type: .walks30, isNew: true)
            ],
            rank: 8,
            isCurrentUser: true
        ))
        return users
    }
}
