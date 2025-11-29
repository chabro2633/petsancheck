//
//  WalkRecordEntity+CoreDataClass.swift
//  petsanCheck
//
//  Created on 2025-11-29.
//

import Foundation
import CoreData

@objc(WalkRecordEntity)
public class WalkRecordEntity: NSManagedObject {
    /// WalkSession 도메인 모델로 변환
    func toDomain() -> WalkSession {
        let decoder = JSONDecoder()

        let locations: [WalkLocation]
        if let locationsData = locationsData,
           let decoded = try? decoder.decode([WalkLocation].self, from: locationsData) {
            locations = decoded
        } else {
            locations = []
        }

        let weather: WeatherInfo?
        if let weatherData = weatherData,
           let decoded = try? decoder.decode(WeatherInfo.self, from: weatherData) {
            weather = decoded
        } else {
            weather = nil
        }

        return WalkSession(
            id: id ?? UUID(),
            startTime: startTime ?? Date(),
            endTime: endTime,
            locations: locations,
            weatherAtStart: weather,
            notes: notes
        )
    }

    /// WalkSession 도메인 모델로부터 업데이트
    func update(from session: WalkSession) {
        let encoder = JSONEncoder()

        self.id = session.id
        self.startTime = session.startTime
        self.endTime = session.endTime
        self.totalDistance = session.totalDistance
        self.averageSpeed = session.averageSpeed
        self.calories = Int32(session.estimatedCalories)
        self.notes = session.notes

        if let locationsData = try? encoder.encode(session.locations) {
            self.locationsData = locationsData
        }

        if let weather = session.weatherAtStart,
           let weatherData = try? encoder.encode(weather) {
            self.weatherData = weatherData
        }
    }
}
