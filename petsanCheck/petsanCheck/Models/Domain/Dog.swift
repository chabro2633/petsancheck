//
//  Dog.swift
//  petsanCheck
//
//  Created on 2025-11-29.
//

import Foundation

/// 반려견 정보 모델
struct Dog: Codable, Identifiable, Equatable {
    static func == (lhs: Dog, rhs: Dog) -> Bool {
        lhs.id == rhs.id
    }

    let id: UUID
    var name: String
    var breed: String
    var birthDate: Date
    var weight: Double // kg
    var gender: Gender
    var profileImageData: Data?
    var notes: String?
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        breed: String,
        birthDate: Date,
        weight: Double,
        gender: Gender,
        profileImageData: Data? = nil,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.breed = breed
        self.birthDate = birthDate
        self.weight = weight
        self.gender = gender
        self.profileImageData = profileImageData
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// 나이 계산 (년)
    var age: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: birthDate, to: Date())
        return components.year ?? 0
    }

    /// 나이 텍스트 (개월 포함)
    var ageText: String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: birthDate, to: Date())
        let years = components.year ?? 0
        let months = components.month ?? 0

        if years > 0 {
            return "\(years)년 \(months)개월"
        } else {
            return "\(months)개월"
        }
    }

    /// 성별
    enum Gender: String, Codable, CaseIterable {
        case male = "남아"
        case female = "여아"
    }
}

// MARK: - Preview Helper
extension Dog {
    static var preview: Dog {
        Dog(
            name: "뽀삐",
            breed: "포메라니안",
            birthDate: Calendar.current.date(byAdding: .year, value: -3, to: Date()) ?? Date(),
            weight: 4.5,
            gender: .female,
            notes: "활발하고 사람을 좋아해요"
        )
    }

    static var previews: [Dog] {
        [
            Dog(
                name: "뽀삐",
                breed: "포메라니안",
                birthDate: Calendar.current.date(byAdding: .year, value: -3, to: Date()) ?? Date(),
                weight: 4.5,
                gender: .female
            ),
            Dog(
                name: "초코",
                breed: "치와와",
                birthDate: Calendar.current.date(byAdding: .year, value: -2, to: Date()) ?? Date(),
                weight: 2.8,
                gender: .male
            ),
            Dog(
                name: "복실이",
                breed: "말티즈",
                birthDate: Calendar.current.date(byAdding: .month, value: -8, to: Date()) ?? Date(),
                weight: 3.2,
                gender: .male
            )
        ]
    }
}
