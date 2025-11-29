//
//  WalkRecordDetailView.swift
//  petsanCheck
//
//  Created on 2025-11-29.
//

import SwiftUI
import CoreLocation

/// 산책 기록 상세 화면
struct WalkRecordDetailView: View {
    let record: WalkSession
    @State private var centerCoordinate: CLLocationCoordinate2D

    // 카카오맵 API 키
    private let kakaoMapAPIKey = "9e8b18c55ec9d4441317124e6ecf84b6"

    init(record: WalkSession) {
        self.record = record

        // 경로의 중심 좌표로 지도 초기화
        if let center = record.centerCoordinate {
            _centerCoordinate = State(initialValue: CLLocationCoordinate2D(
                latitude: center.latitude,
                longitude: center.longitude
            ))
        } else {
            _centerCoordinate = State(initialValue: CLLocationCoordinate2D(
                latitude: 37.5665,
                longitude: 126.9780
            ))
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 카카오맵
                WalkMapView(
                    apiKey: kakaoMapAPIKey,
                    centerCoordinate: $centerCoordinate,
                    routeCoordinates: record.locations.map {
                        CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
                    }
                )
                .frame(height: 300)
                .cornerRadius(12)

                // 통계 정보
                VStack(spacing: 16) {
                    HStack(spacing: 20) {
                        DetailStatBox(
                            icon: "map.fill",
                            label: "거리",
                            value: String(format: "%.2fkm", record.totalDistance / 1000),
                            color: .blue
                        )

                        DetailStatBox(
                            icon: "clock.fill",
                            label: "시간",
                            value: formatDuration(record.duration),
                            color: .green
                        )
                    }

                    HStack(spacing: 20) {
                        DetailStatBox(
                            icon: "speedometer",
                            label: "평균 속도",
                            value: String(format: "%.1f km/h", record.averageSpeed),
                            color: .orange
                        )

                        DetailStatBox(
                            icon: "flame.fill",
                            label: "칼로리",
                            value: "\(record.estimatedCalories) kcal",
                            color: .red
                        )
                    }

                    HStack(spacing: 20) {
                        DetailStatBox(
                            icon: "figure.walk",
                            label: "평균 페이스",
                            value: String(format: "%.1f 분/km", record.averagePace),
                            color: .purple
                        )

                        DetailStatBox(
                            icon: "location.fill",
                            label: "경로 포인트",
                            value: "\(record.locations.count)",
                            color: .teal
                        )
                    }
                }

                // 날씨 정보
                if let weather = record.weatherAtStart {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("산책 시작 시 날씨")
                            .font(.headline)

                        HStack {
                            Image(systemName: weather.weatherCondition.icon)
                                .font(.title)
                                .foregroundColor(.blue)

                            VStack(alignment: .leading) {
                                Text(weather.weatherCondition.rawValue)
                                    .font(.subheadline)
                                Text("\(String(format: "%.1f", weather.temperature))°C")
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text("습도: \(weather.humidity)%")
                                    .font(.caption)
                                Text("풍속: \(String(format: "%.1f", weather.windSpeed))m/s")
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                }

                // 메모
                if let notes = record.notes {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("메모")
                            .font(.headline)

                        Text(notes)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                    }
                }

                // 시간 정보
                VStack(alignment: .leading, spacing: 8) {
                    Text("시간 정보")
                        .font(.headline)

                    VStack(spacing: 4) {
                        HStack {
                            Text("시작")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(record.startTime, style: .date)
                            Text(record.startTime, style: .time)
                        }

                        if let endTime = record.endTime {
                            HStack {
                                Text("종료")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(endTime, style: .date)
                                Text(endTime, style: .time)
                            }
                        }
                    }
                    .font(.body)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }
            }
            .padding()
        }
        .navigationTitle("산책 기록 상세")
        .navigationBarTitleDisplayMode(.inline)
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

// MARK: - 상세 통계 박스
struct DetailStatBox: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.headline)
                .fontWeight(.bold)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    NavigationStack {
        WalkRecordDetailView(record: .preview)
    }
}
