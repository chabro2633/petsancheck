//
//  FeedView.swift
//  petsanCheck
//
//  Created on 2025-11-29.
//

import SwiftUI
import PhotosUI
import AVKit
import CoreLocation
import Combine

/// 피드 화면 (인스타그램 스타일)
struct FeedView: View {
    @StateObject private var viewModel = FeedViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    // 스토리 섹션
                    StorySection(viewModel: viewModel)

                    Divider()
                        .padding(.vertical, 8)

                    // 피드 게시글 목록
                    if viewModel.isLoading {
                        ProgressView()
                            .padding(.top, 50)
                    } else if viewModel.posts.isEmpty {
                        EmptyFeedView()
                    } else {
                        ForEach(viewModel.posts) { post in
                            FeedPostCard(post: post, viewModel: viewModel)
                        }
                    }
                }
            }
            .background(AppTheme.background)
            .navigationTitle("펫산책")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("펫산책")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.textPrimary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: { viewModel.showCreatePost = true }) {
                            Image(systemName: "plus.app")
                                .font(.title3)
                                .foregroundColor(AppTheme.textPrimary)
                        }
                        Button(action: {}) {
                            Image(systemName: "paperplane")
                                .font(.title3)
                                .foregroundColor(AppTheme.textPrimary)
                        }
                    }
                }
            }
            .refreshable {
                await viewModel.refreshPosts()
            }
            .sheet(isPresented: $viewModel.showCreatePost) {
                CreatePostView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showCreateStory) {
                CreateStoryView(viewModel: viewModel)
            }
            .fullScreenCover(isPresented: $viewModel.showStoryViewer) {
                if let story = viewModel.selectedStory {
                    StoryViewerView(
                        stories: viewModel.stories,
                        initialStory: story,
                        onDismiss: { viewModel.showStoryViewer = false }
                    )
                }
            }
        }
    }
}

// MARK: - 스토리 섹션
struct StorySection: View {
    @ObservedObject var viewModel: FeedViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                // 내 스토리 추가 버튼
                Button(action: { viewModel.showCreateStory = true }) {
                    VStack(spacing: 4) {
                        ZStack(alignment: .bottomTrailing) {
                            Circle()
                                .fill(AppTheme.cardBackground)
                                .frame(width: 68, height: 68)
                                .overlay(
                                    Circle()
                                        .stroke(AppTheme.secondary.opacity(0.3), lineWidth: 1)
                                )
                                .overlay(
                                    Image(systemName: "pawprint.fill")
                                        .font(.title2)
                                        .foregroundColor(AppTheme.primary)
                                )

                            // + 버튼
                            Circle()
                                .fill(AppTheme.primary)
                                .frame(width: 22, height: 22)
                                .overlay(
                                    Image(systemName: "plus")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                )
                                .offset(x: 2, y: 2)
                        }
                        Text("스토리 추가")
                            .font(.caption2)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }

                // 스토리 목록
                ForEach(viewModel.stories) { story in
                    StoryItemView(story: story) {
                        viewModel.selectedStory = story
                        viewModel.showStoryViewer = true
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
    }
}

struct StoryItemView: View {
    let story: Story
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    // 스토리 있음 표시 (그라데이션 링)
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.orange, .pink, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 72, height: 72)

                    if let imageData = story.petProfileImage,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 64, height: 64)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(AppTheme.primary.opacity(0.2))
                            .frame(width: 64, height: 64)
                            .overlay(
                                Image(systemName: "pawprint.fill")
                                    .font(.title2)
                                    .foregroundColor(AppTheme.primary)
                            )
                    }
                }

                Text(story.petName)
                    .font(.caption2)
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(1)
            }
            .frame(width: 76)
        }
    }
}

// MARK: - 피드 게시글 카드
struct FeedPostCard: View {
    let post: FeedPost
    @ObservedObject var viewModel: FeedViewModel
    @State private var currentImageIndex = 0
    @State private var showComments = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 헤더 (프로필 정보)
            PostHeader(post: post)

            // 이미지/영상
            PostMediaView(post: post, currentIndex: $currentImageIndex)

            // 액션 버튼들
            PostActions(post: post, viewModel: viewModel, showComments: $showComments)

