//
//  HomeView.swift
//  petsanCheck
//
//  Created on 2025-11-29.
//

import SwiftUI

/// 홈 화면
struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @Binding var selectedTab: Int

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 날씨 카드
                    WeatherCardView(weather: viewModel.weatherInfo)

                    // 로딩 인디케이터
                    if viewModel.isLoadingWeather {
                        ProgressView("날씨 정보 로딩 중...")
                            .padding()
                            .foregroundColor(AppTheme.textSecondary)
                    }

                    // 에러 메시지
                    if let error = viewModel.weatherError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(AppTheme.danger)
                            .padding()
                            .background(AppTheme.danger.opacity(0.1))
                            .cornerRadius(8)
                    }

                    // 산책 추천 카드
                    if let recommendation = viewModel.walkRecommendation {
                        WalkRecommendationCardView(recommendation: recommendation)
                    }
                }
                .padding()
            }
            .background(AppTheme.background)
            .navigationTitle("펫산책")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: ProfileView()) {
                        Image(systemName: "person.circle.fill")
                            .font(.title2)
                            .foregroundColor(AppTheme.primary)
                    }
                }
            }
            .onAppear {
                viewModel.loadCurrentLocationWeather()
            }
            .refreshable {
                viewModel.loadCurrentLocationWeather()
            }
        }
    }
}

// MARK: - 날씨 카드 뷰
struct WeatherCardView: View {
    let weather: WeatherInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 위치 정보
            HStack(spacing: 6) {
                Image(systemName: "location.fill")
                    .font(.caption)
                    .foregroundColor(AppTheme.primary)
                Text(weather.locationName ?? "위치 확인 중...")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                Text(formattedTime)
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }

            // 메인 날씨 정보
            HStack(alignment: .center) {
                // 날씨 아이콘과 상태
                VStack(alignment: .leading, spacing: 4) {
                    Image(systemName: weather.weatherCondition.icon)
                        .font(.system(size: 50))
                        .foregroundColor(iconColor)
                    Text(weather.weatherCondition.rawValue)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                }

                Spacer()

                // 온도 표시
                VStack(alignment: .trailing, spacing: 0) {
                    Text("\(Int(round(weather.temperature)))°")
                        .font(.system(size: 64, weight: .thin))
                        .foregroundColor(AppTheme.textPrimary)
                    Text(weather.temperatureCategory.description)
                        .font(.caption)
                        .foregroundColor(temperatureColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(temperatureColor.opacity(0.15))
                        .cornerRadius(8)
                }
            }

            Divider()

            // 상세 날씨 정보
            HStack(spacing: 0) {
                WeatherDetailItem(icon: "humidity.fill", value: "\(weather.humidity)%", label: "습도")
                WeatherDetailItem(icon: "wind", value: "\(String(format: "%.1f", weather.windSpeed))m/s", label: "풍속")
                WeatherDetailItem(icon: "sun.max.fill", value: "\(weather.uvIndex)", label: "자외선")
                WeatherDetailItem(icon: "aqi.medium", value: airQualityText, label: "대기질")
            }
        }
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
        .shadow(color: AppTheme.shadow, radius: 10, x: 0, y: 4)
    }

    // 현재 시간 포맷
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "a h:mm 업데이트"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: weather.timestamp)
    }

    // 날씨 아이콘 색상
    private var iconColor: Color {
        switch weather.weatherCondition {
        case .sunny: return Color.orange
        case .cloudy: return AppTheme.textSecondary
        case .rainy: return AppTheme.primary
        case .snowy: return AppTheme.primary.opacity(0.7)
        case .foggy: return AppTheme.textSecondary
        }
    }

    // 온도 카테고리 색상
    private var temperatureColor: Color {
        switch weather.temperatureCategory {
        case .cold: return Color.blue
        case .cool: return AppTheme.primary
        case .moderate: return AppTheme.success
        case .warm: return Color.orange
        case .hot: return AppTheme.danger
        }
    }

    // 대기질 텍스트
    private var airQualityText: String {
        switch weather.airQuality {
        case 0..<50: return "좋음"
        case 50..<100: return "보통"
        case 100..<150: return "나쁨"
        default: return "매우나쁨"
        }
    }
}

struct WeatherDetailItem: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(AppTheme.primary)
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.textPrimary)
            Text(label)
                .font(.caption2)
                .foregroundColor(AppTheme.textSecondary)
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
                    .foregroundColor(AppTheme.textPrimary)

                Spacer()

                Text("\(recommendation.score)점")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(colorForLevel(recommendation.level))
            }

            Text(recommendation.message)
                .font(.body)
                .foregroundColor(AppTheme.textPrimary)

            if !recommendation.warnings.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(recommendation.warnings, id: \.message) { warning in
                        HStack {
                            Image(systemName: warning.type.icon)
                                .foregroundColor(AppTheme.warning)
                            Text(warning.message)
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                }
            }

            if !recommendation.bestTimeSlots.isEmpty {
                Divider()
                Text("추천 시간대")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.textPrimary)

                ForEach(recommendation.bestTimeSlots) { slot in
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(AppTheme.primary)
                        Text(slot.displayTimeRange)
                            .font(.caption)
                            .foregroundColor(AppTheme.textPrimary)
                        Spacer()
                        Text("\(slot.score)점")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
            }
        }
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
        .shadow(color: AppTheme.shadow, radius: 10, x: 0, y: 4)
    }

    private func colorForLevel(_ level: WalkRecommendation.RecommendationLevel) -> Color {
        switch level {
        case .excellent: return AppTheme.success
        case .good: return AppTheme.primary
        case .moderate: return AppTheme.warning
        case .poor: return AppTheme.warning
        case .dangerous: return AppTheme.danger
        }
    }
}


#Preview {
    HomeView(selectedTab: .constant(0))
}
