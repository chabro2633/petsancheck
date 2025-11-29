//
//  Hospital.swift
//  petsanCheck
//
//  Created on 2025-11-30.
//

import Foundation
import CoreLocation

/// 동물병원 정보 모델
struct Hospital: Codable, Identifiable {
    let id: String
    let name: String
    let address: String
    let roadAddress: String?
    let phone: String?
    let latitude: Double
    let longitude: Double
    let distance: Double? // 현재 위치로부터의 거리 (미터)
    let category: String?
    let url: String?

    /// CLLocationCoordinate2D로 변환
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// 거리 표시 텍스트
    var distanceText: String {
        guard let distance = distance else { return "" }

        if distance < 1000 {
            return String(format: "%.0fm", distance)
        } else {
            return String(format: "%.1fkm", distance / 1000)
        }
    }

    /// 전화번호 포맷팅
    var formattedPhone: String? {
        guard let phone = phone else { return nil }
        return phone
    }
}

// MARK: - Preview Helper
extension Hospital {
    static var preview: Hospital {
        Hospital(
            id: "1",
            name: "서울동물병원",
            address: "서울특별시 강남구 역삼동 123-45",
            roadAddress: "서울특별시 강남구 테헤란로 123",
            phone: "02-1234-5678",
            latitude: 37.5665,
            longitude: 126.9780,
            distance: 500,
            category: "동물병원",
            url: nil
        )
    }

    static var previews: [Hospital] {
        [
            Hospital(
                id: "1",
                name: "서울동물병원",
                address: "서울특별시 강남구 역삼동 123-45",
                roadAddress: "서울특별시 강남구 테헤란로 123",
                phone: "02-1234-5678",
                latitude: 37.5665,
                longitude: 126.9780,
                distance: 500,
                category: "동물병원",
                url: nil
            ),
            Hospital(
                id: "2",
                name: "24시 우리동물병원",
                address: "서울특별시 강남구 삼성동 456-78",
                roadAddress: "서울특별시 강남구 봉은사로 456",
                phone: "02-2345-6789",
                latitude: 37.5670,
                longitude: 126.9785,
                distance: 800,
                category: "동물병원",
                url: nil
            ),
            Hospital(
                id: "3",
                name: "강아지 고양이 동물병원",
                address: "서울특별시 강남구 논현동 789-12",
                roadAddress: "서울특별시 강남구 학동로 789",
                phone: "02-3456-7890",
                latitude: 37.5680,
                longitude: 126.9790,
                distance: 1200,
                category: "동물병원",
                url: nil
            )
        ]
    }
}
