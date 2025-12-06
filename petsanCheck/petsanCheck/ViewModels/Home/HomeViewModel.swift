//
//  HomeViewModel.swift
//  petsanCheck
//
//  Created on 2025-11-30.
//

import Foundation
import CoreLocation
import Combine

/// 홈 화면 ViewModel
@MainActor
class HomeViewModel: ObservableObject {
    @Published var weatherInfo: WeatherInfo = .preview
    @Published var walkRecommendation: WalkRecommendation?
    @Published var isLoadingWeather = false
    @Published var weatherError: String?

    private let weatherService = WeatherService.shared
    private let locationManager = LocationManager()
    private let geocoder = CLGeocoder()
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupBindings()
    }

    private func setupBindings() {
        // 위치 변경 감지
        locationManager.$location
            .compactMap { $0 }
            .sink { [weak self] location in
                Task {
                    await self?.loadWeather(for: location)
                }
            }
            .store(in: &cancellables)
    }

    /// 날씨 정보 로드
    func loadWeather(for location: CLLocation) async {
        isLoadingWeather = true
        weatherError = nil

        do {
            var weather = try await weatherService.fetchWeather(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )

            // 한글 위치명 가져오기
            let koreanLocationName = await getKoreanLocationName(for: location)
            if let koreanName = koreanLocationName {
                weather = WeatherInfo(
                    id: weather.id,
                    temperature: weather.temperature,
                    humidity: weather.humidity,
                    precipitation: weather.precipitation,
                    windSpeed: weather.windSpeed,
                    uvIndex: weather.uvIndex,
                    airQuality: weather.airQuality,
                    weatherCondition: weather.weatherCondition,
                    timestamp: weather.timestamp,
                    locationName: koreanName
                )
            }

            self.weatherInfo = weather
            self.evaluateWalkConditions()
        } catch let error as WeatherServiceError {
            self.weatherError = error.errorDescription
            // API 키 에러인 경우 preview 데이터 사용
            if case .invalidAPIKey = error {
                self.weatherInfo = .preview
                self.evaluateWalkConditions()
            }
        } catch {
            self.weatherError = "날씨 정보를 가져오는데 실패했습니다: \(error.localizedDescription)"
        }

        isLoadingWeather = false
    }

    /// 한글 위치명 가져오기 (Reverse Geocoding)
    private func getKoreanLocationName(for location: CLLocation) async -> String? {
        return await withCheckedContinuation { continuation in
            // 한국어 로케일 설정
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location, preferredLocale: Locale(identifier: "ko_KR")) { placemarks, error in
                if let placemark = placemarks?.first {
                    // 구/동 단위로 표시 (예: 서울특별시 강남구)
                    var locationParts: [String] = []

                    if let administrativeArea = placemark.administrativeArea {
                        locationParts.append(administrativeArea) // 서울특별시
                    }
                    if let locality = placemark.locality {
                        locationParts.append(locality) // 강남구
                    } else if let subAdministrativeArea = placemark.subAdministrativeArea {
                        locationParts.append(subAdministrativeArea)
                    }
                    if let subLocality = placemark.subLocality {
                        locationParts.append(subLocality) // 역삼동
                    }

                    if !locationParts.isEmpty {
                        // 최대 2개까지만 표시 (예: 서울특별시 강남구)
                        let displayName = locationParts.prefix(2).joined(separator: " ")
                        continuation.resume(returning: displayName)
                    } else {
                        continuation.resume(returning: nil)
                    }
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    /// 현재 위치의 날씨 로드
    func loadCurrentLocationWeather() {
        // 위치 권한 요청
        locationManager.requestPermission()
        locationManager.startUpdatingLocation()
    }

    /// 산책 조건 평가
    private func evaluateWalkConditions() {
        walkRecommendation = WeatherEvaluator.evaluateWalkConditions(weather: weatherInfo)
    }
}