            // 좋아요 수
            if post.likeCount > 0 {
                Text("좋아요 \(post.likeCount)개")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.textPrimary)
                    .padding(.horizontal)
                    .padding(.bottom, 4)
            }

            // 본문 내용
            PostContent(post: post)

            // 댓글 보기
            if post.commentCount > 0 {
                Button(action: { showComments = true }) {
                    Text("댓글 \(post.commentCount)개 모두 보기")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                }
                .padding(.horizontal)
                .padding(.bottom, 4)
            }

            // 작성 시간
            Text(post.relativeTimeString)
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
                .padding(.horizontal)
                .padding(.bottom, 16)
        }
        .background(AppTheme.cardBackground)
        .sheet(isPresented: $showComments) {
            CommentsSheetView(post: post, viewModel: viewModel)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - 댓글 시트 뷰
struct CommentsSheetView: View {
    let post: FeedPost
    @ObservedObject var viewModel: FeedViewModel
    @State private var newCommentText = ""
    @FocusState private var isCommentFieldFocused: Bool

    var comments: [FeedComment] {
        viewModel.commentsMap[post.id] ?? []
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 댓글 목록
                ScrollView {
                    LazyVStack(spacing: 0) {
                        if comments.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "bubble.left.and.bubble.right")
                                    .font(.system(size: 40))
                                    .foregroundColor(AppTheme.secondary)

                                Text("아직 댓글이 없어요")
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.textSecondary)

                                Text("첫 번째 댓글을 남겨보세요!")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 60)
                        } else {
                            ForEach(comments) { comment in
                                CommentRow(
                                    comment: comment,
                                    onLike: {
                                        viewModel.toggleCommentLike(commentId: comment.id, postId: post.id)
                                    }
                                )
                            }
                        }
                    }
                    .padding(.top, 8)
                }

                Divider()

                // 댓글 입력 영역
                HStack(spacing: 12) {
                    // 프로필 이미지
                    Circle()
                        .fill(AppTheme.primary.opacity(0.2))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.primary)
                        )

                    // 입력 필드
                    HStack {
                        TextField("댓글 달기...", text: $newCommentText)
                            .font(.subheadline)
                            .focused($isCommentFieldFocused)

                        if !newCommentText.isEmpty {
                            Button(action: submitComment) {
                                Text("게시")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(AppTheme.primary)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(AppTheme.background)
                    .cornerRadius(20)
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(AppTheme.cardBackground)
            }
            .background(AppTheme.background)
            .navigationTitle("댓글")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.loadComments(for: post.id)
            }
        }
    }

    private func submitComment() {
        guard !newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        viewModel.addComment(to: post.id, content: newCommentText)
        newCommentText = ""
        isCommentFieldFocused = false
    }
}

// MARK: - 댓글 행
struct CommentRow: View {
    let comment: FeedComment
    let onLike: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 프로필 이미지
            Circle()
                .fill(AppTheme.secondary.opacity(0.2))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.secondary)
                )

            VStack(alignment: .leading, spacing: 4) {
                // 작성자 이름 + 내용
                HStack(alignment: .top) {
                    Text(comment.authorName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.textPrimary)
                    +
                    Text(" ")
                    +
                    Text(comment.content)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textPrimary)

                    Spacer()
                }

                // 시간 + 좋아요 수
                HStack(spacing: 16) {
                    Text(relativeTimeString)
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)

                    if comment.likeCount > 0 {
                        Text("좋아요 \(comment.likeCount)개")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    }

                    Button(action: {}) {
                        Text("답글 달기")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
            }

            // 좋아요 버튼
            Button(action: onLike) {
                Image(systemName: comment.isLiked ? "heart.fill" : "heart")
                    .font(.caption)
                    .foregroundColor(comment.isLiked ? .red : AppTheme.textSecondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    private var relativeTimeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: comment.createdAt, relativeTo: Date())
    }
}

// MARK: - 게시글 헤더
struct PostHeader: View {
    let post: FeedPost

    var body: some View {
        HStack(spacing: 12) {
            // 반려견 프로필 이미지
            Circle()
                .fill(AppTheme.primary.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "pawprint.fill")
                        .font(.title3)
                        .foregroundColor(AppTheme.primary)
                )

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(post.petName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.textPrimary)

                    if let breed = post.petBreed {
                        Text(breed)
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppTheme.secondary.opacity(0.15))
                            .cornerRadius(4)
                    }
                }

                if let location = post.location {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.caption2)
                        Text(location)
                    }
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
                }
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
}

// MARK: - 게시글 미디어 뷰 (사진/영상)
struct PostMediaView: View {
    let post: FeedPost
    @Binding var currentIndex: Int

