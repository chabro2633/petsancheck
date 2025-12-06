//
//  FeedViewModel.swift
//  petsanCheck
//
//  Created on 2025-12-06.
//

import Foundation
import SwiftUI
import Combine
import PhotosUI

/// 피드 화면을 관리하는 ViewModel
@MainActor
class FeedViewModel: ObservableObject {
    @Published var posts: [FeedPost] = []
    @Published var stories: [Story] = []
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var error: String?
    @Published var selectedPost: FeedPost?
    @Published var showCreatePost = false
    @Published var showCreateStory = false
    @Published var selectedStory: Story?
    @Published var showStoryViewer = false

    // 프로필에서 반려견 정보 가져오기
    @Published var registeredDogs: [Dog] = []

    private let coreDataService = CoreDataService.shared

    init() {
        loadPosts()
        loadStories()
        loadRegisteredDogs()
    }

    /// 스토리 목록 로드
    func loadStories() {
        // 실제 앱에서는 서버에서 데이터를 가져옴
        stories = Story.previews
    }

    /// 등록된 반려견 목록 로드
    func loadRegisteredDogs() {
        registeredDogs = coreDataService.fetchAllDogs()
    }

    /// 피드 게시글 로드
    func loadPosts() {
        isLoading = true
        error = nil

        // 실제 앱에서는 서버에서 데이터를 가져옴
        // 현재는 샘플 데이터 사용
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.posts = FeedPost.previews
            self?.isLoading = false
        }
    }

    /// 피드 새로고침
    func refreshPosts() async {
        isRefreshing = true
        error = nil

        // 반려견 정보 다시 로드
        loadRegisteredDogs()

        // 서버에서 최신 데이터 가져오기 시뮬레이션
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        posts = FeedPost.previews.shuffled()
        isRefreshing = false
    }

    /// 게시글 좋아요 토글
    func toggleLike(for post: FeedPost) {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }

        let currentPost = posts[index]
        let newLikeCount = currentPost.isLiked ? currentPost.likeCount - 1 : currentPost.likeCount + 1

        posts[index] = FeedPost(
            id: currentPost.id,
            authorId: currentPost.authorId,
            authorName: currentPost.authorName,
            authorProfileImage: currentPost.authorProfileImage,
            petId: currentPost.petId,
            petName: currentPost.petName,
            petBreed: currentPost.petBreed,
            mediaItems: currentPost.mediaItems,
            content: currentPost.content,
            location: currentPost.location,
            walkDistance: currentPost.walkDistance,
            walkDuration: currentPost.walkDuration,
            likeCount: newLikeCount,
            commentCount: currentPost.commentCount,
            isLiked: !currentPost.isLiked,
            isBookmarked: currentPost.isBookmarked,
            createdAt: currentPost.createdAt
        )
    }

    /// 게시글 북마크 토글
    func toggleBookmark(for post: FeedPost) {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }

        let currentPost = posts[index]

        posts[index] = FeedPost(
            id: currentPost.id,
            authorId: currentPost.authorId,
            authorName: currentPost.authorName,
            authorProfileImage: currentPost.authorProfileImage,
            petId: currentPost.petId,
            petName: currentPost.petName,
            petBreed: currentPost.petBreed,
            mediaItems: currentPost.mediaItems,
            content: currentPost.content,
            location: currentPost.location,
            walkDistance: currentPost.walkDistance,
            walkDuration: currentPost.walkDuration,
            likeCount: currentPost.likeCount,
            commentCount: currentPost.commentCount,
            isLiked: currentPost.isLiked,
            isBookmarked: !currentPost.isBookmarked,
            createdAt: currentPost.createdAt
        )
    }

    /// 새 게시글 작성
    func createPost(
        content: String,
        selectedDog: Dog?,
        petName: String,
        petBreed: String?,
        mediaItems: [MediaItem],
        location: String?,
        walkDistance: Double?,
        walkDuration: TimeInterval?
    ) {
        let newPost = FeedPost(
            authorName: "나",  // 실제 앱에서는 로그인된 사용자 정보 사용
            authorProfileImage: "person.circle.fill",
            petId: selectedDog?.id,
            petName: petName,
            petBreed: petBreed,
            mediaItems: mediaItems,
            content: content,
            location: location,
            walkDistance: walkDistance,
            walkDuration: walkDuration,
            likeCount: 0,
            commentCount: 0,
            isLiked: false,
            isBookmarked: false,
            createdAt: Date()
        )

        posts.insert(newPost, at: 0)
    }

    /// 새 반려견 등록 (피드에서 직접 등록 시)
    func registerNewDog(name: String, breed: String) -> Dog {
        let newDog = Dog(
            name: name,
            breed: breed,
            birthDate: Date(),  // 기본값
            weight: 0,  // 나중에 수정 가능
            gender: .male  // 기본값
        )
        coreDataService.createDog(newDog)
        loadRegisteredDogs()
        return newDog
    }

    /// 새 스토리 생성
    func createStory(
        selectedDog: Dog?,
        petName: String,
        petBreed: String?,
        mediaData: Data,
        mediaType: StoryItem.MediaType,
        caption: String?,
        location: String?
    ) {
        let storyItem = StoryItem(
            type: mediaType,
            mediaData: mediaData,
            caption: caption,
            location: location
        )

        let newStory = Story(
            petId: selectedDog?.id,
            petName: petName,
            petBreed: petBreed,
            petProfileImage: selectedDog?.profileImageData,
            items: [storyItem]
        )

        stories.insert(newStory, at: 0)
    }

    /// 스토리에 아이템 추가
    func addItemToStory(storyId: UUID, mediaData: Data, mediaType: StoryItem.MediaType, caption: String?) {
        guard let index = stories.firstIndex(where: { $0.id == storyId }) else { return }

        let newItem = StoryItem(
            type: mediaType,
            mediaData: mediaData,
            caption: caption
        )

        var updatedItems = stories[index].items
        updatedItems.append(newItem)

        let updatedStory = Story(
            id: stories[index].id,
            petId: stories[index].petId,
            petName: stories[index].petName,
            petBreed: stories[index].petBreed,
            petProfileImage: stories[index].petProfileImage,
            items: updatedItems,
            createdAt: stories[index].createdAt
        )

        stories[index] = updatedStory
    }

    // MARK: - 댓글 관련

    /// 댓글 저장소 (postId: comments)
    @Published var commentsMap: [UUID: [FeedComment]] = [:]

    /// 특정 게시글의 댓글 로드
    func loadComments(for postId: UUID) {
        // 샘플 댓글 데이터 생성
        if commentsMap[postId] == nil {
            commentsMap[postId] = generateSampleComments(for: postId)
        }
    }

    /// 댓글 추가
    func addComment(to postId: UUID, content: String) {
        let newComment = FeedComment(
            postId: postId,
            authorName: "나",
            authorProfileImage: "person.circle.fill",
            content: content
        )

        if commentsMap[postId] != nil {
            commentsMap[postId]?.insert(newComment, at: 0)
        } else {
            commentsMap[postId] = [newComment]
        }

        // 댓글 수 업데이트
        if let index = posts.firstIndex(where: { $0.id == postId }) {
            let currentPost = posts[index]
            posts[index] = FeedPost(
                id: currentPost.id,
                authorId: currentPost.authorId,
                authorName: currentPost.authorName,
                authorProfileImage: currentPost.authorProfileImage,
                petId: currentPost.petId,
                petName: currentPost.petName,
                petBreed: currentPost.petBreed,
                mediaItems: currentPost.mediaItems,
                content: currentPost.content,
                location: currentPost.location,
                walkDistance: currentPost.walkDistance,
                walkDuration: currentPost.walkDuration,
                likeCount: currentPost.likeCount,
                commentCount: currentPost.commentCount + 1,
                isLiked: currentPost.isLiked,
                isBookmarked: currentPost.isBookmarked,
                createdAt: currentPost.createdAt
            )
        }
    }

    /// 댓글 좋아요 토글
    func toggleCommentLike(commentId: UUID, postId: UUID) {
        guard var comments = commentsMap[postId],
              let index = comments.firstIndex(where: { $0.id == commentId }) else { return }

        let currentComment = comments[index]
        let newLikeCount = currentComment.isLiked ? currentComment.likeCount - 1 : currentComment.likeCount + 1

        comments[index] = FeedComment(
            id: currentComment.id,
            postId: currentComment.postId,
            authorId: currentComment.authorId,
            authorName: currentComment.authorName,
            authorProfileImage: currentComment.authorProfileImage,
            content: currentComment.content,
            likeCount: newLikeCount,
            isLiked: !currentComment.isLiked,
            createdAt: currentComment.createdAt
        )

        commentsMap[postId] = comments
    }

    /// 샘플 댓글 생성
    private func generateSampleComments(for postId: UUID) -> [FeedComment] {
        let sampleNames = ["댕댕이맘", "산책왕", "멍뭉이사랑", "강아지집사", "해피독"]
        let sampleContents = [
            "너무 귀여워요! 🐶",
            "오늘 날씨 좋았겠네요~",
            "우리 강아지도 데려가고 싶어요!",
            "산책 코스 추천해주세요!",
            "행복해 보여요 ❤️"
        ]

        return (0..<min(3, Int.random(in: 1...5))).map { i in
            FeedComment(
                postId: postId,
                authorName: sampleNames[i % sampleNames.count],
                content: sampleContents[i % sampleContents.count],
                likeCount: Int.random(in: 0...20),
                createdAt: Date().addingTimeInterval(-Double.random(in: 60...86400))
            )
        }
    }
}
