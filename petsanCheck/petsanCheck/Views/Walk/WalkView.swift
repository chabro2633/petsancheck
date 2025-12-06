//
//  WalkView.swift
//  petsanCheck
//
//  Created on 2025-11-29.
//

import SwiftUI
import CoreLocation

/// 산책 화면
struct WalkView: View {
    @ObservedObject private var viewModel = WalkViewModel.shared
    @StateObject private var profileViewModel = ProfileViewModel()
    @State private var centerCoordinate = CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)
    @State private var showDogSelection = false
    @State private var isMapReady = false

    var body: some View {
        NavigationStack {
            ZStack {
                // 카카오맵 - 위치가 준비되면 표시
                if isMapReady {
                    WalkMapView(
                        centerCoordinate: $centerCoordinate,
                        routeCoordinates: viewModel.routeLocations.map {
                            CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
                        }
                    )
                    .ignoresSafeArea()
                } else {
                    // 위치 로딩 중
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("현재 위치를 찾는 중...")
                            .font(.subheadline)
                            .foregroundColor(.black.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppTheme.background)
                }

                VStack {
                    // 상단 컴팩트 정보 영역
                    VStack(spacing: 0) {
                        // 선택된 반려견 정보
                        if viewModel.isTracking, let dogName = viewModel.selectedDogName {
                            DogInfoBannerSimple(dogName: dogName, isPaused: viewModel.isPaused)
                        }

                        // 통계 카드 (컴팩트 버전)
                        if viewModel.isTracking {
                            CompactWalkStatsCard(stats: viewModel.currentStats)
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                        }
                    }
                    .background(AppTheme.cardBackground.opacity(0.95))
                    .cornerRadius(16, corners: [.bottomLeft, .bottomRight])
                    .shadow(color: AppTheme.shadow, radius: 5, x: 0, y: 2)

                    Spacer()

                    // 내 위치 찾기 버튼
                    HStack {
                        Spacer()
                        Button(action: {
                            // 현재 위치가 있으면 바로 이동
                            if let coordinate = viewModel.currentLocation?.coordinate {
                                withAnimation {
                                    centerCoordinate = coordinate
                                }
                            } else {
                                // 위치가 없으면 업데이트 요청
                                Task {
                                    await viewModel.requestLocationUpdate()
                                }
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.primary)
                                    .frame(width: 44, height: 44)
                                    .shadow(color: AppTheme.shadow, radius: 4)

                                if viewModel.isLocating {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "location.fill")
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .padding(.trailing)
                    }
                    .padding(.bottom, 8)

                    // 컨트롤 버튼
                    WalkControlButtons(
                        isTracking: viewModel.isTracking,
                        isPaused: viewModel.isPaused,
                        onStart: {
                            if profileViewModel.dogs.isEmpty {
                                // 반려견이 없으면 바로 시작
                                viewModel.startWalk()
                            } else {
                                // 반려견 선택 시트 표시
                                showDogSelection = true
                            }
                        },
                        onPause: {
                            viewModel.pauseWalk()
                        },
                        onResume: {
                            viewModel.resumeWalk()
                        },
                        onStop: {
                            viewModel.stopWalk()
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
                    showDogSelection = false
                    viewModel.startWalk(dog: dog)
                }
            }
            .onChange(of: viewModel.currentLocation) { oldValue, newValue in
                if let location = newValue {
                    centerCoordinate = location.coordinate
                    // 위치를 받으면 지도 표시
                    if !isMapReady {
                        isMapReady = true
                    }
                }
            }
            .onAppear {
                print("[WalkView] onAppear - 현재 위치: \(viewModel.currentLocation?.coordinate.latitude ?? 0), \(viewModel.currentLocation?.coordinate.longitude ?? 0)")

                // 이미 위치가 있으면 바로 지도 표시
                if let location = viewModel.currentLocation {
                    centerCoordinate = location.coordinate
                    isMapReady = true
                    print("[WalkView] 이미 위치 있음 - 바로 지도 표시")
                }

                // 뷰가 나타날 때 위치 업데이트 시작
                Task {
                    await viewModel.requestLocationUpdate()

                    // 위치가 업데이트되면 지도 중심 설정
                    if let location = viewModel.currentLocation {
                        centerCoordinate = location.coordinate
                        if !isMapReady {
                            isMapReady = true
                        }
                        print("[WalkView] 위치 업데이트 완료")
                    }
                }

                // 3초 후에도 위치를 못 찾으면 기본 위치로 지도 표시
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    if !isMapReady {
                        isMapReady = true
                        print("[WalkView] 3초 타임아웃 - 기본 위치로 지도 표시")
                    }
                }
            }
            .fullScreenCover(isPresented: $viewModel.showCompletionPopup) {
                if let stats = viewModel.completedWalkStats {
                    WalkCompletionView(
                        stats: stats,
                        dogName: viewModel.completedDogName,
                        onDismiss: {
                            viewModel.dismissCompletionPopup()
                        }
                    )
                    .background(ClearBackgroundView())
                }
            }
        }
    }
}

// MARK: - 투명 배경을 위한 UIViewRepresentable
struct ClearBackgroundView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .clear
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

// MARK: - 반려견 정보 배너 (간단 버전)
struct DogInfoBannerSimple: View {
    let dogName: String
    let isPaused: Bool

    var body: some View {
        HStack {
            Image(systemName: "pawprint.fill")
                .foregroundColor(isPaused ? AppTheme.warning : AppTheme.primary)
            Text(isPaused ? "\(dogName)와 산책 일시정지" : "\(dogName)와 산책 중")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(AppTheme.cardBackground)
        .cornerRadius(20)
        .shadow(color: AppTheme.shadow, radius: 5, x: 0, y: 2)
    }
}

// MARK: - 반려견 선택 시트
struct DogSelectionView: View {
    let dogs: [Dog]
    let onSelect: (Dog?) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 반려견 없이 산책 버튼
                Button(action: {
                    onSelect(nil)
                }) {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(AppTheme.primary.opacity(0.15))
                                .frame(width: 50, height: 50)
                            Image(systemName: "figure.walk")
                                .font(.title2)
                                .foregroundColor(AppTheme.primary)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("반려견 없이 산책")
                                .font(.headline)
                                .foregroundColor(.black)
                            Text("혼자 산책하기")
                                .font(.caption)
                                .foregroundColor(.black.opacity(0.5))
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(.black.opacity(0.3))
                    }
                    .padding()
                    .background(AppTheme.cardBackground)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.top)

                // 반려견 목록 헤더
                HStack {
                    Text("반려견 선택")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.black.opacity(0.6))
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 20)
                .padding(.bottom, 8)

                // 반려견 목록
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(dogs) { dog in
                            Button(action: {
                                onSelect(dog)
                            }) {
                                HStack {
                                    ZStack {
                                        Circle()
                                            .fill(AppTheme.primary.opacity(0.15))
                                            .frame(width: 50, height: 50)
                                        Image(systemName: "pawprint.fill")
                                            .font(.title3)
                                            .foregroundColor(AppTheme.primary)
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(dog.name)
                                            .font(.headline)
                                            .foregroundColor(.black)
                                        Text(dog.breed)
                                            .font(.caption)
                                            .foregroundColor(.black.opacity(0.5))
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.black.opacity(0.3))
                                }
                                .padding()
                                .background(AppTheme.cardBackground)
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                Spacer()
            }
            .background(AppTheme.background)
            .navigationTitle("산책할 반려견 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.primary)
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
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
        .shadow(color: AppTheme.shadow, radius: 10, x: 0, y: 4)
    }
}

// MARK: - 컴팩트 통계 카드
struct CompactWalkStatsCard: View {
    let stats: WalkStats

    var body: some View {
        HStack(spacing: 12) {
            CompactStatItem(icon: "map.fill", value: stats.distanceText)
            Divider().frame(height: 20)
            CompactStatItem(icon: "clock.fill", value: stats.durationText)
            Divider().frame(height: 20)
            CompactStatItem(icon: "speedometer", value: stats.speedText)
            Divider().frame(height: 20)
            CompactStatItem(icon: "flame.fill", value: stats.caloriesText)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

struct CompactStatItem: View {
    let icon: String
    let value: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(AppTheme.primary)
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.textPrimary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct StatItem: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(AppTheme.primary)
                .font(.caption)
            Text(label)
                .font(.caption2)
                .foregroundColor(AppTheme.textSecondary)
            Text(value)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.textPrimary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 컨트롤 버튼
struct WalkControlButtons: View {
    let isTracking: Bool
    let isPaused: Bool
    let onStart: () -> Void
    let onPause: () -> Void
    let onResume: () -> Void
    let onStop: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            if isTracking {
                // 일시정지/재개 버튼
                Button(action: {
                    if isPaused {
                        onResume()
                    } else {
                        onPause()
                    }
                }) {
                    HStack {
                        Image(systemName: isPaused ? "play.fill" : "pause.fill")
                        Text(isPaused ? "재개" : "일시정지")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isPaused ? AppTheme.success : AppTheme.warning)
                    .cornerRadius(12)
                }

                // 종료 버튼
                Button(action: onStop) {
                    HStack {
                        Image(systemName: "stop.fill")
                        Text("종료")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.danger)
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
                    .background(AppTheme.primary)
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
