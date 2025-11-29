//
//  WalkViewModel.swift
//  petsanCheck
//
//  Created on 2025-11-29.
//

import Foundation
import CoreLocation
import Combine

/// 산책 기능을 관리하는 ViewModel
@MainActor
class WalkViewModel: ObservableObject {
    @Published var currentSession: WalkSession?
    @Published var isTracking = false
    @Published var showPermissionAlert = false

    private let locationManager: LocationManager
    private var cancellables = Set<AnyCancellable>()

    /// 산책 경로 위치들
    var routeLocations: [WalkLocation] {
        currentSession?.locations ?? []
    }

    init(locationManager: LocationManager) {
        self.locationManager = locationManager

        // LocationManager의 변경사항 구독
        setupBindings()
    }

    convenience init() {
        self.init(locationManager: LocationManager())
    }

    private func setupBindings() {
        // 위치 업데이트 구독
        locationManager.$location
            .compactMap { $0 }
            .sink { [weak self] location in
                self?.handleLocationUpdate(location)
            }
            .store(in: &cancellables)

        // 추적 상태 구독
        locationManager.$isTracking
            .assign(to: &$isTracking)

        // 권한 상태 구독
        locationManager.$authorizationStatus
            .sink { [weak self] status in
                if status == .denied || status == .restricted {
                    self?.showPermissionAlert = true
                    self?.stopWalk()
                }
            }
            .store(in: &cancellables)
    }

    /// 산책 시작
    func startWalk(weatherInfo: WeatherInfo? = nil) {
        // 권한 확인
        guard locationManager.authorizationStatus == .authorizedWhenInUse ||
              locationManager.authorizationStatus == .authorizedAlways else {
            locationManager.requestPermission()
            showPermissionAlert = true
            return
        }

        // 새 세션 생성
        currentSession = WalkSession(
            startTime: Date(),
            weatherAtStart: weatherInfo
        )

        // 위치 추적 시작
        locationManager.startTracking()
    }

    /// 산책 종료
    func stopWalk(dogId: UUID? = nil) {
        guard var session = currentSession else { return }

        // 종료 시간 설정
        session.endTime = Date()
        currentSession = session

        // 위치 추적 중지
        locationManager.stopTracking()

        // 세션을 CoreData에 저장
        CoreDataService.shared.createWalkRecord(session, dogId: dogId)

        // 세션 초기화
        currentSession = nil
    }

    /// 산책 일시정지
    func pauseWalk() {
        locationManager.stopUpdatingLocation()
    }

    /// 산책 재개
    func resumeWalk() {
        locationManager.startUpdatingLocation()
    }

    /// 위치 업데이트 처리
    private func handleLocationUpdate(_ location: CLLocation) {
        guard var session = currentSession else { return }

        // 위치 추가
        let walkLocation = WalkLocation(from: location)
        session.locations.append(walkLocation)
        currentSession = session
    }

    /// 현재 세션의 통계
    var currentStats: WalkStats {
        guard let session = currentSession else {
            return WalkStats(
                distance: 0,
                duration: 0,
                averageSpeed: 0,
                calories: 0
            )
        }

        return WalkStats(
            distance: session.totalDistance,
            duration: session.duration,
            averageSpeed: session.averageSpeed,
            calories: session.estimatedCalories
        )
    }

    /// 현재 위치
    var currentLocation: CLLocation? {
        locationManager.location
    }
}

/// 산책 통계 정보
struct WalkStats {
    let distance: Double // 미터
    let duration: TimeInterval // 초
    let averageSpeed: Double // km/h
    let calories: Int

    var distanceText: String {
        if distance < 1000 {
            return String(format: "%.0fm", distance)
        } else {
            return String(format: "%.2fkm", distance / 1000)
        }
    }

    var durationText: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    var speedText: String {
        String(format: "%.1f km/h", averageSpeed)
    }

    var caloriesText: String {
        "\(calories) kcal"
    }
}
