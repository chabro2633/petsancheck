//
//  Story.swift
//  petsanCheck
//
//  Created on 2025-12-06.
//

import Foundation

/// 스토리 모델
struct Story: Identifiable, Codable {
    let id: UUID
    let petId: UUID?
    let petName: String
    let petBreed: String?
    let petProfileImage: Data?
    let items: [StoryItem]
    let createdAt: Date
    let expiresAt: Date  // 24시간 후 만료

    init(
        id: UUID = UUID(),
        petId: UUID? = nil,
        petName: String,
        petBreed: String? = nil,
        petProfileImage: Data? = nil,
        items: [StoryItem] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.petId = petId
        self.petName = petName
        self.petBreed = petBreed
        self.petProfileImage = petProfileImage
        self.items = items
        self.createdAt = createdAt
        self.expiresAt = createdAt.addingTimeInterval(24 * 60 * 60)  // 24시간
    }

    /// 스토리가 만료되었는지
    var isExpired: Bool {
        Date() > expiresAt
    }

    /// 스토리가 아직 유효한지
    var isActive: Bool {
        !isExpired && !items.isEmpty
    }
}

/// 산책 경로 좌표
struct WalkRouteCoordinate: Codable {
    let latitude: Double
    let longitude: Double
}

/// 스토리 아이템 (개별 사진/영상)
struct StoryItem: Identifiable, Codable {
    let id: UUID
    let type: MediaType
    let mediaData: Data?
    let mediaURL: String?
    let caption: String?
    let location: String?
    let walkRoute: [WalkRouteCoordinate]?  // 산책 경로
    let walkDistance: Double?  // 산책 거리 (미터)
    let walkDuration: TimeInterval?  // 산책 시간 (초)
    let createdAt: Date
    var viewedBy: [UUID]  // 본 사용자 ID 목록

    enum MediaType: String, Codable {
        case photo
        case video
        case walkRoute  // 산책 경로 타입 추가
    }

    init(
        id: UUID = UUID(),
        type: MediaType,
        mediaData: Data? = nil,
        mediaURL: String? = nil,
        caption: String? = nil,
        location: String? = nil,
        walkRoute: [WalkRouteCoordinate]? = nil,
        walkDistance: Double? = nil,
        walkDuration: TimeInterval? = nil,
        createdAt: Date = Date(),
        viewedBy: [UUID] = []
    ) {
        self.id = id
        self.type = type
        self.mediaData = mediaData
        self.mediaURL = mediaURL
        self.caption = caption
        self.location = location
        self.walkRoute = walkRoute
        self.walkDistance = walkDistance
        self.walkDuration = walkDuration
        self.createdAt = createdAt
        self.viewedBy = viewedBy
    }

    /// 산책 거리 텍스트
    var walkDistanceText: String? {
        guard let distance = walkDistance else { return nil }
        if distance < 1000 {
            return String(format: "%.0fm", distance)
        } else {
            return String(format: "%.1fkm", distance / 1000)
        }
    }

    /// 산책 시간 텍스트
    var walkDurationText: String? {
        guard let duration = walkDuration else { return nil }
        let minutes = Int(duration) / 60
        if minutes < 60 {
            return "\(minutes)분"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)시간 \(remainingMinutes)분"
        }
    }

    /// 상대적 시간 표시
    var relativeTimeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
}

// MARK: - Preview Data
extension Story {
    /// 샘플 산책 경로 (한강공원 주변)
    static var sampleWalkRoute: [WalkRouteCoordinate] {
        [
            WalkRouteCoordinate(latitude: 37.5283, longitude: 126.9340),
            WalkRouteCoordinate(latitude: 37.5285, longitude: 126.9345),
            WalkRouteCoordinate(latitude: 37.5290, longitude: 126.9350),
            WalkRouteCoordinate(latitude: 37.5295, longitude: 126.9355),
            WalkRouteCoordinate(latitude: 37.5300, longitude: 126.9360),
            WalkRouteCoordinate(latitude: 37.5305, longitude: 126.9365),
            WalkRouteCoordinate(latitude: 37.5310, longitude: 126.9370),
            WalkRouteCoordinate(latitude: 37.5315, longitude: 126.9368),
            WalkRouteCoordinate(latitude: 37.5320, longitude: 126.9365),
            WalkRouteCoordinate(latitude: 37.5325, longitude: 126.9360)
        ]
    }

    static var previews: [Story] {
        [
            Story(
                petName: "초코",
                petBreed: "포메라니안",
                items: [
                    StoryItem(
                        type: .walkRoute,
                        caption: "오늘 한강 산책!",
                        location: "서울 한강공원",
                        walkRoute: sampleWalkRoute,
                        walkDistance: 2500,
                        walkDuration: 2400
                    ),
                    StoryItem(type: .photo, caption: "간식 타임")
                ],
                createdAt: Date().addingTimeInterval(-3600)
            ),
            Story(
                petName: "뽀삐",
                petBreed: "비숑",
                items: [
                    StoryItem(
                        type: .walkRoute,
                        caption: "비오기 전 산책",
                        location: "경기도 분당",
                        walkRoute: sampleWalkRoute,
                        walkDistance: 1800,
                        walkDuration: 1800
                    )
                ],
                createdAt: Date().addingTimeInterval(-7200)
            ),
            Story(
                petName: "루이",
                petBreed: "골든 리트리버",
                items: [
                    StoryItem(
                        type: .walkRoute,
                        caption: "해변 산책!",
                        location: "부산 해운대",
                        walkRoute: sampleWalkRoute,
                        walkDistance: 3800,
                        walkDuration: 3600
                    ),
                    StoryItem(type: .photo, caption: "수영 후")
                ],
                createdAt: Date().addingTimeInterval(-10800)
            ),
            Story(
                petName: "콩이",
                petBreed: "시바견",
                items: [
                    StoryItem(
                        type: .walkRoute,
                        caption: "등산 산책",
                        location: "서울 북한산",
                        walkRoute: sampleWalkRoute,
                        walkDistance: 4200,
                        walkDuration: 4800
                    )
                ],
                createdAt: Date().addingTimeInterval(-14400)
            ),
            Story(
                petName: "몽이",
                petBreed: "말티즈",
                items: [
                    StoryItem(
                        type: .walkRoute,
                        caption: "아침 산책",
                        location: "인천 송도",
                        walkRoute: sampleWalkRoute,
                        walkDistance: 1500,
                        walkDuration: 1200
                    )
                ],
                createdAt: Date().addingTimeInterval(-18000)
            )
        ]
    }
}
