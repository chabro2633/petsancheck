//
//  FeedPost.swift
//  petsanCheck
//
//  Created on 2025-12-06.
//

import Foundation
import SwiftUI

/// 미디어 아이템 (사진 또는 영상)
struct MediaItem: Identifiable, Codable {
    let id: UUID
    let type: MediaType
    let data: Data?  // 로컬 저장용
    let url: String?  // 서버 URL
    let thumbnailData: Data?  // 영상 썸네일

    enum MediaType: String, Codable {
        case photo
        case video
    }

    init(id: UUID = UUID(), type: MediaType, data: Data? = nil, url: String? = nil, thumbnailData: Data? = nil) {
        self.id = id
        self.type = type
        self.data = data
        self.url = url
        self.thumbnailData = thumbnailData
    }
}

/// 피드 게시글 모델
struct FeedPost: Identifiable, Codable {
    let id: UUID
    let authorId: UUID
    let authorName: String
    let authorProfileImage: String?  // URL 또는 시스템 이미지명
    let petId: UUID?  // 연결된 반려견 ID
    let petName: String
    let petBreed: String?
    let mediaItems: [MediaItem]  // 사진/영상 지원
    let content: String
    let location: String?
    let walkDistance: Double?  // 산책 거리 (미터)
    let walkDuration: TimeInterval?  // 산책 시간 (초)
    let likeCount: Int
    let commentCount: Int
    let isLiked: Bool
    let isBookmarked: Bool
    let createdAt: Date

    init(
        id: UUID = UUID(),
        authorId: UUID = UUID(),
        authorName: String,
        authorProfileImage: String? = nil,
        petId: UUID? = nil,
        petName: String,
        petBreed: String? = nil,
        mediaItems: [MediaItem] = [],
        content: String,
        location: String? = nil,
        walkDistance: Double? = nil,
        walkDuration: TimeInterval? = nil,
        likeCount: Int = 0,
        commentCount: Int = 0,
        isLiked: Bool = false,
        isBookmarked: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.authorId = authorId
        self.authorName = authorName
        self.authorProfileImage = authorProfileImage
        self.petId = petId
        self.petName = petName
        self.petBreed = petBreed
        self.mediaItems = mediaItems
        self.content = content
        self.location = location
        self.walkDistance = walkDistance
        self.walkDuration = walkDuration
        self.likeCount = likeCount
        self.commentCount = commentCount
        self.isLiked = isLiked
        self.isBookmarked = isBookmarked
        self.createdAt = createdAt
    }

    /// 미디어가 있는지
    var hasMedia: Bool {
        !mediaItems.isEmpty
    }

    /// 영상이 포함되어 있는지
    var hasVideo: Bool {
        mediaItems.contains { $0.type == .video }
    }

    /// 상대적 시간 표시 (예: "3시간 전")
    var relativeTimeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }

    /// 산책 거리 표시
    var walkDistanceText: String? {
        guard let distance = walkDistance else { return nil }
        if distance < 1000 {
            return String(format: "%.0fm", distance)
        } else {
            return String(format: "%.1fkm", distance / 1000)
        }
    }

    /// 산책 시간 표시
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
}

/// 댓글 모델
struct FeedComment: Identifiable, Codable {
    let id: UUID
    let postId: UUID
    let authorId: UUID
    let authorName: String
    let authorProfileImage: String?
    let content: String
    let likeCount: Int
    let isLiked: Bool
    let createdAt: Date

    init(
        id: UUID = UUID(),
        postId: UUID,
        authorId: UUID = UUID(),
        authorName: String,
        authorProfileImage: String? = nil,
        content: String,
        likeCount: Int = 0,
        isLiked: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.postId = postId
        self.authorId = authorId
        self.authorName = authorName
        self.authorProfileImage = authorProfileImage
        self.content = content
        self.likeCount = likeCount
        self.isLiked = isLiked
        self.createdAt = createdAt
    }
}

// MARK: - Preview Data
extension FeedPost {
    static var previews: [FeedPost] {
        [
            FeedPost(
                authorName: "김민수",
                authorProfileImage: "person.circle.fill",
                petName: "초코",
                petBreed: "포메라니안",
                mediaItems: [],
                content: "오늘 한강 공원에서 산책했어요! 초코가 너무 신나했어요",
                location: "서울 한강공원",
                walkDistance: 2500,
                walkDuration: 2400,
                likeCount: 24,
                commentCount: 5,
                createdAt: Date().addingTimeInterval(-3600)
            ),
            FeedPost(
                authorName: "이지은",
                authorProfileImage: "person.circle.fill",
                petName: "뽀삐",
                petBreed: "비숑 프리제",
                mediaItems: [],
                content: "비 오기 전에 빠르게 산책 다녀왔어요~ 뽀삐가 우비 입은 모습 너무 귀엽지 않나요?",
                location: "경기도 분당",
                walkDistance: 1200,
                walkDuration: 1800,
                likeCount: 56,
                commentCount: 12,
                isLiked: true,
                createdAt: Date().addingTimeInterval(-7200)
            ),
            FeedPost(
                authorName: "박준영",
                authorProfileImage: "person.circle.fill",
                petName: "루이",
                petBreed: "골든 리트리버",
                mediaItems: [],
                content: "루이 첫 바다 나들이! 파도가 무서운지 계속 제 뒤에 숨더라고요 ㅋㅋㅋ",
                location: "부산 해운대",
                walkDistance: 3800,
                walkDuration: 5400,
                likeCount: 128,
                commentCount: 23,
                createdAt: Date().addingTimeInterval(-86400)
            ),
            FeedPost(
                authorName: "최서연",
                authorProfileImage: "person.circle.fill",
                petName: "콩이",
                petBreed: "시바견",
                mediaItems: [],
                content: "동네 산책로에 단풍이 너무 예뻐요~ 콩이도 가을 분위기에 푹 빠졌어요",
                location: "서울 북한산",
                walkDistance: 4200,
                walkDuration: 4800,
                likeCount: 89,
                commentCount: 15,
                createdAt: Date().addingTimeInterval(-172800)
            ),
            FeedPost(
                authorName: "정현우",
                authorProfileImage: "person.circle.fill",
                petName: "몽이",
                petBreed: "말티즈",
                mediaItems: [],
                content: "아침 산책은 역시 공기가 달라요~ 몽이도 상쾌해하는 것 같아요",
                location: "인천 송도",
                walkDistance: 1800,
                walkDuration: 2100,
                likeCount: 45,
                commentCount: 8,
                createdAt: Date().addingTimeInterval(-259200)
            )
        ]
    }
}
