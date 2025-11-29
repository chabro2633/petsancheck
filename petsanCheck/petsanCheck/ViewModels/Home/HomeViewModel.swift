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
            let weather = try await weatherService.fetchWeather(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
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
