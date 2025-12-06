//
//  RankingView.swift
//  petsanCheck
//
//  Created on 2025-12-06.
//

import SwiftUI

/// 랭킹 및 뱃지 화면
struct RankingView: View {
    @StateObject private var viewModel = RankingViewModel()
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 상단 탭 선택
                Picker("", selection: $selectedTab) {
                    Text("랭킹").tag(0)
                    Text("내 뱃지").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)

                if selectedTab == 0 {
                    RankingTabView(viewModel: viewModel)
                } else {
                    BadgeTabView(viewModel: viewModel)
                }
            }
            .background(AppTheme.background)
            .navigationTitle("랭킹")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await viewModel.refresh()
            }
            .sheet(isPresented: $viewModel.showKakaoLoginPrompt) {
                KakaoLoginPromptView(viewModel: viewModel)
                    .presentationDetents([.medium])
            }
        }
    }
}

// MARK: - 랭킹 탭
struct RankingTabView: View {
    @ObservedObject var viewModel: RankingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 범위 선택 (전체/내 주변)
                RankingScopeSelector(
                    selectedScope: viewModel.selectedScope,
                    nearbyRadius: viewModel.nearbyRadius,
                    onScopeSelect: { scope in
                        viewModel.selectedScope = scope
                        viewModel.loadRankings()
                    },
                    onRadiusChange: { radius in
                        viewModel.nearbyRadius = radius
                        if viewModel.selectedScope == .nearby {
                            viewModel.loadRankings()
                        }
                    }
                )
                .padding(.horizontal)

                // 랭킹 타입 선택
                RankingTypeSelector(
                    selectedType: viewModel.selectedRankingType,
                    onSelect: { viewModel.changeRankingType($0) }
                )
                .padding(.horizontal)

                // 기간 선택
                PeriodSelector(
                    selectedPeriod: viewModel.selectedPeriod,
                    onSelect: { viewModel.changePeriod($0) }
                )
                .padding(.horizontal)

                // 에러 메시지
                if let errorMessage = viewModel.errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .padding(.horizontal)
                }

                // 내 순위 카드
                if let currentUser = viewModel.currentUser {
                    MyRankCard(user: currentUser, rankingType: viewModel.selectedRankingType)
                        .padding(.horizontal)
                }

                // 다음 목표 진행률
                NextGoalProgressCard(viewModel: viewModel)
                    .padding(.horizontal)

                // 상위 3위 포디엄
                if viewModel.rankings.count >= 3 {
                    TopThreePodium(
                        users: Array(viewModel.rankings.prefix(3)),
                        rankingType: viewModel.selectedRankingType
                    )
                    .padding(.horizontal)
                }

                // 전체 랭킹 리스트
                RankingListSection(
                    rankings: viewModel.rankings,
                    rankingType: viewModel.selectedRankingType,
                    scope: viewModel.selectedScope,
                    nearbyRadius: viewModel.nearbyRadius
                )
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
}

// MARK: - 랭킹 타입 선택기
struct RankingTypeSelector: View {
    let selectedType: RankingType
    let onSelect: (RankingType) -> Void

