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
        NavigationStack {
            List {
                // 통계 섹션
                Section {
                    WalkStatisticsCard(viewModel: viewModel)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

                // 산책 기록 목록
                Section("산책 기록") {
                    if viewModel.walkRecords.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "figure.walk.circle")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            Text("산책 기록이 없습니다")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .listRowBackground(Color.clear)
                    } else {
                        ForEach(viewModel.walkRecords) { record in
                            WalkRecordRow(record: record)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        viewModel.deleteRecord(record)
                                    } label: {
                                        Label("삭제", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
            }
            .navigationTitle("산책 기록")
            .refreshable {
                viewModel.loadWalkRecords()
            }
        }
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
                    color: .blue
                )

                StatBox(
                    title: "총 거리",
                    value: String(format: "%.1fkm", viewModel.totalDistance),
                    icon: "map",
                    color: .green
                )
            }

            HStack(spacing: 20) {
                StatBox(
                    title: "총 시간",
                    value: String(format: "%.1fh", viewModel.totalDuration),
                    icon: "clock",
                    color: .orange
                )

                StatBox(
                    title: "평균 거리",
                    value: String(format: "%.2fkm", viewModel.averageDistance),
                    icon: "chart.bar",
                    color: .purple
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

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - 산책 기록 행
struct WalkRecordRow: View {
    let record: WalkSession

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(record.startTime, style: .date)
                    .font(.headline)

                Spacer()

                if record.isActive {
                    Text("진행 중")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(8)
                } else {
                    Text(record.startTime, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
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
            .foregroundColor(.secondary)

            if let notes = record.notes {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
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
