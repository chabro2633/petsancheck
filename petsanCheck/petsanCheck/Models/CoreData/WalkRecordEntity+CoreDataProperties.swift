//
//  WalkRecordEntity+CoreDataProperties.swift
//  petsanCheck
//
//  Created on 2025-11-29.
//

import Foundation
import CoreData

extension WalkRecordEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<WalkRecordEntity> {
        return NSFetchRequest<WalkRecordEntity>(entityName: "WalkRecordEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var startTime: Date?
    @NSManaged public var endTime: Date?
    @NSManaged public var totalDistance: Double
    @NSManaged public var averageSpeed: Double
    @NSManaged public var calories: Int32
    @NSManaged public var locationsData: Data?
    @NSManaged public var weatherData: Data?
    @NSManaged public var notes: String?
    @NSManaged public var dog: DogEntity?
}

extension WalkRecordEntity: Identifiable {
}
