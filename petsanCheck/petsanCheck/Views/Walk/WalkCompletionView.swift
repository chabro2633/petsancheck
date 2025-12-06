//
//  WalkCompletionView.swift
//  petsanCheck
//
//  Created on 2025-12-06.
//

import SwiftUI

/// 산책 완료 축하 팝업
struct WalkCompletionView: View {
    let stats: WalkStats
    let dogName: String?
    let onDismiss: () -> Void

    @State private var showContent = false
    @State private var showPaw1 = false
    @State private var showPaw2 = false
    @State private var showPaw3 = false
    @State private var bounceIcon = false
    @State private var showStats = false
    @State private var showButton = false

    var body: some View {
        ZStack {
            // 배경
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissWithAnimation()
                }

            // 메인 카드
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 24) {
                    // 발바닥 애니메이션
                    HStack(spacing: 16) {
                        PawPrint()
                            .opacity(showPaw1 ? 1 : 0)
                            .scaleEffect(showPaw1 ? 1 : 0.3)
                            .rotationEffect(.degrees(-15))

                        PawPrint()
                            .opacity(showPaw2 ? 1 : 0)
                            .scaleEffect(showPaw2 ? 1 : 0.3)
                            .offset(y: -10)

                        PawPrint()
                            .opacity(showPaw3 ? 1 : 0)
                            .scaleEffect(showPaw3 ? 1 : 0.3)
                            .rotationEffect(.degrees(15))
                    }
                    .padding(.top, 20)

                    // 메인 아이콘
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [AppTheme.primary, AppTheme.primaryDark],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .shadow(color: AppTheme.primary.opacity(0.4), radius: 20)

                        Image(systemName: dogName != nil ? "heart.fill" : "checkmark")
                            .font(.system(size: 44, weight: .bold))
                            .foregroundColor(.white)
                            .scaleEffect(bounceIcon ? 1.1 : 1.0)
                    }
                    .opacity(showContent ? 1 : 0)
                    .scaleEffect(showContent ? 1 : 0.5)

                    // 메시지
                    VStack(spacing: 8) {
                        if let name = dogName {
                            // 반려견과 함께 산책한 경우
                            Text("오늘도 산책시켜줘서 고마워요!")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(AppTheme.textPrimary)
                                .multilineTextAlignment(.center)

                            Text("- \(name) 올림 🐾")
                                .font(.headline)
                                .foregroundColor(AppTheme.primary)

                            Text("덕분에 오늘도 행복했어요")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.textSecondary)
                                .padding(.top, 4)
                        } else {
                            // 혼자 산책한 경우
                            Text("산책 완료!")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(AppTheme.textPrimary)

                            Text("오늘도 수고하셨어요")
                                .font(.headline)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)

                    // 통계
                    HStack(spacing: 24) {
                        CompletionStatItem(
                            icon: "map.fill",
                            value: stats.distanceText,
                            label: "거리"
                        )

                        CompletionStatItem(
                            icon: "clock.fill",
                            value: stats.durationText,
                            label: "시간"
                        )

                        CompletionStatItem(
                            icon: "flame.fill",
                            value: stats.caloriesText,
                            label: "칼로리"
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(AppTheme.background)
                    .cornerRadius(16)
                    .opacity(showStats ? 1 : 0)
                    .scaleEffect(showStats ? 1 : 0.9)

                    // 확인 버튼
                    Button(action: {
                        dismissWithAnimation()
                    }) {
                        Text("확인")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [AppTheme.primary, AppTheme.primaryDark],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                    }
                    .opacity(showButton ? 1 : 0)
                    .offset(y: showButton ? 0 : 20)
                    .padding(.top, 8)
                }
                .padding(24)
                .background(AppTheme.cardBackground)
                .cornerRadius(24)
                .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
                .padding(.horizontal, 24)

                Spacer()
            }
        }
        .onAppear {
            startAnimations()
        }
    }

    private func startAnimations() {
        // 순차적 애니메이션
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
            showPaw1 = true
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2)) {
            showPaw2 = true
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3)) {
            showPaw3 = true
        }

        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.4)) {
            showContent = true
        }

        // 아이콘 바운스
        withAnimation(.easeInOut(duration: 0.3).delay(0.7)) {
            bounceIcon = true
        }
        withAnimation(.easeInOut(duration: 0.3).delay(1.0)) {
            bounceIcon = false
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.6)) {
            showStats = true
        }

        withAnimation(.easeOut(duration: 0.4).delay(0.8)) {
            showButton = true
        }
    }

    private func dismissWithAnimation() {
        withAnimation(.easeIn(duration: 0.2)) {
            showButton = false
            showStats = false
            showContent = false
            showPaw1 = false
            showPaw2 = false
            showPaw3 = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            onDismiss()
        }
    }
}

// MARK: - 발바닥 아이콘
struct PawPrint: View {
    var body: some View {
        Image(systemName: "pawprint.fill")
            .font(.system(size: 28))
            .foregroundColor(AppTheme.primary.opacity(0.6))
    }
}

// MARK: - 완료 통계 아이템
struct CompletionStatItem: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(AppTheme.primary)

            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.textPrimary)

            Text(label)
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview
#Preview("With Dog") {
    WalkCompletionView(
        stats: WalkStats(distance: 2500, duration: 1800, averageSpeed: 5.0, calories: 125),
        dogName: "깜지",
        onDismiss: {}
    )
}

#Preview("Without Dog") {
    WalkCompletionView(
        stats: WalkStats(distance: 1200, duration: 900, averageSpeed: 4.8, calories: 60),
        dogName: nil,
        onDismiss: {}
    )
}
