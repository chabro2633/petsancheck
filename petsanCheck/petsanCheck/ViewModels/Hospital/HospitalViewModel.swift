//
//  HospitalViewModel.swift
//  petsanCheck
//
//  Created on 2025-11-30.
//

import Foundation
import CoreLocation
import Combine

/// 동물병원 검색 ViewModel
@MainActor
class HospitalViewModel: ObservableObject {
    @Published var hospitals: [Hospital] = []
    @Published var selectedHospital: Hospital?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var searchMode: SearchMode = .nearby

    private let hospitalService = HospitalService.shared
    private let locationManager = LocationManager()
    private var cancellables = Set<AnyCancellable>()
    private var currentLocation: CLLocation?

    enum SearchMode {
        case nearby // 현재 위치 근처
        case region // 지역명 검색
        case name // 병원명 검색
    }

    init() {
        setupBindings()
    }

    private func setupBindings() {
        // 위치 변경 감지
        locationManager.$location
            .compactMap { $0 }
            .sink { [weak self] location in
                self?.currentLocation = location
                if self?.searchMode == .nearby {
                    Task {
                        await self?.searchNearbyHospitals()
                    }
                }
            }
            .store(in: &cancellables)

        // 검색어 변경 감지 (디바운싱)
        $searchText
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] text in
                guard let self = self, !text.isEmpty else { return }

                Task {
                    await self.performSearch()
                }
            }
            .store(in: &cancellables)
    }

    /// 현재 위치 가져오기
    func requestLocation() {
        locationManager.requestPermission()
        locationManager.startUpdatingLocation()
    }

    /// 근처 병원 검색
    func searchNearbyHospitals() async {
        guard let location = currentLocation else {
            errorMessage = "현재 위치를 가져올 수 없습니다."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let results = try await hospitalService.searchNearbyHospitals(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
            self.hospitals = results
        } catch let error as HospitalServiceError {
            self.errorMessage = error.errorDescription
            // API 키 에러인 경우 preview 데이터 사용
            if case .invalidAPIKey = error {
                self.hospitals = Hospital.previews
            }
        } catch {
            self.errorMessage = "병원 정보를 가져오는데 실패했습니다: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// 검색 실행
    func performSearch() async {
        guard !searchText.isEmpty else {
            await searchNearbyHospitals()
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let results: [Hospital]

            switch searchMode {
            case .nearby:
                if let location = currentLocation {
                    results = try await hospitalService.searchHospitalsByName(
                        name: searchText,
                        latitude: location.coordinate.latitude,
                        longitude: location.coordinate.longitude
                    )
                } else {
                    results = try await hospitalService.searchHospitalsByName(name: searchText)
                }
            case .region:
                results = try await hospitalService.searchHospitalsByRegion(region: searchText)
            case .name:
                if let location = currentLocation {
                    results = try await hospitalService.searchHospitalsByName(
                        name: searchText,
                        latitude: location.coordinate.latitude,
                        longitude: location.coordinate.longitude
                    )
                } else {
                    results = try await hospitalService.searchHospitalsByName(name: searchText)
                }
            }

            self.hospitals = results
        } catch let error as HospitalServiceError {
            self.errorMessage = error.errorDescription
        } catch {
            self.errorMessage = "검색에 실패했습니다: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// 전화 걸기
    func callHospital(_ hospital: Hospital) {
        guard let phone = hospital.phone,
              let url = URL(string: "tel://\(phone.replacingOccurrences(of: "-", with: ""))") else {
            return
        }

        UIApplication.shared.open(url)
    }

    /// 지도 앱에서 열기
    func openInMaps(_ hospital: Hospital) {
        let coordinate = hospital.coordinate
        let url = URL(string: "http://maps.apple.com/?ll=\(coordinate.latitude),\(coordinate.longitude)&q=\(hospital.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")

        if let url = url {
            UIApplication.shared.open(url)
        }
    }
}
