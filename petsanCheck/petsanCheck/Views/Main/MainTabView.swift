//
//  MainTabView.swift
//  petsanCheck
//
//  Created on 2025-11-29.
//

import SwiftUI

/// 메인 탭 뷰
struct MainTabView: View {
    @State private var selectedTab = 0
    @ObservedObject private var walkViewModel = WalkViewModel.shared

    var body: some View {
        ZStack(alignment: .top) {
            TabView(selection: $selectedTab) {
                // 홈 탭
                HomeView(selectedTab: $selectedTab)
                    .tabItem {
                        Label("홈", systemImage: "house.fill")
                    }
                    .tag(0)

                // 산책 탭
                WalkView()
                    .tabItem {
                        Label("산책", systemImage: "figure.walk")
                    }
                    .tag(1)

                // 피드 탭
                FeedView()
                    .tabItem {
                        Label("피드", systemImage: "photo.on.rectangle")
                    }
                    .tag(2)

                // 산책 기록 탭
                NavigationStack {
                    WalkHistoryView()
                }
                    .tabItem {
                        Label("산책기록", systemImage: "chart.bar.fill")
                    }
                    .tag(3)

                // 병원 탭
                HospitalView()
                    .tabItem {
                        Label("병원", systemImage: "cross.fill")
                    }
                    .tag(4)
            }
            .tint(AppTheme.primary)

            // 산책 중일 때 다른 탭에서 보이는 배너
            if walkViewModel.isTracking && selectedTab != 1 {
                WalkingStatusBanner(
                    dogName: walkViewModel.selectedDogName,
                    duration: walkViewModel.currentStats.durationText,
                    isPaused: walkViewModel.isPaused
                ) {
                    // 배너 탭하면 산책 탭으로 이동
                    withAnimation {
                        selectedTab = 1
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.3), value: walkViewModel.isTracking)
            }
        }
    }
}

// MARK: - 산책 중 상태 배너
struct WalkingStatusBanner: View {
    let dogName: String?
    let duration: String
    let isPaused: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // 아이콘
                ZStack {
                    Circle()
                        .fill(isPaused ? AppTheme.warning : AppTheme.success)
                        .frame(width: 36, height: 36)

                    Image(systemName: isPaused ? "pause.fill" : "figure.walk")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }

                // 텍스트 정보
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        if let name = dogName {
                            Text("\(name)")
                                .fontWeight(.bold)
                            Text("산책 중")
                        } else {
                            Text("산책 중")
                                .fontWeight(.bold)
                        }

                        if isPaused {
                            Text("(일시정지)")
                                .foregroundColor(AppTheme.warning)
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)

                    Text(duration)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.9))
                }

                Spacer()

                // 화살표
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: isPaused
                        ? [AppTheme.warning, AppTheme.warning.opacity(0.8)]
                        : [AppTheme.primary, AppTheme.primaryDark],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    MainTabView()
}
