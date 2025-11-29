//
//  DogEntity+CoreDataClass.swift
//  petsanCheck
//
//  Created on 2025-11-29.
//

import Foundation
import CoreData

@objc(DogEntity)
public class DogEntity: NSManagedObject {
    /// Dog 도메인 모델로 변환
    func toDomain() -> Dog {
        Dog(
            id: id ?? UUID(),
            name: name ?? "",
            breed: breed ?? "",
            birthDate: birthDate ?? Date(),
            weight: weight,
            gender: Dog.Gender(rawValue: gender ?? "남아") ?? .male,
            profileImageData: profileImageData,
            notes: notes,
            createdAt: createdAt ?? Date(),
            updatedAt: updatedAt ?? Date()
        )
    }

    /// Dog 도메인 모델로부터 업데이트
    func update(from dog: Dog) {
        self.id = dog.id
        self.name = dog.name
        self.breed = dog.breed
        self.birthDate = dog.birthDate
        self.weight = dog.weight
        self.gender = dog.gender.rawValue
        self.profileImageData = dog.profileImageData
        self.notes = dog.notes
        self.updatedAt = Date()
    }
}
