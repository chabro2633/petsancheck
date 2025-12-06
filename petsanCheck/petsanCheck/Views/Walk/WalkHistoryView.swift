//
//  WalkHistoryView.swift
//  petsanCheck
//
//  Created on 2025-11-29.
//

import SwiftUI

/// 산책 기록 조회 화면
struct WalkHistoryView: View {
    @StateObject private var viewModel = WalkHistoryViewModel()

    var body: some View {
        List {
            // 이번 주 헤더
            Section {
                WeeklyHeaderView(viewModel: viewModel)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            // 이번 주 통계 섹션
            Section {
                WeeklyStatisticsCard(viewModel: viewModel)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            // 요일별 산책 기록
            Section {
                WeeklyCalendarView(viewModel: viewModel)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            // 이번 주 산책 기록 목록
            Section {
                if viewModel.weeklyRecords.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "figure.walk.circle")
                            .font(.system(size: 50))
                            .foregroundColor(.black.opacity(0.4))
                        Text("이번 주 산책 기록이 없습니다")
                            .font(.headline)
                            .foregroundColor(.black.opacity(0.6))
                        Text("산책을 시작해보세요!")
                            .font(.subheadline)
                            .foregroundColor(.black.opacity(0.4))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .listRowBackground(AppTheme.cardBackground)
                } else {
                    ForEach(viewModel.weeklyRecords) { record in
                        NavigationLink(destination: WalkRecordDetailView(record: record)) {
                            WalkRecordRow(record: record)
                        }
                        .listRowBackground(AppTheme.cardBackground)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                viewModel.deleteRecord(record)
                            } label: {
                                Label("삭제", systemImage: "trash")
                            }
                        }
                    }
                }
            } header: {
                Text("이번 주 산책 기록")
                    .foregroundColor(.black)
                    .font(.headline)
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.background)
        .navigationTitle("산책 기록")
        .toolbarBackground(AppTheme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .refreshable {
            viewModel.loadWalkRecords()
        }
    }
}

// MARK: - 이번 주 헤더
struct WeeklyHeaderView: View {
    @ObservedObject var viewModel: WalkHistoryViewModel

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("이번 주")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.black)

                Text(viewModel.weekRangeText)
                    .font(.subheadline)
                    .foregroundColor(.black.opacity(0.7))
            }

            Spacer()

            Image(systemName: "calendar")
                .font(.title2)
                .foregroundColor(AppTheme.primary)
        }
        .padding()
    }
}

// MARK: - 이번 주 통계 카드
struct WeeklyStatisticsCard: View {
    @ObservedObject var viewModel: WalkHistoryViewModel

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                StatBox(
                    title: "이번 주 산책",
                    value: "\(viewModel.weeklyWalkCount)회",
                    icon: "figure.walk",
                    color: AppTheme.primary
                )

                StatBox(
                    title: "이번 주 거리",
                    value: String(format: "%.1fkm", viewModel.weeklyDistance),
                    icon: "map",
                    color: AppTheme.success
                )
            }

            HStack(spacing: 20) {
                StatBox(
                    title: "이번 주 시간",
                    value: formatDuration(viewModel.weeklyDuration),
                    icon: "clock",
                    color: AppTheme.warning
                )

                StatBox(
                    title: "평균 거리",
                    value: String(format: "%.2fkm", viewModel.weeklyAverageDistance),
                    icon: "chart.bar",
                    color: AppTheme.secondary
                )
            }
        }
        .padding()
    }

    private func formatDuration(_ hours: Double) -> String {
        if hours < 1 {
            return String(format: "%.0f분", hours * 60)
        } else {
            return String(format: "%.1f시간", hours)
        }
    }
}

// MARK: - 요일별 캘린더 뷰
struct WeeklyCalendarView: View {
    @ObservedObject var viewModel: WalkHistoryViewModel

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                ForEach(1...7, id: \.self) { day in
                    DayCell(
                        dayName: viewModel.dayName(for: day),
                        date: viewModel.dateFor(day: day),
                        walkCount: viewModel.dailyRecords[day]?.count ?? 0,
                        distance: viewModel.distanceFor(day: day),
                        isToday: viewModel.isToday(day: day),
                        isFuture: viewModel.isFuture(day: day)
                    )
                }
            }
        }
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
        .shadow(color: AppTheme.shadow, radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
}

// MARK: - 요일 셀
struct DayCell: View {
    let dayName: String
    let date: Date?
    let walkCount: Int
    let distance: Double
    let isToday: Bool
    let isFuture: Bool