    var body: some View {
        HStack(spacing: 12) {
            ForEach(RankingType.allCases, id: \.self) { type in
                Button(action: { onSelect(type) }) {
                    HStack(spacing: 6) {
                        Image(systemName: type.icon)
                            .font(.subheadline)
                        Text(type.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(selectedType == type ? .white : AppTheme.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(selectedType == type ? AppTheme.primary : AppTheme.cardBackground)
                    .cornerRadius(20)
                    .shadow(color: selectedType == type ? AppTheme.primary.opacity(0.3) : AppTheme.shadow, radius: 4)
                }
            }
        }
    }
}

// MARK: - 기간 선택기
struct PeriodSelector: View {
    let selectedPeriod: RankingPeriod
    let onSelect: (RankingPeriod) -> Void

    var body: some View {
        HStack(spacing: 8) {
            ForEach(RankingPeriod.allCases, id: \.self) { period in
                Button(action: { onSelect(period) }) {
                    Text(period.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(selectedPeriod == period ? AppTheme.primary : AppTheme.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(selectedPeriod == period ? AppTheme.primary.opacity(0.15) : Color.clear)
                        .cornerRadius(12)
                }
            }
            Spacer()
        }
    }
}

// MARK: - 범위 선택기 (전체/내 주변)
struct RankingScopeSelector: View {
    let selectedScope: RankingScope
    let nearbyRadius: Double
    let onScopeSelect: (RankingScope) -> Void
    let onRadiusChange: (Double) -> Void

    @State private var showRadiusPicker = false

    private let radiusOptions: [Double] = [1, 3, 5, 10, 20]

    var body: some View {
        VStack(spacing: 8) {
            scopeButtons
            if showRadiusPicker && selectedScope == .nearby {
                radiusPickerView
            }
        }
    }

    private var scopeButtons: some View {
        HStack(spacing: 12) {
            ForEach(RankingScope.allCases, id: \.self) { scope in
                scopeButton(for: scope)
            }
            Spacer()
            if selectedScope == .nearby {
                radiusButton
            }
        }
    }

    private func scopeButton(for scope: RankingScope) -> some View {
        Button(action: { onScopeSelect(scope) }) {
            HStack(spacing: 6) {
                Image(systemName: scope.icon)
                    .font(.subheadline)
                Text(scope.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(selectedScope == scope ? .white : AppTheme.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(selectedScope == scope ? AppTheme.secondary : AppTheme.cardBackground)
            .cornerRadius(20)
            .shadow(color: selectedScope == scope ? AppTheme.secondary.opacity(0.3) : AppTheme.shadow, radius: 4)
        }
    }

    private var radiusButton: some View {
        Button(action: { showRadiusPicker.toggle() }) {
            HStack(spacing: 4) {
                Image(systemName: "slider.horizontal.3")
                    .font(.caption)
                Text("\(Int(nearbyRadius))km")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(AppTheme.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(AppTheme.secondary.opacity(0.15))
            .cornerRadius(12)
        }
    }

    private var radiusPickerView: some View {
        HStack(spacing: 8) {
            Text("반경:")
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)

            ForEach(radiusOptions, id: \.self) { radius in
                radiusOptionButton(for: radius)
            }

            Spacer()
        }
        .padding(.top, 4)
    }

    private func radiusOptionButton(for radius: Double) -> some View {
        Button(action: {
            onRadiusChange(radius)
            showRadiusPicker = false
        }) {
            Text("\(Int(radius))km")
                .font(.caption)
                .fontWeight(nearbyRadius == radius ? .bold : .regular)
                .foregroundColor(nearbyRadius == radius ? .white : AppTheme.textPrimary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(nearbyRadius == radius ? AppTheme.secondary : AppTheme.cardBackground)
                .cornerRadius(8)
        }
    }
}

// MARK: - 내 순위 카드
struct MyRankCard: View {
    let user: RankingUser
    let rankingType: RankingType

    var body: some View {
        HStack(spacing: 16) {
            // 순위
            ZStack {
                Circle()
                    .fill(AppTheme.primary)
                    .frame(width: 50, height: 50)

                Text("\(user.rank)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }

            // 정보
            VStack(alignment: .leading, spacing: 4) {
                Text("내 순위")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)

                HStack(spacing: 8) {
                    Text(user.petName)
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)

                    Text(user.petBreed)
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(AppTheme.secondary.opacity(0.15))
                        .cornerRadius(4)
                }
            }

            Spacer()

            // 기록
            VStack(alignment: .trailing, spacing: 4) {
                Text(valueText)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.primary)

                Text(rankingType.rawValue)
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [AppTheme.primary.opacity(0.1), AppTheme.cardBackground],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.primary.opacity(0.3), lineWidth: 1)
        )
    }

    private var valueText: String {
        switch rankingType {
        case .distance: return user.distanceText
        case .walkCount: return "\(user.totalWalkCount)회"
        case .duration: return user.durationText
        }
    }
}

// MARK: - 다음 목표 진행률 카드
struct NextGoalProgressCard: View {
    @ObservedObject var viewModel: RankingViewModel

    var body: some View {
        let progress = viewModel.progressToNextBadge(for: viewModel.selectedRankingType)

        if let badgeType = progress.badgeType {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("다음 목표")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.textPrimary)

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: badgeType.icon)
                            .foregroundColor(badgeType.color)
                        Text(badgeType.name)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(AppTheme.textPrimary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(badgeType.color.opacity(0.15))
                    .cornerRadius(12)
                }

                // 진행률 바
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(AppTheme.secondary.opacity(0.2))
                            .frame(height: 12)

                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [AppTheme.primary, badgeType.color],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * min(progress.current / progress.target, 1.0), height: 12)
                    }
                }
                .frame(height: 12)

                // 수치
                HStack {
                    Text(progressText(progress.current))
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)

                    Spacer()

                    Text(progressText(progress.target))
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            .padding()
            .background(AppTheme.cardBackground)
            .cornerRadius(16)
            .shadow(color: AppTheme.shadow, radius: 8)
        }
    }

    private func progressText(_ value: Double) -> String {
        switch viewModel.selectedRankingType {
        case .distance:
            if value < 1000 {
                return String(format: "%.0fm", value)
            } else {
                return String(format: "%.1fkm", value / 1000)
            }
        case .walkCount:
            return "\(Int(value))회"
        case .duration:
            let hours = Int(value) / 3600
            return "\(hours)시간"
        }
    }
}

// MARK: - 상위 3위 포디엄
struct TopThreePodium: View {
    let users: [RankingUser]
    let rankingType: RankingType

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if users.count >= 2 {
                PodiumItem(user: users[1], rank: 2, height: 80, rankingType: rankingType)
            }
            if users.count >= 1 {
                PodiumItem(user: users[0], rank: 1, height: 100, rankingType: rankingType)
            }
            if users.count >= 3 {
                PodiumItem(user: users[2], rank: 3, height: 60, rankingType: rankingType)
            }
        }
        .padding(.vertical, 16)
    }
}

struct PodiumItem: View {
    let user: RankingUser
    let rank: Int
    let height: CGFloat
    let rankingType: RankingType

    var body: some View {
        VStack(spacing: 8) {
            // 프로필
            ZStack {
                Circle()
                    .fill(rankColor.opacity(0.2))
                    .frame(width: rank == 1 ? 70 : 56, height: rank == 1 ? 70 : 56)

                Circle()
                    .stroke(rankColor, lineWidth: 3)
                    .frame(width: rank == 1 ? 70 : 56, height: rank == 1 ? 70 : 56)

                Image(systemName: "pawprint.fill")
                    .font(rank == 1 ? .title : .title2)
                    .foregroundColor(rankColor)

                // 왕관 (1위만)
                if rank == 1 {
                    Image(systemName: "crown.fill")
                        .font(.title3)
                        .foregroundColor(.yellow)
                        .offset(y: -45)
                }
            }

            // 이름
            Text(user.petName)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.textPrimary)
                .lineLimit(1)

            // 기록
            Text(valueText)
                .font(.caption2)
                .foregroundColor(AppTheme.textSecondary)

            // 포디엄
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [rankColor, rankColor.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: height)

                Text("\(rank)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var rankColor: Color {
        switch rank {
        case 1: return Color(red: 1.0, green: 0.84, blue: 0)  // Gold
        case 2: return Color(red: 0.75, green: 0.75, blue: 0.8)  // Silver
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2)  // Bronze
        default: return AppTheme.secondary
        }
    }

    private var valueText: String {
        switch rankingType {
        case .distance: return user.distanceText
        case .walkCount: return "\(user.totalWalkCount)회"
        case .duration: return user.durationText
        }
    }
}

// MARK: - 랭킹 리스트 섹션
struct RankingListSection: View {
    let rankings: [RankingUser]
    let rankingType: RankingType
    var scope: RankingScope = .global
    var nearbyRadius: Double = 5.0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(titleText)
                    .font(.headline)
                    .foregroundColor(AppTheme.textPrimary)

                if scope == .nearby {
                    Text("반경 \(Int(nearbyRadius))km")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.secondary.opacity(0.15))
                        .cornerRadius(8)
                }
            }

