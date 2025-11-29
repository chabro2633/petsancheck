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
    @StateObject private var profileViewModel = ProfileViewModel()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var showDogSelection = false
    @State private var selectedDog: Dog?

    var body: some View {
        NavigationStack {
            ZStack {
                // 지도
                Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: viewModel.routeLocations) { location in
                    MapMarker(coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude), tint: .blue)
                }
                .ignoresSafeArea()

                VStack {
                    // 선택된 반려견 정보
                    if viewModel.isTracking, let dog = selectedDog {
                        DogInfoBanner(dog: dog)
                            .padding(.top)
                    }

                    Spacer()

                    // 통계 카드
                    if viewModel.isTracking {
                        WalkStatsCard(stats: viewModel.currentStats)
                            .padding()
                    }

                    // 컨트롤 버튼
                    WalkControlButtons(
                        isTracking: viewModel.isTracking,
                        selectedDog: selectedDog,
                        onStart: {
                            if profileViewModel.dogs.isEmpty {
                                // 반려견이 없으면 바로 시작
                                viewModel.startWalk()
                            } else {
                                // 반려견 선택 시트 표시
                                showDogSelection = true
                            }
                        },
                        onStop: {
                            viewModel.stopWalk(dogId: selectedDog?.id)
                            selectedDog = nil
                        }
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
            .sheet(isPresented: $showDogSelection) {
                DogSelectionView(dogs: profileViewModel.dogs) { dog in
                    selectedDog = dog
                    showDogSelection = false
                    viewModel.startWalk()
                }
            }
            .onChange(of: viewModel.currentLocation) { oldValue, newValue in
                if let location = newValue {
                    region.center = location.coordinate
                }
            }
        }
    }
}

// MARK: - 반려견 정보 배너
struct DogInfoBanner: View {
    let dog: Dog

    var body: some View {
        HStack {
            Image(systemName: "pawprint.fill")
                .foregroundColor(.blue)
            Text("\(dog.name)와 산책 중")
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - 반려견 선택 시트
struct DogSelectionView: View {
    let dogs: [Dog]
    let onSelect: (Dog?) -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button(action: {
                        onSelect(nil)
                    }) {
                        HStack {
                            Image(systemName: "figure.walk")
                                .foregroundColor(.gray)
                            Text("반려견 없이 산책")
                                .foregroundColor(.primary)
                        }
                    }
                }

                Section("반려견 선택") {
                    ForEach(dogs) { dog in
                        Button(action: {
                            onSelect(dog)
                        }) {
                            HStack {
                                Image(systemName: "pawprint.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.title2)

                                VStack(alignment: .leading) {
                                    Text(dog.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text(dog.breed)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
            .navigationTitle("산책할 반려견 선택")
            .navigationBarTitleDisplayMode(.inline)
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
    let selectedDog: Dog?
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
