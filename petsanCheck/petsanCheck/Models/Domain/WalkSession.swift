//
//  WalkSession.swift
//  petsanCheck
//
//  Created on 2025-11-29.
//

import Foundation
import CoreLocation

/// 산책 세션 모델
struct WalkSession: Codable, Identifiable {
    let id: UUID
    let startTime: Date
    var endTime: Date?
    var locations: [WalkLocation]
    var weatherAtStart: WeatherInfo?
    var notes: String?

    init(
        id: UUID = UUID(),
        startTime: Date = Date(),
        endTime: Date? = nil,
        locations: [WalkLocation] = [],
        weatherAtStart: WeatherInfo? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.locations = locations
        self.weatherAtStart = weatherAtStart
        self.notes = notes
    }

    /// 산책 진행 중 여부
    var isActive: Bool {
        endTime == nil
    }

    /// 산책 지속 시간 (초)
    var duration: TimeInterval {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime)
    }

    /// 총 이동 거리 (미터)
    var totalDistance: Double {
        guard locations.count > 1 else { return 0 }

        var distance: Double = 0
        for i in 1..<locations.count {
            let loc1 = CLLocation(
                latitude: locations[i-1].latitude,
                longitude: locations[i-1].longitude
            )
            let loc2 = CLLocation(
                latitude: locations[i].latitude,
                longitude: locations[i].longitude
            )
            distance += loc1.distance(from: loc2)
        }
        return distance
    }

    /// 평균 속도 (km/h)
    var averageSpeed: Double {
        guard duration > 0 else { return 0 }
        let distanceKm = totalDistance / 1000
        let durationHours = duration / 3600
        return distanceKm / durationHours
    }

    /// 평균 페이스 (분/km)
    var averagePace: Double {
        guard averageSpeed > 0 else { return 0 }
        return 60 / averageSpeed
    }

    /// 소모 칼로리 추정 (대략적인 계산)
    var estimatedCalories: Int {
        // 평균 체중 60kg 기준, 걷기 시 약 0.05 kcal/kg/분
        let durationMinutes = duration / 60
        return Int(60 * 0.05 * durationMinutes)
    }

    /// 산책 경로의 중심 좌표
    var centerCoordinate: (latitude: Double, longitude: Double)? {
        guard !locations.isEmpty else { return nil }

        let sumLat = locations.reduce(0.0) { $0 + $1.latitude }
        let sumLon = locations.reduce(0.0) { $0 + $1.longitude }

        return (
            latitude: sumLat / Double(locations.count),
            longitude: sumLon / Double(locations.count)
        )
    }
}

/// 산책 경로의 위치 정보
struct WalkLocation: Codable, Identifiable {
    let id: UUID
    let latitude: Double
    let longitude: Double
    let altitude: Double
    let timestamp: Date
    let speed: Double // m/s
    let accuracy: Double // 위치 정확도 (미터)

    init(
        id: UUID = UUID(),
        latitude: Double,
        longitude: Double,
        altitude: Double = 0,
        timestamp: Date = Date(),
        speed: Double = 0,
        accuracy: Double = 0
    ) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.timestamp = timestamp
        self.speed = speed
        self.accuracy = accuracy
    }

    init(from location: CLLocation) {
        self.id = UUID()
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
        self.altitude = location.altitude
        self.timestamp = location.timestamp
        self.speed = location.speed
        self.accuracy = location.horizontalAccuracy
    }
}

// MARK: - Preview Helper
extension WalkSession {
    static var preview: WalkSession {
        let now = Date()
        let startTime = now.addingTimeInterval(-1800) // 30분 전

        let locations = [
            WalkLocation(latitude: 37.5665, longitude: 126.9780, timestamp: startTime),
            WalkLocation(latitude: 37.5670, longitude: 126.9785, timestamp: startTime.addingTimeInterval(300)),
            WalkLocation(latitude: 37.5675, longitude: 126.9790, timestamp: startTime.addingTimeInterval(600)),
            WalkLocation(latitude: 37.5680, longitude: 126.9795, timestamp: startTime.addingTimeInterval(900)),
            WalkLocation(latitude: 37.5685, longitude: 126.9800, timestamp: startTime.addingTimeInterval(1200))
        ]

        return WalkSession(
            startTime: startTime,
            endTime: now,
            locations: locations,
            weatherAtStart: .preview,
            notes: "강아지와 함께한 즐거운 산책"
        )
    }

    static var activePreview: WalkSession {
        let now = Date()
        let startTime = now.addingTimeInterval(-600) // 10분 전

        let locations = [
            WalkLocation(latitude: 37.5665, longitude: 126.9780, timestamp: startTime),
            WalkLocation(latitude: 37.5670, longitude: 126.9785, timestamp: startTime.addingTimeInterval(300))
        ]

        return WalkSession(
            startTime: startTime,
            locations: locations,
            weatherAtStart: .preview
        )
    }
}
