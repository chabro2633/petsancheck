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

    private let locationManager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()

    override init() {
        self.authorizationStatus = locationManager.authorizationStatus
        super.init()

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // 10미터마다 업데이트
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.activityType = .fitness
    }

    /// 위치 권한 요청
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    /// 위치 업데이트 시작
    func startUpdatingLocation() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            error = .permissionDenied
            return
        }

        locationManager.startUpdatingLocation()
    }

    /// 위치 업데이트 중지
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }

    /// 산책 추적 시작
    func startTracking() {
        guard !isTracking else { return }

        trackingLocations.removeAll()
        isTracking = true
        startUpdatingLocation()
    }

    /// 산책 추적 중지
    func stopTracking() {
        guard isTracking else { return }

        isTracking = false
        stopUpdatingLocation()
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
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let location = locations.last else { return }

            self.location = location

            if isTracking {
                trackingLocations.append(location)
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
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
            return "위치 권한이 거부되었습니다. 설정에서 권한을 허용해주세요."
        case .locationUnavailable:
            return "현재 위치를 찾을 수 없습니다."
        case .unknown(let message):
            return message
        }
    }
}
