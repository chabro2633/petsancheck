//
//  DogEntity+CoreDataProperties.swift
//  petsanCheck
//
//  Created on 2025-11-29.
//

import Foundation
import CoreData

extension DogEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<DogEntity> {
        return NSFetchRequest<DogEntity>(entityName: "DogEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var breed: String?
    @NSManaged public var birthDate: Date?
    @NSManaged public var weight: Double
    @NSManaged public var gender: String?
    @NSManaged public var profileImageData: Data?
    @NSManaged public var notes: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var walkRecords: NSSet?
}

// MARK: Generated accessors for walkRecords
extension DogEntity {
    @objc(addWalkRecordsObject:)
    @NSManaged public func addToWalkRecords(_ value: WalkRecordEntity)

    @objc(removeWalkRecordsObject:)
    @NSManaged public func removeFromWalkRecords(_ value: WalkRecordEntity)

    @objc(addWalkRecords:)
    @NSManaged public func addToWalkRecords(_ values: NSSet)

    @objc(removeWalkRecords:)
    @NSManaged public func removeFromWalkRecords(_ values: NSSet)
}

extension DogEntity: Identifiable {
}
