//
//  HomeView.swift
//  petsanCheck
//
//  Created on 2025-11-29.
//

import SwiftUI

/// 홈 화면
struct HomeView: View {
    @State private var weatherInfo: WeatherInfo = .preview
    @State private var walkRecommendation: WalkRecommendation?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 날씨 카드
                    WeatherCardView(weather: weatherInfo)

                    // 산책 추천 카드
                    if let recommendation = walkRecommendation {
                        WalkRecommendationCardView(recommendation: recommendation)
                    }

                    // 퀵 액션 버튼들
                    QuickActionsView()
                }
                .padding()
            }
            .navigationTitle("펫산책")
            .onAppear {
                evaluateWalkConditions()
            }
        }
    }

    private func evaluateWalkConditions() {
        walkRecommendation = WeatherEvaluator.evaluateWalkConditions(weather: weatherInfo)
    }
}

// MARK: - 날씨 카드 뷰
struct WeatherCardView: View {
    let weather: WeatherInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: weather.weatherCondition.icon)
                    .font(.system(size: 40))
                    .foregroundColor(.blue)

                Spacer()

                VStack(alignment: .trailing) {
                    Text("\(String(format: "%.1f", weather.temperature))°C")
                        .font(.system(size: 36, weight: .bold))
                    Text(weather.weatherCondition.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            HStack(spacing: 20) {
                WeatherDetailItem(icon: "humidity.fill", value: "\(weather.humidity)%", label: "습도")
                WeatherDetailItem(icon: "wind", value: "\(String(format: "%.1f", weather.windSpeed))m/s", label: "풍속")
                WeatherDetailItem(icon: "sun.max.fill", value: "\(weather.uvIndex)", label: "자외선")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
    }
}

struct WeatherDetailItem: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 산책 추천 카드 뷰
struct WalkRecommendationCardView: View {
    let recommendation: WalkRecommendation

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: recommendation.level.icon)
                    .font(.title2)
                    .foregroundColor(colorForLevel(recommendation.level))

                Text("산책 추천")
                    .font(.headline)

                Spacer()

                Text("\(recommendation.score)점")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(colorForLevel(recommendation.level))
            }

            Text(recommendation.message)
                .font(.body)

            if !recommendation.warnings.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(recommendation.warnings, id: \.message) { warning in
                        HStack {
                            Image(systemName: warning.type.icon)
                                .foregroundColor(.orange)
                            Text(warning.message)
                                .font(.caption)
                        }
                    }
                }
            }

            if !recommendation.bestTimeSlots.isEmpty {
                Divider()
                Text("추천 시간대")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                ForEach(recommendation.bestTimeSlots) { slot in
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.blue)
                        Text(slot.displayTimeRange)
                            .font(.caption)
                        Spacer()
                        Text("\(slot.score)점")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
    }

    private func colorForLevel(_ level: WalkRecommendation.RecommendationLevel) -> Color {
        switch level {
        case .excellent: return .green
        case .good: return .blue
        case .moderate: return .yellow
        case .poor: return .orange
        case .dangerous: return .red
        }
    }
}

// MARK: - 퀵 액션 뷰
struct QuickActionsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("퀵 액션")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                QuickActionButton(
                    icon: "figure.walk",
                    title: "산책 시작",
                    color: .blue
                ) {
                    // 산책 시작 액션
                }

                QuickActionButton(
                    icon: "cross.fill",
                    title: "병원 찾기",
                    color: .red
                ) {
                    // 병원 찾기 액션
                }
            }

            HStack(spacing: 12) {
                QuickActionButton(
                    icon: "chart.bar.fill",
                    title: "산책 기록",
                    color: .green
                ) {
                    // 기록 보기 액션
                }

                QuickActionButton(
                    icon: "photo.fill",
                    title: "사진 공유",
                    color: .purple
                ) {
                    // 사진 공유 액션
                }
            }
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .cornerRadius(12)
        }
    }
}

#Preview {
    HomeView()
}