    var body: some View {
        ZStack {
            if post.hasMedia {
                // 실제 미디어 표시
                TabView(selection: $currentIndex) {
                    ForEach(Array(post.mediaItems.enumerated()), id: \.element.id) { index, item in
                        MediaItemView(item: item)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: post.mediaItems.count > 1 ? .automatic : .never))
                .aspectRatio(1, contentMode: .fit)
            } else {
                // 플레이스홀더 이미지
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppTheme.primary.opacity(0.3),
                                AppTheme.secondary.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        VStack(spacing: 12) {
                            Image(systemName: "pawprint.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(AppTheme.primary.opacity(0.6))

                            Text(post.petName)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(AppTheme.textPrimary.opacity(0.8))
                        }
                    )
            }

            // 산책 정보 배지
            if post.walkDistance != nil || post.walkDuration != nil {
                VStack {
                    HStack {
                        Spacer()
                        WalkInfoBadge(post: post)
                            .padding(12)
                    }
                    Spacer()
                }
            }

            // 영상 표시 아이콘
            if post.hasVideo {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "video.fill")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(6)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                            .padding(12)
                    }
                }
            }
        }
    }
}

// MARK: - 미디어 아이템 뷰
struct MediaItemView: View {
    let item: MediaItem

    var body: some View {
        if let data = item.data, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .clipped()
        } else {
            // 플레이스홀더
            Rectangle()
                .fill(AppTheme.secondary.opacity(0.2))
                .overlay(
                    Image(systemName: item.type == .video ? "video.fill" : "photo.fill")
                        .font(.largeTitle)
                        .foregroundColor(AppTheme.secondary)
                )
        }
    }
}

// MARK: - 산책 정보 배지
struct WalkInfoBadge: View {
    let post: FeedPost

