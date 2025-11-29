//
//  HospitalView.swift
//  petsanCheck
//
//  Created on 2025-11-29.
//

import SwiftUI
import MapKit

/// 병원 검색 화면
struct HospitalView: View {
    @StateObject private var viewModel = HospitalViewModel()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var showingSearchOptions = false

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    // 지도
                    Map(coordinateRegion: $region, showsUserLocation: true)
                        .frame(height: 250)
                        .overlay(alignment: .topTrailing) {
                            VStack(spacing: 12) {
                                // 내 위치로 이동 버튼
                                Button(action: {
                                    if let coordinate = viewModel.currentCoordinate {
                                        withAnimation {
                                            region.center = coordinate
                                        }
                                    }
                                }) {
                                    Image(systemName: "location.fill")
                                        .padding(12)
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .clipShape(Circle())
                                        .shadow(radius: 4)
                                }

                                // 근처 병원 검색 버튼
                                Button(action: {
                                    Task {
                                        await viewModel.searchNearbyHospitals()
                                    }
                                }) {
                                    Image(systemName: "magnifyingglass")
                                        .padding(12)
                                        .background(Color.white)
                                        .foregroundColor(.blue)
                                        .clipShape(Circle())
                                        .shadow(radius: 4)
                                }
                            }
                            .padding()
                        }

                    // 병원 목록
                    if viewModel.isLoading {
                        ProgressView("검색 중...")
                            .padding()
                    } else if let error = viewModel.errorMessage {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundColor(.orange)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                    } else if viewModel.hospitals.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                            Text("검색 결과가 없습니다")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    } else {
                        List {
                            ForEach(viewModel.hospitals) { hospital in
                                HospitalRow(hospital: hospital)
                                    .onTapGesture {
                                        viewModel.selectedHospital = hospital
                                        region.center = hospital.coordinate
                                    }
                            }
                        }
                        .listStyle(.plain)
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
                    .foregroundColor(.red)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(hospital.name)
                        .font(.headline)

                    if let distance = hospital.distance {
                        Text(hospital.distanceText)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Text(hospital.address)
                .font(.caption)
                .foregroundColor(.secondary)

            if let phone = hospital.phone {
                HStack {
                    Image(systemName: "phone.fill")
                        .font(.caption2)
                    Text(phone)
                        .font(.caption)
                }
                .foregroundColor(.secondary)
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
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 6)
                .padding(.top, 8)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "cross.circle.fill")
                        .foregroundColor(.red)
                        .font(.title)

                    VStack(alignment: .leading) {
                        Text(hospital.name)
                            .font(.title3)
                            .fontWeight(.bold)

                        if let distance = hospital.distance {
                            Text(hospital.distanceText)
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }

                    Spacer()

                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .font(.title2)
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "map.fill")
                            .foregroundColor(.gray)
                        Text(hospital.address)
                            .font(.subheadline)
                    }

                    if let roadAddress = hospital.roadAddress {
                        HStack {
                            Image(systemName: "signpost.right.fill")
                                .foregroundColor(.gray)
                            Text(roadAddress)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    if let phone = hospital.phone {
                        HStack {
                            Image(systemName: "phone.fill")
                                .foregroundColor(.gray)
                            Text(phone)
                                .font(.subheadline)
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
                            .background(Color.green)
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
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .cornerRadius(20, corners: [.topLeft, .topRight])
        .shadow(radius: 10)
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
