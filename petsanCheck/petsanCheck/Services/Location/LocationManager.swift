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
    @Published var isLocating = false

    private let locationManager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()
    private var lastValidLocation: CLLocation?

    // 위치 필터링 설정값
    private let minimumHorizontalAccuracyForTracking: CLLocationAccuracy = 20.0
    private let minimumHorizontalAccuracyForInitial: CLLocationAccuracy = 1000.0  // 1km까지 허용 (더 빠른 초기 표시)
    private let minimumDistanceFilter: CLLocationDistance = 5.0
    private let maximumLocationAge: TimeInterval = 120.0  // 2분까지 캐시 허용
    private let maximumLocationAgeForTracking: TimeInterval = 10.0

    override init() {
        self.authorizationStatus = locationManager.authorizationStatus
        super.init()

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest  // 최고 정확도로 시작
        locationManager.distanceFilter = kCLDistanceFilterNone  // 모든 위치 업데이트 수신
        locationManager.activityType = .fitness
        locationManager.pausesLocationUpdatesAutomatically = false

        print("[Location] 초기화 완료 - 권한 상태: \(authorizationStatus.rawValue)")

        // 권한이 있으면 즉시 캐시된 위치 사용 및 위치 업데이트 시작
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            useImmediateCachedLocation()
            // 즉시 위치 업데이트 시작
            locationManager.startUpdatingLocation()
            print("[Location] 자동 위치 업데이트 시작")
        }
    }

    /// 즉시 캐시된 위치 사용 (가장 빠름)
    private func useImmediateCachedLocation() {
        // 시스템에 캐시된 위치가 있으면 즉시 사용
        if let cachedLocation = locationManager.location {
            let age = -cachedLocation.timestamp.timeIntervalSinceNow
            // 5분 이내 캐시는 무조건 사용 (빠른 표시 우선)
            if age < 300 {
                self.location = cachedLocation
                print("[Location] 즉시 캐시 사용: \(String(format: "%.4f, %.4f", cachedLocation.coordinate.latitude, cachedLocation.coordinate.longitude)) (나이: \(String(format: "%.0f", age))초)")
            }
        }
    }

    /// 위치 권한 요청
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    /// 빠른 초기 위치 가져오기
    func startQuickLocationFetch() {
        print("[Location] startQuickLocationFetch 호출 - 현재 권한: \(authorizationStatus.rawValue)")

        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            print("[Location] 권한 없음 - 권한 요청")
            requestPermission()
            return
        }

        // 1. 먼저 캐시된 위치 즉시 사용
        useImmediateCachedLocation()

        // 이미 위치가 있으면 로딩 표시 안함
        if location != nil {
            isLocating = false
            print("[Location] 이미 위치 있음: \(String(format: "%.6f, %.6f", location!.coordinate.latitude, location!.coordinate.longitude))")
        } else {
            isLocating = true
            print("[Location] 위치 없음 - 새로 요청")
        }

        // 2. 항상 위치 업데이트 시작 (더 정확한 위치를 위해)
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.startUpdatingLocation()
        print("[Location] 위치 업데이트 요청 완료")
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

        // 고정밀 추적 모드
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 3.0

        startUpdatingLocation()
    }

    /// 산책 추적 중지
    func stopTracking() {
        guard isTracking else { return }

        isTracking = false
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = minimumDistanceFilter

        stopUpdatingLocation()
    }

    /// 초기 표시용 유효성 검사 (관대함)
    private func isValidForInitialDisplay(_ location: CLLocation) -> Bool {
        guard location.horizontalAccuracy >= 0 &&
              location.horizontalAccuracy <= minimumHorizontalAccuracyForInitial else {
            return false
        }

        let locationAge = -location.timestamp.timeIntervalSinceNow
        guard locationAge <= maximumLocationAge else {
            return false
        }

        return true
    }

    /// 추적용 유효성 검사 (엄격함)
    private func isValidForTracking(_ location: CLLocation) -> Bool {
        guard location.horizontalAccuracy >= 0 &&
              location.horizontalAccuracy <= minimumHorizontalAccuracyForTracking else {
            return false
        }

        let locationAge = -location.timestamp.timeIntervalSinceNow
        guard locationAge <= maximumLocationAgeForTracking else {
            return false
        }

        if let lastLocation = lastValidLocation {
            let distance = location.distance(from: lastLocation)
            let timeDiff = location.timestamp.timeIntervalSince(lastLocation.timestamp)

            if timeDiff > 0 {
                let speed = distance / timeDiff
                if speed > 13.9 {  // 50km/h 이상은 무시
                    return false
                }
            }
        }

        return true
    }

    /// 총 이동 거리 (미터)
    var totalDistance: Double {
        guard trackingLocations.count > 1 else { return 0 }

        var distance: Double = 0
        for i in 1..<trackingLocations.count {
            distance += trackingLocations[i-1].distance(from: trackingLocations[i])
        }
        return distance
    }

    /// 평균 속도 (km/h)
    var averageSpeed: Double {
        guard trackingLocations.count > 1,
              let firstTime = trackingLocations.first?.timestamp,
              let lastTime = trackingLocations.last?.timestamp else {
            return 0
        }

        let timeInterval = lastTime.timeIntervalSince(firstTime) / 3600
        guard timeInterval > 0 else { return 0 }

        return (totalDistance / 1000) / timeInterval
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            let newStatus = manager.authorizationStatus
            print("[Location] 권한 상태 변경: \(authorizationStatus.rawValue) → \(newStatus.rawValue)")
            authorizationStatus = newStatus

            if newStatus == .authorizedWhenInUse || newStatus == .authorizedAlways {
                print("[Location] 권한 허용됨 - 위치 업데이트 시작")
                useImmediateCachedLocation()
                locationManager.desiredAccuracy = kCLLocationAccuracyBest
                locationManager.distanceFilter = kCLDistanceFilterNone
                locationManager.startUpdatingLocation()
            } else if newStatus == .denied || newStatus == .restricted {
                print("[Location] 권한 거부됨")
                error = .permissionDenied
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            print("[Location] didUpdateLocations 호출됨 - 위치 개수: \(locations.count)")

            // 가장 최근 위치 사용
            guard let newLocation = locations.last else {
                print("[Location] 위치 배열이 비어있음")
                return
            }

            let age = -newLocation.timestamp.timeIntervalSinceNow
            print("[Location] 새 위치 수신: \(String(format: "%.6f, %.6f", newLocation.coordinate.latitude, newLocation.coordinate.longitude))")
            print("[Location] - 정확도: \(String(format: "%.0f", newLocation.horizontalAccuracy))m, 나이: \(String(format: "%.1f", age))초")

            // 유효한 위치인지 확인 (정확도가 음수면 무효)
            guard newLocation.horizontalAccuracy >= 0 else {
                print("[Location] 무효한 위치 (정확도 음수)")
                return
            }

            // 너무 오래된 위치는 건너뜀 (5분 이상)
            guard age < 300 else {
                print("[Location] 너무 오래된 위치 (5분 초과)")
                return
            }

            // 위치 업데이트 - 항상 최신 위치로 업데이트
            let previousLocation = self.location
            self.location = newLocation
            isLocating = false

            if previousLocation == nil {
                print("[Location] ✅ 첫 위치 설정 완료!")
            } else {
                print("[Location] ✅ 위치 업데이트 완료")
            }

            // 추적 중이면 엄격한 기준 적용
            if isTracking {
                guard isValidForTracking(newLocation) else {
                    print("[Location] 추적용 유효성 검사 실패")
                    return
                }

                self.lastValidLocation = newLocation

                if let lastTracked = trackingLocations.last {
                    let distance = newLocation.distance(from: lastTracked)
                    if distance >= 2.0 {
                        trackingLocations.append(newLocation)
                        print("[Location] 경로에 추가 (거리: \(String(format: "%.1f", distance))m)")
                    }
                } else {
                    trackingLocations.append(newLocation)
                    print("[Location] 첫 경로 포인트 추가")
                }
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            print("[Location] 오류: \(error.localizedDescription)")
            isLocating = false

            if let clError = error as? CLError {
                switch clError.code {
                case .denied:
                    self.error = .permissionDenied
                case .locationUnknown:
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
            return "위치 권한이 거부되었습니다."
        case .locationUnavailable:
            return "현재 위치를 찾을 수 없습니다."
        case .unknown(let message):
            return message
        }
    }
}