    var body: some View {
        HStack(spacing: 8) {
            if let distance = post.walkDistanceText {
                HStack(spacing: 4) {
                    Image(systemName: "figure.walk")
                        .font(.caption)
                    Text(distance)
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }

            if let duration = post.walkDurationText {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                    Text(duration)
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
}

// MARK: - 게시글 액션 버튼
struct PostActions: View {
    let post: FeedPost
    @ObservedObject var viewModel: FeedViewModel
    @Binding var showComments: Bool

    var body: some View {
        HStack(spacing: 16) {
            // 좋아요
            Button(action: { viewModel.toggleLike(for: post) }) {
                Image(systemName: post.isLiked ? "heart.fill" : "heart")
                    .font(.title2)
                    .foregroundColor(post.isLiked ? .red : AppTheme.textPrimary)
            }

            // 댓글
            Button(action: { showComments = true }) {
                Image(systemName: "bubble.right")
                    .font(.title2)
                    .foregroundColor(AppTheme.textPrimary)
            }

            // 공유
            Button(action: {}) {
                Image(systemName: "paperplane")
                    .font(.title2)
                    .foregroundColor(AppTheme.textPrimary)
            }

            Spacer()

            // 북마크
            Button(action: { viewModel.toggleBookmark(for: post) }) {
                Image(systemName: post.isBookmarked ? "bookmark.fill" : "bookmark")
                    .font(.title2)
                    .foregroundColor(post.isBookmarked ? AppTheme.primary : AppTheme.textPrimary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
}

// MARK: - 게시글 본문
struct PostContent: View {
    let post: FeedPost
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(post.content)
                .font(.subheadline)
                .foregroundColor(AppTheme.textPrimary)
                .lineLimit(isExpanded ? nil : 3)

            if post.content.count > 100 && !isExpanded {
                Button(action: { isExpanded = true }) {
                    Text("더 보기")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}

// MARK: - 빈 피드 뷰
struct EmptyFeedView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.secondary)

            Text("아직 게시글이 없어요")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.textPrimary)

            Text("첫 번째 산책 피드를 올려보세요!")
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
        }
        .padding(.top, 80)
    }
}

// MARK: - 게시글 작성 화면
struct CreatePostView: View {
    @ObservedObject var viewModel: FeedViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var locationHelper = PostLocationHelper()

    // 미디어 선택
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var mediaItems: [MediaItem] = []
    @State private var isLoadingMedia = false

    // 반려견 정보
    @State private var selectedDog: Dog?
    @State private var petName = ""
    @State private var petBreed = ""
    @State private var showDogPicker = false
    @State private var isNewDog = false

    // 게시글 정보
    @State private var content = ""
    @State private var location = ""
    @State private var includeWalkData = true  // 기본값 true로 변경

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 미디어 선택 영역
                    MediaPickerSection(
                        selectedPhotos: $selectedPhotos,
                        mediaItems: $mediaItems,
                        isLoadingMedia: $isLoadingMedia
                    )

                    // 반려견 선택/입력 영역
                    DogSelectionSection(
                        viewModel: viewModel,
                        selectedDog: $selectedDog,
                        petName: $petName,
                        petBreed: $petBreed,
                        isNewDog: $isNewDog
                    )

                    // 위치 정보 (자동 입력)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("위치")
                                .font(.headline)
                                .foregroundColor(AppTheme.textPrimary)

                            Spacer()

                            if locationHelper.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else if !location.isEmpty {
                                Button(action: {
                                    locationHelper.refreshLocation()
                                }) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.primary)
                                }
                            }
                        }

                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(AppTheme.primary)
                                .font(.caption)

                            Text(location.isEmpty ? "위치를 가져오는 중..." : location)
                                .font(.subheadline)
                                .foregroundColor(location.isEmpty ? AppTheme.textSecondary : AppTheme.textPrimary)

                            Spacer()
                        }
                        .padding(12)
                        .background(AppTheme.cardBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppTheme.secondary.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal)

                    // 산책 데이터 포함 (기본 true)
                    Toggle(isOn: $includeWalkData) {
                        HStack {
                            Image(systemName: "figure.walk")
                                .foregroundColor(AppTheme.primary)
                            Text("최근 산책 데이터 포함")
                                .foregroundColor(AppTheme.textPrimary)
                        }
                    }
                    .padding(.horizontal)
                    .tint(AppTheme.primary)

                    // 본문 입력
                    VStack(alignment: .leading, spacing: 12) {
                        Text("내용")
                            .font(.headline)
                            .foregroundColor(AppTheme.textPrimary)

                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $content)
                                .frame(minHeight: 120)
                                .padding(8)
                                .scrollContentBackground(.hidden)
                                .foregroundColor(.black)  // 텍스트 색상 검은색
                                .background(AppTheme.cardBackground)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppTheme.secondary.opacity(0.3), lineWidth: 1)
                                )

                            if content.isEmpty {
                                Text("오늘의 산책은 어땠나요?")
                                    .foregroundColor(AppTheme.textSecondary)
                                    .padding(.leading, 12)
                                    .padding(.top, 16)
                                    .allowsHitTesting(false)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(AppTheme.background)
            .navigationTitle("새 게시글")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.textPrimary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("공유") {
                        sharePost()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(canPost ? AppTheme.primary : AppTheme.textSecondary)
                    .disabled(!canPost)
                }
            }
            .onChange(of: selectedDog) { _, newDog in
                if let dog = newDog {
                    petName = dog.name
                    petBreed = dog.breed
                    isNewDog = false
                }
            }
            .onChange(of: locationHelper.locationName) { _, newLocation in
                if !newLocation.isEmpty {
                    location = newLocation
                }
            }
            .onAppear {
                // 이미 위치가 있으면 사용
                if !locationHelper.locationName.isEmpty {
                    location = locationHelper.locationName
                }
            }
        }
    }

    private var canPost: Bool {
        !content.isEmpty && !petName.isEmpty
    }

    private func sharePost() {
        // 새 반려견이면 프로필에 저장
        var dogToUse = selectedDog
        if isNewDog && !petName.isEmpty && !petBreed.isEmpty {
            dogToUse = viewModel.registerNewDog(name: petName, breed: petBreed)
        }

        viewModel.createPost(
            content: content,
            selectedDog: dogToUse,
            petName: petName,
            petBreed: petBreed.isEmpty ? nil : petBreed,
            mediaItems: mediaItems,
            location: location.isEmpty ? nil : location,
            walkDistance: includeWalkData ? 2500 : nil,
            walkDuration: includeWalkData ? 2400 : nil
        )
        dismiss()
    }
}