            if rankings.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: scope == .nearby ? "location.slash" : "person.3.fill")
                        .font(.largeTitle)
                        .foregroundColor(AppTheme.textSecondary.opacity(0.5))

                    Text(emptyMessage)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                VStack(spacing: 8) {
                    ForEach(rankings) { user in
                        RankingListItem(user: user, rankingType: rankingType)
                    }
                }
            }
        }
    }

    private var titleText: String {
        switch scope {
        case .global:
            return "전체 순위"
        case .nearby:
            return "내 주변 순위"
        case .friends:
            return "친구 순위"
        }
    }

    private var emptyMessage: String {
        switch scope {
        case .global:
            return "아직 랭킹 데이터가 없습니다."
        case .nearby:
            return "주변에 산책 중인 사용자가 없습니다.\n반경을 넓혀보세요."
        case .friends:
            return "앱을 사용하는 카카오톡 친구가 없습니다.\n친구를 초대해보세요!"
        }
    }
}

struct RankingListItem: View {
    let user: RankingUser
    let rankingType: RankingType

    var body: some View {
        HStack(spacing: 12) {
            // 순위
            Text("\(user.rank)")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(user.rank <= 3 ? rankColor : AppTheme.textSecondary)
                .frame(width: 30)

            // 프로필
            Circle()
                .fill(user.isCurrentUser ? AppTheme.primary.opacity(0.2) : AppTheme.secondary.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "pawprint.fill")
                        .foregroundColor(user.isCurrentUser ? AppTheme.primary : AppTheme.secondary)
                )

            // 정보
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(user.petName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.textPrimary)

                    if user.isCurrentUser {
                        Text("나")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppTheme.primary)
                            .cornerRadius(4)
                    }
                }

                Text(user.petBreed)
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }

            Spacer()

            // 뱃지 미리보기
            if !user.badges.isEmpty {
                HStack(spacing: -6) {
                    ForEach(user.badges.prefix(3)) { badge in
                        Image(systemName: badge.type.icon)
                            .font(.caption2)
                            .foregroundColor(.white)
                            .frame(width: 20, height: 20)
                            .background(badge.type.color)
                            .clipShape(Circle())
                    }
                }
            }

            // 기록
            Text(valueText)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.textPrimary)
        }
        .padding()
        .background(user.isCurrentUser ? AppTheme.primary.opacity(0.08) : AppTheme.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(user.isCurrentUser ? AppTheme.primary.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }

    private var rankColor: Color {
        switch user.rank {
        case 1: return Color(red: 1.0, green: 0.84, blue: 0)
        case 2: return Color(red: 0.75, green: 0.75, blue: 0.8)
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2)
        default: return AppTheme.textSecondary
        }
    }

    private var valueText: String {
        switch rankingType {
        case .distance: return user.distanceText
        case .walkCount: return "\(user.totalWalkCount)회"
        case .duration: return user.durationText
        }
    }
}

