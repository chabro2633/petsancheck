//
//  LocationManager.swift
//  petsanCheck
//
//  Created on 2025-11-29.
//

import Foundation
import CoreLocation
import Combine

/// 위치 추적 및 관리를 담당하는 서비스
@MainActor
class LocationManager: NSObject, ObservableObject {
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var isTracking = false
    @Published var trackingLocations: [CLLocation] = []
    @Published var error: LocationError?
    @Published var isLocating = false  // 위치 찾는 중 표시

    private let locationManager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()
    private var lastValidLocation: CLLocation?
    private var initialLocationTimer: Timer?

    // 위치 필터링을 위한 설정값 (추적용 - 엄격함)
    private let minimumHorizontalAccuracyForTracking: CLLocationAccuracy = 20.0  // 추적용: 20m
    // 초기 위치용 - 더 관대함 (빠른 표시를 위해)
    private let minimumHorizontalAccuracyForInitial: CLLocationAccuracy = 100.0  // 초기: 100m
    private let minimumDistanceFilter: CLLocationDistance = 5.0
    private let maximumLocationAge: TimeInterval = 30.0  // 초기: 30초까지 허용
    private let maximumLocationAgeForTracking: TimeInterval = 10.0  // 추적: 10초

    override init() {
        self.authorizationStatus = locationManager.authorizationStatus
        super.init()

        locationManager.delegate = self

        // 빠른 초기 위치를 위해 Best 대신 NearestTenMeters 사용 (더 빠름)
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.distanceFilter = minimumDistanceFilter
        locationManager.activityType = .fitness
        locationManager.pausesLocationUpdatesAutomatically = false

        // 권한이 이미 있으면 즉시 위치 요청 시작
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            startQuickLocationFetch()
        }
    }

    /// 위치 권한 요청
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    /// 빠른 초기 위치 가져오기 (앱 시작 시)
    func startQuickLocationFetch() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            return
        }

        isLocating = true

        // 캐시된 위치가 있으면 먼저 사용 (30초 이내)
        if let cachedLocation = locationManager.location,
           -cachedLocation.timestamp.timeIntervalSinceNow < 30 {
            self.location = cachedLocation
            print("[Location] 캐시된 위치 사용: \(cachedLocation.coordinate)")
        }

        // 즉시 위치 업데이트 시작
        locationManager.startUpdatingLocation()

        // 3초 후에도 위치를 못 찾으면 정확도 낮춰서 재시도
        initialLocationTimer?.invalidate()
        initialLocationTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                if self?.location == nil {
                    print("[Location] 3초 내 위치 못찾음 - 정확도 낮춤")
                    self?.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
                }
            }
        }
    }

    /// 위치 업데이트 시작
    func startUpdatingLocation() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            error = .permissionDenied
            return
        }

        isLocating = true
        locationManager.startUpdatingLocation()
    }

    /// 위치 업데이트 중지
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
        isLocating = false
    }

    /// 산책 추적 시작
    func startTracking() {
        guard !isTracking else { return }

        trackingLocations.removeAll()
        lastValidLocation = nil
        isTracking = true

        // 고정밀 추적 모드로 전환
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 3.0  // 추적 중에는 3미터마다 업데이트

        startUpdatingLocation()
    }

    /// 산책 추적 중지
    func stopTracking() {
        guard isTracking else { return }

        isTracking = false

        // 일반 모드로 복귀
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.distanceFilter = minimumDistanceFilter

        stopUpdatingLocation()
    }

    /// 위치가 초기 표시용으로 유효한지 (더 관대함)
    private func isValidForInitialDisplay(_ location: CLLocation) -> Bool {
        // 정확도 100m 이내
        guard location.horizontalAccuracy >= 0 &&
              location.horizontalAccuracy <= minimumHorizontalAccuracyForInitial else {
            return false
        }

        // 30초 이내 위치
        let locationAge = -location.timestamp.timeIntervalSinceNow
        guard locationAge <= maximumLocationAge else {
            return false
        }

        return true
    }

    /// 위치가 추적용으로 유효한지 (엄격함)
    private func isValidForTracking(_ location: CLLocation) -> Bool {
        // 1. 정확도 체크 - 수평 정확도가 너무 낮으면 무시
        guard location.horizontalAccuracy >= 0 &&
              location.horizontalAccuracy <= minimumHorizontalAccuracyForTracking else {
            print("[Location] 정확도 부족: \(location.horizontalAccuracy)m")
            return false
        }

        // 2. 위치 나이 체크 - 너무 오래된 위치는 무시
        let locationAge = -location.timestamp.timeIntervalSinceNow
        guard locationAge <= maximumLocationAgeForTracking else {
            print("[Location] 오래된 위치: \(locationAge)초 전")
            return false
        }

        // 3. 이전 위치와 비교하여 비정상적인 이동 감지
        if let lastLocation = lastValidLocation {
            let distance = location.distance(from: lastLocation)
            let timeDiff = location.timestamp.timeIntervalSince(lastLocation.timestamp)

            // 시간 간격이 0보다 클 때만 속도 계산
            if timeDiff > 0 {
                let speed = distance / timeDiff  // m/s

                // 비현실적인 속도 (시속 50km 이상)는 무시
                if speed > 13.9 {
                    print("[Location] 비정상 속도: \(speed * 3.6)km/h")
                    return false
                }
            }
        }

        return true
    }

    /// 위치 필터링 및 스무딩 적용
    private func processLocation(_ location: CLLocation) -> CLLocation {
        // 칼만 필터 또는 간단한 스무딩 적용 가능
        // 현재는 유효한 위치만 반환
        return location
    }

    /// 총 이동 거리 계산 (미터)
    var totalDistance: Double {
        guard trackingLocations.count > 1 else { return 0 }

        var distance: Double = 0
        for i in 1..<trackingLocations.count {
            distance += trackingLocations[i-1].distance(from: trackingLocations[i])
        }
        return distance
    }

    /// 평균 속도 계산 (km/h)
    var averageSpeed: Double {
        guard trackingLocations.count > 1,
              let firstTime = trackingLocations.first?.timestamp,
              let lastTime = trackingLocations.last?.timestamp else {
            return 0
        }

        let timeInterval = lastTime.timeIntervalSince(firstTime) / 3600 // 시간 단위로 변환
        guard timeInterval > 0 else { return 0 }

        let distanceKm = totalDistance / 1000
        return distanceKm / timeInterval
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus

            // 권한이 허용되면 즉시 위치 업데이트 시작
            if manager.authorizationStatus == .authorizedWhenInUse ||
               manager.authorizationStatus == .authorizedAlways {
                startUpdatingLocation()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            // 가장 정확한 위치 선택 (여러 위치 중 정확도가 가장 높은 것)
            let bestLocation = locations.min(by: { $0.horizontalAccuracy < $1.horizontalAccuracy })

            guard let location = bestLocation else { return }

            // 초기 위치 표시용 (더 관대한 기준)
            if self.location == nil || isValidForInitialDisplay(location) {
                // 첫 위치이거나 유효한 위치면 바로 표시
                self.location = location
                isLocating = false
                initialLocationTimer?.invalidate()
                print("[Location] 위치 업데이트: \(String(format: "%.4f", location.coordinate.latitude)), \(String(format: "%.4f", location.coordinate.longitude)) (정확도: \(String(format: "%.0f", location.horizontalAccuracy))m)")
            }

            // 추적 중이면 더 엄격한 기준 적용
            if isTracking {
                guard isValidForTracking(location) else {
                    return
                }

                let processedLocation = processLocation(location)
                self.lastValidLocation = processedLocation

                // 이전 위치와 최소 거리 이상 떨어져 있을 때만 추가 (노이즈 감소)
                if let lastTracked = trackingLocations.last {
                    let distance = processedLocation.distance(from: lastTracked)
                    if distance >= 2.0 {  // 최소 2미터 이상 이동했을 때만 추가
                        trackingLocations.append(processedLocation)
                        print("[Location] 경로 추가: \(trackingLocations.count)개, 거리: \(String(format: "%.1f", distance))m")
                    }
                } else {
                    // 첫 번째 위치는 바로 추가
                    trackingLocations.append(processedLocation)
                    print("[Location] 첫 위치 추가")
                }
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            print("[Location] 오류: \(error.localizedDescription)")

            if let clError = error as? CLError {
                switch clError.code {
                case .denied:
                    self.error = .permissionDenied
                case .locationUnknown:
                    // 위치를 찾을 수 없는 경우 - 재시도
                    self.error = .locationUnavailable
                default:
                    self.error = .unknown(clError.localizedDescription)
                }
            }
        }
    }
}

// MARK: - LocationError
enum LocationError: Error, LocalizedError {
    case permissionDenied
    case locationUnavailable
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "위치 권한이 거부되었습니다. 설정에서 권한을 허용해주세요."
        case .locationUnavailable:
            return "현재 위치를 찾을 수 없습니다."
        case .unknown(let message):
            return message
        }
    }
}