// MARK: - 미디어 선택 섹션
struct MediaPickerSection: View {
    @Binding var selectedPhotos: [PhotosPickerItem]
    @Binding var mediaItems: [MediaItem]
    @Binding var isLoadingMedia: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("사진/영상")
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // 추가 버튼
                    PhotosPicker(
                        selection: $selectedPhotos,
                        maxSelectionCount: 10,
                        matching: .any(of: [.images, .videos])
                    ) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppTheme.secondary.opacity(0.1))
                                .frame(width: 100, height: 100)

                            VStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title)
                                    .foregroundColor(AppTheme.primary)
                                Text("추가")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                        }
                    }

                    // 선택된 미디어 미리보기
                    ForEach(Array(mediaItems.enumerated()), id: \.element.id) { index, item in
                        ZStack(alignment: .topTrailing) {
                            if let data = item.data, let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppTheme.secondary.opacity(0.3))
                                    .frame(width: 100, height: 100)
                                    .overlay(
                                        Image(systemName: item.type == .video ? "video.fill" : "photo.fill")
                                            .foregroundColor(AppTheme.secondary)
                                    )
                            }

                            // 영상 표시
                            if item.type == .video {
                                Image(systemName: "play.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .shadow(radius: 2)
                            }

                            // 삭제 버튼
                            Button(action: {
                                mediaItems.remove(at: index)
                                if index < selectedPhotos.count {
                                    selectedPhotos.remove(at: index)
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white)
                                    .background(Circle().fill(Color.black.opacity(0.5)))
                            }
                            .padding(4)
                        }
                    }

                    if isLoadingMedia {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppTheme.secondary.opacity(0.1))
                            .frame(width: 100, height: 100)
                            .overlay(ProgressView())
                    }
                }
                .padding(.horizontal)
            }
        }
        .onChange(of: selectedPhotos) { _, newItems in
            Task {
                await loadMedia(from: newItems)
            }
        }
    }

    private func loadMedia(from items: [PhotosPickerItem]) async {
        isLoadingMedia = true
        var newMediaItems: [MediaItem] = []

        for item in items {
            // 이미지 로드 시도
            if let data = try? await item.loadTransferable(type: Data.self) {
                let isVideo = item.supportedContentTypes.contains { $0.conforms(to: .movie) }
                let mediaItem = MediaItem(
                    type: isVideo ? .video : .photo,
                    data: data
                )
                newMediaItems.append(mediaItem)
            }
        }

        await MainActor.run {
            mediaItems = newMediaItems
            isLoadingMedia = false
        }
    }
}

// MARK: - 반려견 선택 섹션
struct DogSelectionSection: View {
    @ObservedObject var viewModel: FeedViewModel
    @Binding var selectedDog: Dog?
    @Binding var petName: String
    @Binding var petBreed: String
    @Binding var isNewDog: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("반려견 정보")
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)

            if !viewModel.registeredDogs.isEmpty {
                // 등록된 반려견이 있으면 선택 가능
                VStack(spacing: 12) {
                    // 등록된 반려견 선택
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.registeredDogs) { dog in
                                DogSelectionCard(
                                    dog: dog,
                                    isSelected: selectedDog?.id == dog.id
                                ) {
                                    selectedDog = dog
                                    isNewDog = false
                                }
                            }

                            // 새 반려견 추가 버튼
                            Button(action: {
                                selectedDog = nil
                                petName = ""
                                petBreed = ""
                                isNewDog = true
                            }) {
                                VStack(spacing: 8) {
                                    ZStack {
                                        Circle()
                                            .stroke(isNewDog ? AppTheme.primary : AppTheme.secondary.opacity(0.3), lineWidth: 2)
                                            .frame(width: 60, height: 60)

                                        Image(systemName: "plus")
                                            .font(.title2)
                                            .foregroundColor(isNewDog ? AppTheme.primary : AppTheme.secondary)
                                    }
                                    Text("새 반려견")
                                        .font(.caption)
                                        .foregroundColor(isNewDog ? AppTheme.primary : AppTheme.textSecondary)
                                }
                            }
                        }
                    }

                    // 새 반려견 정보 입력 (isNewDog일 때만)
                    if isNewDog {
                        VStack(spacing: 12) {
                            TextField("반려견 이름", text: $petName)
                                .textFieldStyle(CustomTextFieldStyle())

                            TextField("견종", text: $petBreed)
                                .textFieldStyle(CustomTextFieldStyle())

                            Text("입력한 반려견 정보가 프로필에 저장됩니다")
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                }
            } else {
                // 등록된 반려견이 없으면 직접 입력
                VStack(spacing: 12) {
                    TextField("반려견 이름", text: $petName)
                        .textFieldStyle(CustomTextFieldStyle())

                    TextField("견종", text: $petBreed)
                        .textFieldStyle(CustomTextFieldStyle())

                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(AppTheme.primary)
                        Text("입력한 반려견 정보가 프로필에 저장됩니다")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                .onAppear {
                    isNewDog = true
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - 반려견 선택 카드
struct DogSelectionCard: View {
    let dog: Dog
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? AppTheme.primary.opacity(0.2) : AppTheme.secondary.opacity(0.1))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Circle()
                                .stroke(isSelected ? AppTheme.primary : Color.clear, lineWidth: 2)
                        )

                    if let imageData = dog.profileImageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 56, height: 56)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "pawprint.fill")
                            .font(.title2)
                            .foregroundColor(isSelected ? AppTheme.primary : AppTheme.secondary)
                    }

                    if isSelected {
                        Circle()
                            .fill(AppTheme.primary)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            )
                            .offset(x: 20, y: 20)
                    }
                }

                Text(dog.name)
                    .font(.caption)
                    .foregroundColor(isSelected ? AppTheme.primary : AppTheme.textPrimary)
                    .lineLimit(1)
            }
        }
    }
}

