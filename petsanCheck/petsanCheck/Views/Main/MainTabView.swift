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

    var body: some View {
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
    }
}

#Preview {
    MainTabView()
}
