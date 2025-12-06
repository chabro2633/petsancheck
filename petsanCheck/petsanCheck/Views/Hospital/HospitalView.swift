//
//  HospitalView.swift
//  petsanCheck
//
//  Created on 2025-11-29.
//

import SwiftUI
import CoreLocation

/// 병원 검색 화면
struct HospitalView: View {
    @StateObject private var viewModel = HospitalViewModel()
    @State private var centerCoordinate = CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)
    @State private var showingSearchOptions = false
    @State private var hasSetInitialLocation = false

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    // 카카오맵
                    KakaoMapView(
                        centerCoordinate: $centerCoordinate,
                        hospitals: viewModel.hospitals,
                        onMarkerTap: { hospital in
                            viewModel.selectedHospital = hospital
                            centerCoordinate = hospital.coordinate
                        },
                        currentLocation: viewModel.currentCoordinate
                    )
                    .frame(height: 250)
                    .overlay(alignment: .topTrailing) {
                        VStack(spacing: 12) {
                            // 내 위치로 이동 버튼
                            Button(action: {
                                if let coordinate = viewModel.currentCoordinate {
                                    withAnimation {
                                        centerCoordinate = coordinate
                                    }
                                }
                            }) {
                                Image(systemName: "location.fill")
                                    .padding(12)
                                    .background(AppTheme.primary)
                                    .foregroundColor(.white)
                                    .clipShape(Circle())
                                    .shadow(color: AppTheme.shadow, radius: 4)
                            }

                            // 근처 병원 검색 버튼
                            Button(action: {
                                Task {
                                    await viewModel.searchNearbyHospitals()
                                }
                            }) {
                                Image(systemName: "magnifyingglass")
                                    .padding(12)
                                    .background(AppTheme.cardBackground)
                                    .foregroundColor(AppTheme.primary)
                                    .clipShape(Circle())
                                    .shadow(color: AppTheme.shadow, radius: 4)
                            }
                        }
                        .padding()
                    }

                    // 병원 목록
                    if viewModel.isLoading {
                        ProgressView("검색 중...")
                            .padding()
                            .foregroundColor(.black.opacity(0.6))
                    } else if let error = viewModel.errorMessage {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundColor(AppTheme.warning)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.black.opacity(0.6))
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(AppTheme.background)
                    } else if viewModel.hospitals.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.largeTitle)
                                .foregroundColor(.black.opacity(0.4))
                            Text("검색 결과가 없습니다")
                                .font(.headline)
                                .foregroundColor(.black.opacity(0.6))
                        }
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(AppTheme.background)
                    } else {
                        List {
                            ForEach(viewModel.hospitals) { hospital in
                                HospitalRow(hospital: hospital)
                                    .listRowBackground(AppTheme.cardBackground)
                                    .onTapGesture {
                                        viewModel.selectedHospital = hospital
                                        centerCoordinate = hospital.coordinate
                                    }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .background(AppTheme.background)
                    }
                }

                // 선택된 병원 상세 정보 시트
                if let hospital = viewModel.selectedHospital {
                    VStack {
                        Spacer()
                        HospitalDetailSheet(
                            hospital: hospital,
                            onCall: { viewModel.callHospital(hospital) },
                            onDirections: { viewModel.openInMaps(hospital) },
                            onDismiss: { viewModel.selectedHospital = nil }
                        )
                    }
                }
            }
            .navigationTitle("병원")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .searchable(
                text: $viewModel.searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "병원명 또는 지역 검색"
            )
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            viewModel.searchMode = .nearby
                            Task { await viewModel.searchNearbyHospitals() }
                        }) {
                            Label("근처 병원", systemImage: "location.fill")
                        }

                        Button(action: {
                            viewModel.searchMode = .region
                        }) {
                            Label("지역 검색", systemImage: "map")
                        }

                        Button(action: {
                            viewModel.searchMode = .name
                        }) {
                            Label("병원명 검색", systemImage: "magnifyingglass")
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .onAppear {
                viewModel.requestLocation()
            }
            .onChange(of: viewModel.currentCoordinate?.latitude) { _, _ in
                // 처음 위치를 받으면 지도 중심을 현재 위치로 이동
                if !hasSetInitialLocation, let coordinate = viewModel.currentCoordinate {
                    centerCoordinate = coordinate
                    hasSetInitialLocation = true
                }
            }
        }
    }
}

// MARK: - 병원 목록 행
struct HospitalRow: View {
    let hospital: Hospital

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "cross.circle.fill")
                    .foregroundColor(AppTheme.danger)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(hospital.name)
                        .font(.headline)
                        .foregroundColor(.black)

                    if hospital.distance != nil {
                        Text(hospital.distanceText)
                            .font(.caption)
                            .foregroundColor(AppTheme.primary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.black.opacity(0.4))
            }

            Text(hospital.address)
                .font(.caption)
                .foregroundColor(.black.opacity(0.6))

            if let phone = hospital.phone {
                HStack {
                    Image(systemName: "phone.fill")
                        .font(.caption2)
                    Text(phone)
                        .font(.caption)
                }
                .foregroundColor(.black.opacity(0.6))
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 병원 상세 시트
struct HospitalDetailSheet: View {
    let hospital: Hospital
    let onCall: () -> Void
    let onDirections: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // 드래그 핸들
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.black.opacity(0.2))
                .frame(width: 40, height: 6)
                .padding(.top, 8)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "cross.circle.fill")
                        .foregroundColor(AppTheme.danger)
                        .font(.title)

                    VStack(alignment: .leading) {
                        Text(hospital.name)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.black)

                        if hospital.distance != nil {
                            Text(hospital.distanceText)
                                .font(.caption)
                                .foregroundColor(AppTheme.primary)
                        }
                    }

                    Spacer()

                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.black.opacity(0.4))
                            .font(.title2)
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "map.fill")
                            .foregroundColor(.black.opacity(0.5))
                        Text(hospital.address)
                            .font(.subheadline)
                            .foregroundColor(.black)
                    }

                    if let roadAddress = hospital.roadAddress {
                        HStack {
                            Image(systemName: "signpost.right.fill")
                                .foregroundColor(.black.opacity(0.5))
                            Text(roadAddress)
                                .font(.caption)
                                .foregroundColor(.black.opacity(0.6))
                        }
                    }

                    if let phone = hospital.phone {
                        HStack {
                            Image(systemName: "phone.fill")
                                .foregroundColor(.black.opacity(0.5))
                            Text(phone)
                                .font(.subheadline)
                                .foregroundColor(.black)
                        }
                    }
                }

                HStack(spacing: 12) {
                    if hospital.phone != nil {
                        Button(action: onCall) {
                            HStack {
                                Image(systemName: "phone.fill")
                                Text("전화")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppTheme.success)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }

                    Button(action: onDirections) {
                        HStack {
                            Image(systemName: "map.fill")
                            Text("길찾기")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.primary)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
            }
            .padding()
        }
        .background(AppTheme.cardBackground)
        .cornerRadius(20, corners: [.topLeft, .topRight])
        .shadow(color: AppTheme.shadow, radius: 10)
    }
}

// MARK: - Corner Radius Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    HospitalView()
}