// MARK: - 커스텀 텍스트필드 스타일
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .background(AppTheme.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.secondary.opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - 스토리 뷰어
struct StoryViewerView: View {
    let stories: [Story]
    let initialStory: Story
    let onDismiss: () -> Void

    @State private var currentStoryIndex: Int = 0
    @State private var currentItemIndex: Int = 0
    @State private var progress: CGFloat = 0
    @State private var timer: Timer?

    init(stories: [Story], initialStory: Story, onDismiss: @escaping () -> Void) {
        self.stories = stories
        self.initialStory = initialStory
        self.onDismiss = onDismiss
        self._currentStoryIndex = State(initialValue: stories.firstIndex(where: { $0.id == initialStory.id }) ?? 0)
    }

    private var currentStory: Story {
        stories[currentStoryIndex]
    }

    private var currentItem: StoryItem? {
        guard currentItemIndex < currentStory.items.count else { return nil }
        return currentStory.items[currentItemIndex]
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 배경
                Color.black.ignoresSafeArea()

                // 터치 영역 (아래에 배치)
                HStack(spacing: 0) {
                    // 이전
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .onTapGesture { previousItem() }

                    // 다음
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .onTapGesture { nextItem() }
                }

                // 스토리 콘텐츠
                if let item = currentItem {
                    StoryContentView(item: item, petName: currentStory.petName)
                }

                // 오버레이 UI (위에 배치 - 터치 가능)
                VStack(spacing: 0) {
                    // 프로그레스 바와 헤더
                    VStack(spacing: 0) {
                        // 프로그레스 바
                        HStack(spacing: 4) {
                            ForEach(0..<currentStory.items.count, id: \.self) { index in
                                GeometryReader { geo in
                                    Rectangle()
                                        .fill(Color.white.opacity(0.3))
                                        .overlay(
                                            Rectangle()
                                                .fill(Color.white)
                                                .frame(width: index < currentItemIndex ? geo.size.width :
                                                        (index == currentItemIndex ? geo.size.width * progress : 0))
                                            , alignment: .leading
                                        )
                                }
                                .frame(height: 2)
                                .cornerRadius(1)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)

                        // 헤더
                        HStack(spacing: 12) {
                            // 프로필 이미지
                            if let imageData = currentStory.petProfileImage,
                               let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 36, height: 36)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Image(systemName: "pawprint.fill")
                                            .foregroundColor(.white)
                                    )
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(currentStory.petName)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)

                                if let item = currentItem {
                                    Text(item.relativeTimeString)
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }

                            Spacer()

                            // X 버튼 - 터치 영역 확대
                            Button(action: onDismiss) {
                                Image(systemName: "xmark")
                                    .font(.title3)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .contentShape(Rectangle())
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                    .background(
                        LinearGradient(
                            colors: [Color.black.opacity(0.6), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 120)
                        .allowsHitTesting(false)
                    , alignment: .top)

                    Spacer()

                    // 하단 정보
                    if let item = currentItem {
                        StoryBottomInfo(item: item)
                    }
                }
            }
        }
        .onAppear { startTimer() }
        .onDisappear { stopTimer() }
    }

    private func startTimer() {
        progress = 0
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            withAnimation(.linear(duration: 0.05)) {
                progress += 0.01  // 5초에 완료
            }
            if progress >= 1 {
                nextItem()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func nextItem() {
        stopTimer()
        if currentItemIndex < currentStory.items.count - 1 {
            currentItemIndex += 1
            startTimer()
        } else if currentStoryIndex < stories.count - 1 {
            currentStoryIndex += 1
            currentItemIndex = 0
            startTimer()
        } else {
            onDismiss()
        }
    }

    private func previousItem() {
        stopTimer()
        if currentItemIndex > 0 {
            currentItemIndex -= 1
        } else if currentStoryIndex > 0 {
            currentStoryIndex -= 1
            currentItemIndex = stories[currentStoryIndex].items.count - 1
        }
        startTimer()
    }
}

// MARK: - 스토리 콘텐츠 뷰
struct StoryContentView: View {
    let item: StoryItem
    let petName: String

    var body: some View {
        Group {
            if item.type == .walkRoute, let route = item.walkRoute, !route.isEmpty {
                // 산책 경로 표시
                StoryWalkRouteView(item: item, petName: petName)
            } else if let data = item.mediaData, let uiImage = UIImage(data: data) {
                // 사진/영상
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // 플레이스홀더
                VStack(spacing: 20) {
                    Image(systemName: "pawprint.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white.opacity(0.5))
                    Text(petName)
                        .font(.title)
                        .foregroundColor(.white)
                }
            }
        }
    }
}

// MARK: - 산책 경로 스토리 뷰
struct StoryWalkRouteView: View {
    let item: StoryItem
    let petName: String

    var body: some View {
        ZStack {
            // 지도 배경 (간단한 시각화)
            LinearGradient(
                colors: [
                    Color(red: 0.2, green: 0.3, blue: 0.4),
                    Color(red: 0.15, green: 0.25, blue: 0.35)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // 경로 시각화
            if let route = item.walkRoute {
                WalkRoutePathView(coordinates: route)
                    .padding(40)
            }

            // 산책 정보 카드
            VStack {
                Spacer()

                VStack(spacing: 16) {
                    // 반려견 이름
                    HStack {
                        Image(systemName: "pawprint.fill")
                            .font(.title2)
                        Text("\(petName)의 산책")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)

                    // 산책 통계
                    HStack(spacing: 30) {
                        if let distance = item.walkDistanceText {
                            VStack(spacing: 4) {
                                Text(distance)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Text("거리")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }

                        if let duration = item.walkDurationText {
                            VStack(spacing: 4) {
                                Text(duration)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Text("시간")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }
                }
                .padding(24)
                .background(.ultraThinMaterial.opacity(0.8))
                .cornerRadius(20)
                .padding(.horizontal, 20)
                .padding(.bottom, 120)
            }
        }
    }
}

// MARK: - 산책 경로 Path 시각화
struct WalkRoutePathView: View {
    let coordinates: [WalkRouteCoordinate]

    var body: some View {
        GeometryReader { geometry in
            let path = createPath(in: geometry.size)

            ZStack {
                // 경로 라인
                path
                    .stroke(
                        LinearGradient(
                            colors: [AppTheme.primary, AppTheme.success],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
                    )
                    .shadow(color: AppTheme.primary.opacity(0.5), radius: 8)

                // 시작점
                if let first = normalizedPoints(in: geometry.size).first {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 16, height: 16)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 3)
                        )
                        .position(first)
                }

                // 끝점
                if let last = normalizedPoints(in: geometry.size).last {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 16, height: 16)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 3)
                        )
                        .position(last)
                }
            }
        }
    }

    private func normalizedPoints(in size: CGSize) -> [CGPoint] {
        guard !coordinates.isEmpty else { return [] }

        let lats = coordinates.map { $0.latitude }
        let lons = coordinates.map { $0.longitude }

        guard let minLat = lats.min(), let maxLat = lats.max(),
              let minLon = lons.min(), let maxLon = lons.max() else { return [] }

        let latRange = maxLat - minLat
        let lonRange = maxLon - minLon
        let padding: CGFloat = 20

        return coordinates.map { coord in
            let x = latRange > 0 ? CGFloat((coord.longitude - minLon) / lonRange) * (size.width - padding * 2) + padding : size.width / 2
            let y = lonRange > 0 ? CGFloat(1 - (coord.latitude - minLat) / latRange) * (size.height - padding * 2) + padding : size.height / 2
            return CGPoint(x: x, y: y)
        }
    }

    private func createPath(in size: CGSize) -> Path {
        let points = normalizedPoints(in: size)
        var path = Path()

        guard let first = points.first else { return path }
        path.move(to: first)

        for point in points.dropFirst() {
            path.addLine(to: point)
        }

        return path
    }
}

// MARK: - 스토리 하단 정보
struct StoryBottomInfo: View {
    let item: StoryItem

    var body: some View {
        VStack(spacing: 8) {
            if let location = item.location {
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.caption)
                    Text(location)
                        .font(.caption)
                }
                .foregroundColor(.white.opacity(0.8))
            }

            if let caption = item.caption {
                Text(caption)
                    .font(.body)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .padding(.bottom, 40)
        .background(
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)
        )
    }
}

// MARK: - 스토리 생성 화면
struct CreateStoryView: View {
    @ObservedObject var viewModel: FeedViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var mediaData: Data?
    @State private var mediaType: StoryItem.MediaType = .photo
    @State private var caption = ""
    @State private var location = ""
    @State private var selectedDog: Dog?
    @State private var petName = ""
    @State private var petBreed = ""
    @State private var isNewDog = false
    @State private var isLoadingMedia = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 미디어 선택
                    PhotosPicker(
                        selection: $selectedPhoto,
                        matching: .any(of: [.images, .videos])
                    ) {
                        ZStack {
                            if let data = mediaData, let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 300)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            } else {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(AppTheme.secondary.opacity(0.1))
                                    .frame(height: 300)
                                    .overlay(
                                        VStack(spacing: 16) {
                                            if isLoadingMedia {
                                                ProgressView()
                                            } else {
                                                Image(systemName: "camera.fill")
                                                    .font(.system(size: 50))
                                                    .foregroundColor(AppTheme.primary)
                                                Text("사진 또는 영상 선택")
                                                    .font(.headline)
                                                    .foregroundColor(AppTheme.textSecondary)
                                            }
                                        }
                                    )
                            }
                        }
                    }
                    .padding(.horizontal)

                    // 반려견 선택
                    DogSelectionSection(
                        viewModel: viewModel,
                        selectedDog: $selectedDog,
                        petName: $petName,
                        petBreed: $petBreed,
                        isNewDog: $isNewDog
                    )

                    // 캡션
                    VStack(alignment: .leading, spacing: 12) {
                        Text("캡션")
                            .font(.headline)
                            .foregroundColor(AppTheme.textPrimary)

                        TextField("스토리에 한마디...", text: $caption)
                            .textFieldStyle(CustomTextFieldStyle())
                    }
                    .padding(.horizontal)

                    // 위치
                    VStack(alignment: .leading, spacing: 12) {
                        Text("위치")
                            .font(.headline)
                            .foregroundColor(AppTheme.textPrimary)

                        TextField("위치 추가 (선택)", text: $location)
                            .textFieldStyle(CustomTextFieldStyle())
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(AppTheme.background)
            .navigationTitle("스토리 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.textPrimary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("공유") {
                        shareStory()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(canShare ? AppTheme.primary : AppTheme.textSecondary)
                    .disabled(!canShare)
                }
            }
            .onChange(of: selectedPhoto) { _, newItem in
                Task {
                    await loadMedia(from: newItem)
                }
            }
            .onChange(of: selectedDog) { _, newDog in
                if let dog = newDog {
                    petName = dog.name
                    petBreed = dog.breed
                    isNewDog = false
                }
            }
        }
    }

    private var canShare: Bool {
        mediaData != nil && !petName.isEmpty
    }

    private func loadMedia(from item: PhotosPickerItem?) async {
        guard let item = item else { return }

        isLoadingMedia = true
        if let data = try? await item.loadTransferable(type: Data.self) {
            let isVideo = item.supportedContentTypes.contains { $0.conforms(to: .movie) }
            await MainActor.run {
                mediaData = data
                mediaType = isVideo ? .video : .photo
                isLoadingMedia = false
            }
        } else {
            await MainActor.run {
                isLoadingMedia = false
            }
        }
    }

    private func shareStory() {
        guard let data = mediaData else { return }

        // 새 반려견이면 프로필에 저장
        var dogToUse = selectedDog
        if isNewDog && !petName.isEmpty && !petBreed.isEmpty {
            dogToUse = viewModel.registerNewDog(name: petName, breed: petBreed)
        }

        viewModel.createStory(
            selectedDog: dogToUse,
            petName: petName,
            petBreed: petBreed.isEmpty ? nil : petBreed,
            mediaData: data,
            mediaType: mediaType,
            caption: caption.isEmpty ? nil : caption,
            location: location.isEmpty ? nil : location
        )

        dismiss()
    }
}

