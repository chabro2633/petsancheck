//
//  WalkView.swift
//  petsanCheck
//
//  Created on 2025-11-29.
//

import SwiftUI
import MapKit

/// 산책 화면
struct WalkView: View {
    @StateObject private var viewModel = WalkViewModel()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )

    var body: some View {
        NavigationStack {
            ZStack {
                // 지도
                Map(coordinateRegion: $region, showsUserLocation: true)
                    .ignoresSafeArea()

                VStack {
                    Spacer()

                    // 통계 카드
                    if viewModel.isTracking {
                        WalkStatsCard(stats: viewModel.currentStats)
                            .padding()
                    }

                    // 컨트롤 버튼
                    WalkControlButtons(
                        isTracking: viewModel.isTracking,
                        onStart: { viewModel.startWalk() },
                        onStop: { viewModel.stopWalk() }
                    )
                    .padding()
                }
            }
            .navigationTitle("산책")
            .navigationBarTitleDisplayMode(.inline)
            .alert("위치 권한 필요", isPresented: $viewModel.showPermissionAlert) {
                Button("설정으로 이동") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("취소", role: .cancel) { }
            } message: {
                Text("산책 경로를 추적하려면 위치 권한이 필요합니다. 설정에서 위치 권한을 허용해주세요.")
            }
            .onChange(of: viewModel.currentLocation) { oldValue, newValue in
                if let location = newValue {
                    region.center = location.coordinate
                }
            }
        }
    }
}

// MARK: - 통계 카드
struct WalkStatsCard: View {
    let stats: WalkStats

    var body: some View {
        HStack(spacing: 20) {
            StatItem(icon: "figure.walk", label: "거리", value: stats.distanceText)
            Divider()
            StatItem(icon: "clock.fill", label: "시간", value: stats.durationText)
            Divider()
            StatItem(icon: "speedometer", label: "속도", value: stats.speedText)
            Divider()
            StatItem(icon: "flame.fill", label: "칼로리", value: stats.caloriesText)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
    }
}

struct StatItem: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.caption)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 컨트롤 버튼
struct WalkControlButtons: View {
    let isTracking: Bool
    let onStart: () -> Void
    let onStop: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            if isTracking {
                // 종료 버튼
                Button(action: onStop) {
                    HStack {
                        Image(systemName: "stop.fill")
                        Text("산책 종료")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(12)
                }
            } else {
                // 시작 버튼
                Button(action: onStart) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("산책 시작")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    WalkView()
}