// MARK: - 뱃지 탭
struct BadgeTabView: View {
    @ObservedObject var viewModel: RankingViewModel
    @State private var selectedBadge: BadgeType?
    @State private var showBadgeDetail = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 획득한 뱃지 요약
                BadgeSummaryCard(
                    earnedCount: viewModel.myBadges.count,
                    totalCount: BadgeType.allCases.count
                )
                .padding(.horizontal)

                // 뱃지 카테고리별 표시
                BadgeCategorySection(
                    title: "거리 뱃지",
                    icon: "map.fill",
                    badges: [.distance1km, .distance5km, .distance10km, .distance50km, .distance100km, .distance500km],
                    viewModel: viewModel,
                    selectedBadge: $selectedBadge,
                    showDetail: $showBadgeDetail
                )

                BadgeCategorySection(
                    title: "횟수 뱃지",
                    icon: "pawprint.fill",
                    badges: [.walks5, .walks10, .walks30, .walks50, .walks100, .walks365],
                    viewModel: viewModel,
                    selectedBadge: $selectedBadge,
                    showDetail: $showBadgeDetail
                )

                BadgeCategorySection(
                    title: "연속 뱃지",
                    icon: "calendar",
                    badges: [.streak3days, .streak7days, .streak30days],
                    viewModel: viewModel,
                    selectedBadge: $selectedBadge,
                    showDetail: $showBadgeDetail
                )

                BadgeCategorySection(
                    title: "특별 뱃지",
                    icon: "star.fill",
                    badges: [.earlyBird, .nightOwl, .rainWalker, .weekendWarrior],
                    viewModel: viewModel,
                    selectedBadge: $selectedBadge,
                    showDetail: $showBadgeDetail
                )
            }
            .padding(.vertical)
        }
        .sheet(isPresented: $showBadgeDetail) {
            if let badge = selectedBadge {
                BadgeDetailSheet(
                    badgeType: badge,
                    isEarned: viewModel.isBadgeEarned(badge)
                )
                .presentationDetents([.medium])
            }
        }
    }
}

// MARK: - 뱃지 요약 카드
struct BadgeSummaryCard: View {
    let earnedCount: Int
    let totalCount: Int

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("획득한 뱃지")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)

                HStack(alignment: .bottom, spacing: 4) {
                    Text("\(earnedCount)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(AppTheme.primary)

                    Text("/ \(totalCount)")
                        .font(.headline)
                        .foregroundColor(AppTheme.textSecondary)
                        .padding(.bottom, 4)
                }
            }

            Spacer()

            // 진행률 원형
            ZStack {
                Circle()
                    .stroke(AppTheme.secondary.opacity(0.2), lineWidth: 8)
                    .frame(width: 70, height: 70)

                Circle()
                    .trim(from: 0, to: Double(earnedCount) / Double(totalCount))
                    .stroke(AppTheme.primary, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 70, height: 70)
                    .rotationEffect(.degrees(-90))

                Text("\(Int(Double(earnedCount) / Double(totalCount) * 100))%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.textPrimary)
            }
        }
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
        .shadow(color: AppTheme.shadow, radius: 8)
    }
}