// MARK: - 게시글 위치 도우미
class PostLocationHelper: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var locationName: String = ""
    @Published var isLoading = false

    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        requestLocation()
    }

    func requestLocation() {
        isLoading = true

        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else if locationManager.authorizationStatus == .authorizedWhenInUse ||
                  locationManager.authorizationStatus == .authorizedAlways {
            locationManager.requestLocation()
        } else {
            isLoading = false
        }
    }

    func refreshLocation() {
        requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            isLoading = false
            return
        }

        // 역지오코딩으로 위치 이름 가져오기
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                self?.isLoading = false

                if let placemark = placemarks?.first {
                    var components: [String] = []

                    // 시/도
                    if let administrativeArea = placemark.administrativeArea {
                        components.append(administrativeArea)
                    }

                    // 구/군
                    if let locality = placemark.locality {
                        components.append(locality)
                    } else if let subAdministrativeArea = placemark.subAdministrativeArea {
                        components.append(subAdministrativeArea)
                    }

                    // 동/읍/면
                    if let subLocality = placemark.subLocality {
                        components.append(subLocality)
                    }

                    self?.locationName = components.joined(separator: " ")
                }
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[PostLocation] Error: \(error.localizedDescription)")
        isLoading = false
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse ||
           manager.authorizationStatus == .authorizedAlways {
            locationManager.requestLocation()
        }
    }
}

#Preview {
    FeedView()
}