    private var dayNumber: String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(spacing: 6) {
            // 요일
            Text(dayName)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(isToday ? AppTheme.primary : .black.opacity(0.6))

            // 날짜
            ZStack {
                if isToday {
                    Circle()
                        .fill(AppTheme.primary)
                        .frame(width: 28, height: 28)
                }

                Text(dayNumber)
                    .font(.caption)
                    .fontWeight(isToday ? .bold : .regular)
                    .foregroundColor(isToday ? .white : (isFuture ? .black.opacity(0.3) : .black))
            }

            // 산책 표시
            if walkCount > 0 {
                VStack(spacing: 2) {
                    // 산책 횟수 표시 (점)
                    HStack(spacing: 2) {
                        ForEach(0..<min(walkCount, 3), id: \.self) { _ in
                            Circle()
                                .fill(AppTheme.success)
                                .frame(width: 4, height: 4)
                        }
                        if walkCount > 3 {
                            Text("+")
                                .font(.system(size: 6))
                                .foregroundColor(AppTheme.success)
                        }
                    }

                    // 거리
                    Text(String(format: "%.1f", distance))
                        .font(.system(size: 8))
                        .foregroundColor(.black.opacity(0.6))
                }
            } else if !isFuture {
                Text("-")
                    .font(.caption2)
                    .foregroundColor(.black.opacity(0.2))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isToday ? AppTheme.primary.opacity(0.1) : Color.clear)
        )
    }
}

// MARK: - 통계 카드
struct WalkStatisticsCard: View {
    @ObservedObject var viewModel: WalkHistoryViewModel

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                StatBox(
                    title: "총 산책",
                    value: "\(viewModel.totalWalkCount)회",
                    icon: "figure.walk",
                    color: AppTheme.primary
                )

                StatBox(
                    title: "총 거리",
                    value: String(format: "%.1fkm", viewModel.totalDistance),
                    icon: "map",
                    color: AppTheme.success
                )
            }

            HStack(spacing: 20) {
                StatBox(
                    title: "총 시간",
                    value: String(format: "%.1fh", viewModel.totalDuration),
                    icon: "clock",
                    color: AppTheme.warning
                )

                StatBox(
                    title: "평균 거리",
                    value: String(format: "%.2fkm", viewModel.averageDistance),
                    icon: "chart.bar",
                    color: AppTheme.secondary
                )
            }
        }
        .padding()
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.black)

            Text(title)
                .font(.caption)
                .foregroundColor(.black.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(12)
        .shadow(color: AppTheme.shadow, radius: 5, x: 0, y: 2)
    }
}

// MARK: - 산책 기록 행
struct WalkRecordRow: View {
    let record: WalkSession

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // 날짜 (YYYY-MM-DD 형식)
                Text(record.dateString)
                    .font(.headline)
                    .foregroundColor(.black)

                Spacer()

                if record.isActive {
                    Text("진행 중")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.success.opacity(0.2))
                        .foregroundColor(AppTheme.success)
                        .cornerRadius(8)
                } else {
                    Text(record.timeString)
                        .font(.caption)
                        .foregroundColor(.black.opacity(0.6))
                }
            }

            // 위치 정보 (있을 경우)
            if let locationName = record.locationName, !locationName.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.caption2)
                    Text(locationName)
                }
                .font(.caption)
                .foregroundColor(AppTheme.primary)
            } else if let weatherLocation = record.weatherAtStart?.locationName, !weatherLocation.isEmpty {
                // 날씨 정보에 저장된 위치명 사용
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.caption2)
                    Text(weatherLocation)
                }
                .font(.caption)
                .foregroundColor(AppTheme.primary)
            }

            HStack(spacing: 16) {
                Label(
                    String(format: "%.2fkm", record.totalDistance / 1000),
                    systemImage: "map.fill"
                )

                Label(
                    formatDuration(record.duration),
                    systemImage: "clock.fill"
                )

                Label(
                    String(format: "%.1f km/h", record.averageSpeed),
                    systemImage: "speedometer"
                )
            }
            .font(.caption)
            .foregroundColor(.black.opacity(0.6))

            if let notes = record.notes {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.black.opacity(0.6))
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60

        if hours > 0 {
            return "\(hours)시간 \(minutes)분"
        } else {
            return "\(minutes)분"
        }
    }
}

#Preview {
    WalkHistoryView()
}