// MARK: - 뱃지 카테고리 섹션
struct BadgeCategorySection: View {
    let title: String
    let icon: String
    let badges: [BadgeType]
    @ObservedObject var viewModel: RankingViewModel
    @Binding var selectedBadge: BadgeType?
    @Binding var showDetail: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(AppTheme.primary)
                Text(title)
                    .font(.headline)
                    .foregroundColor(AppTheme.textPrimary)
            }
            .padding(.horizontal)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                ForEach(badges, id: \.self) { badge in
                    BadgeItem(
                        badgeType: badge,
                        isEarned: viewModel.isBadgeEarned(badge),
                        onTap: {
                            selectedBadge = badge
                            showDetail = true
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - 뱃지 아이템
struct BadgeItem: View {
    let badgeType: BadgeType
    let isEarned: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isEarned ? badgeType.color.opacity(0.2) : AppTheme.secondary.opacity(0.1))
                        .frame(width: 60, height: 60)

                    Image(systemName: badgeType.icon)
                        .font(.title2)
                        .foregroundColor(isEarned ? badgeType.color : AppTheme.secondary.opacity(0.4))
                }

                Text(badgeType.name)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(isEarned ? AppTheme.textPrimary : AppTheme.textSecondary)
                    .lineLimit(1)
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(AppTheme.cardBackground)
            .cornerRadius(12)
            .opacity(isEarned ? 1 : 0.6)
        }
    }
}

// MARK: - 뱃지 상세 시트
struct BadgeDetailSheet: View {
    let badgeType: BadgeType
    let isEarned: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            // 뱃지 아이콘
            ZStack {
                Circle()
                    .fill(
                        isEarned
                            ? LinearGradient(colors: [badgeType.color, badgeType.color.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [AppTheme.secondary.opacity(0.3), AppTheme.secondary.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 120, height: 120)
                    .shadow(color: isEarned ? badgeType.color.opacity(0.4) : Color.clear, radius: 20)

                Image(systemName: badgeType.icon)
                    .font(.system(size: 50))
                    .foregroundColor(isEarned ? .white : AppTheme.secondary)
            }

            // 뱃지 이름
            Text(badgeType.name)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.textPrimary)

            // 설명
            Text(badgeType.description)
                .font(.body)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)

            // 상태
            HStack(spacing: 8) {
                Image(systemName: isEarned ? "checkmark.circle.fill" : "lock.fill")
                    .foregroundColor(isEarned ? AppTheme.success : AppTheme.textSecondary)

                Text(isEarned ? "획득 완료!" : "아직 획득하지 못했어요")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isEarned ? AppTheme.success : AppTheme.textSecondary)
            }
            .padding()
            .background(isEarned ? AppTheme.success.opacity(0.1) : AppTheme.secondary.opacity(0.1))
            .cornerRadius(12)

            Spacer()

            Button(action: { dismiss() }) {
                Text("확인")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.primary)
                    .cornerRadius(12)
            }
        }
        .padding(24)
        .background(AppTheme.background)
    }
}

// MARK: - 카카오 로그인 프롬프트
struct KakaoLoginPromptView: View {
    @ObservedObject var viewModel: RankingViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            // 카카오 아이콘
            ZStack {
                Circle()
                    .fill(Color(red: 254/255, green: 229/255, blue: 0))
                    .frame(width: 100, height: 100)

                Image(systemName: "person.2.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.black.opacity(0.8))
            }

            // 제목
            Text("카카오톡 친구와 경쟁하기")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.textPrimary)

            // 설명
            Text("카카오톡에 로그인하면 친구들과\n산책 기록을 비교할 수 있어요!")
                .font(.body)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)

            Spacer()

            // 카카오 로그인 버튼
            Button(action: {
                Task {
                    await viewModel.loginWithKakao()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "message.fill")
                        .font(.title3)

                    Text("카카오톡으로 로그인")
                        .font(.headline)
                }
                .foregroundColor(.black.opacity(0.85))
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(red: 254/255, green: 229/255, blue: 0))
                .cornerRadius(12)
            }

            // 취소 버튼
            Button(action: { dismiss() }) {
                Text("나중에 하기")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
        .padding(24)
        .background(AppTheme.background)
    }
}

// MARK: - Preview
#Preview {
    RankingView()
}
