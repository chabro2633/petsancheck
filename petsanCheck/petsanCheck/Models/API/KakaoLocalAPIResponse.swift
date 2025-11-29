//
//  KakaoLocalAPIResponse.swift
//  petsanCheck
//
//  Created on 2025-11-30.
//

import Foundation

/// 카카오 로컬 API 응답 모델
struct KakaoLocalAPIResponse: Codable {
    let meta: Meta
    let documents: [Document]

    struct Meta: Codable {
        let totalCount: Int
        let pageableCount: Int
        let isEnd: Bool

        enum CodingKeys: String, CodingKey {
            case totalCount = "total_count"
            case pageableCount = "pageable_count"
            case isEnd = "is_end"
        }
    }

    struct Document: Codable {
        let id: String
        let placeName: String
        let categoryName: String
        let categoryGroupCode: String
        let categoryGroupName: String
        let phone: String
        let addressName: String
        let roadAddressName: String
        let x: String // longitude
        let y: String // latitude
        let placeUrl: String
        let distance: String

        enum CodingKeys: String, CodingKey {
            case id
            case placeName = "place_name"
            case categoryName = "category_name"
            case categoryGroupCode = "category_group_code"
            case categoryGroupName = "category_group_name"
            case phone
            case addressName = "address_name"
            case roadAddressName = "road_address_name"
            case x, y
            case placeUrl = "place_url"
            case distance
        }

        /// Hospital 도메인 모델로 변환
        func toHospital() -> Hospital? {
            guard let lat = Double(y),
                  let lon = Double(x) else {
                return nil
            }

            let dist = Double(distance)

            return Hospital(
                id: id,
                name: placeName,
                address: addressName,
                roadAddress: roadAddressName.isEmpty ? nil : roadAddressName,
                phone: phone.isEmpty ? nil : phone,
                latitude: lat,
                longitude: lon,
                distance: dist,
                category: categoryGroupName,
                url: placeUrl.isEmpty ? nil : placeUrl
            )
        }
    }
}
