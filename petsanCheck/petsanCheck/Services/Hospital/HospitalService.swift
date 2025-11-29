//
//  HospitalService.swift
//  petsanCheck
//
//  Created on 2025-11-30.
//

import Foundation
import CoreLocation

/// 동물병원 검색 서비스 (카카오 로컬 API)
class HospitalService {
    static let shared = HospitalService()

    private init() {}

    // TODO: 본인의 카카오 REST API 키로 변경하세요
    // https://developers.kakao.com/ 에서 앱 등록 후 REST API 키를 발급받을 수 있습니다
    private let apiKey = "YOUR_KAKAO_REST_API_KEY"
    private let baseURL = "https://dapi.kakao.com/v2/local/search/keyword.json"

    /// 현재 위치 근처 동물병원 검색
    func searchNearbyHospitals(
        latitude: Double,
        longitude: Double,
        radius: Int = 5000 // 기본 5km
    ) async throws -> [Hospital] {
        guard apiKey != "YOUR_KAKAO_REST_API_KEY" else {
            throw HospitalServiceError.invalidAPIKey
        }

        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "query", value: "동물병원"),
            URLQueryItem(name: "x", value: String(longitude)),
            URLQueryItem(name: "y", value: String(latitude)),
            URLQueryItem(name: "radius", value: String(radius)),
            URLQueryItem(name: "sort", value: "distance"), // 거리순 정렬
            URLQueryItem(name: "size", value: "15") // 최대 15개
        ]

        guard let url = components?.url else {
            throw HospitalServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.addValue("KakaoAK \(apiKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw HospitalServiceError.invalidResponse
        }

        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(KakaoLocalAPIResponse.self, from: data)

        return apiResponse.documents.compactMap { $0.toHospital() }
    }

    /// 지역명으로 동물병원 검색
    func searchHospitalsByRegion(
        region: String,
        page: Int = 1
    ) async throws -> [Hospital] {
        guard apiKey != "YOUR_KAKAO_REST_API_KEY" else {
            throw HospitalServiceError.invalidAPIKey
        }

        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "query", value: "\(region) 동물병원"),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "size", value: "15")
        ]

        guard let url = components?.url else {
            throw HospitalServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.addValue("KakaoAK \(apiKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw HospitalServiceError.invalidResponse
        }

        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(KakaoLocalAPIResponse.self, from: data)

        return apiResponse.documents.compactMap { $0.toHospital() }
    }

    /// 병원명으로 검색
    func searchHospitalsByName(
        name: String,
        latitude: Double? = nil,
        longitude: Double? = nil
    ) async throws -> [Hospital] {
        guard apiKey != "YOUR_KAKAO_REST_API_KEY" else {
            throw HospitalServiceError.invalidAPIKey
        }

        var queryItems = [
            URLQueryItem(name: "query", value: "\(name) 동물병원"),
            URLQueryItem(name: "size", value: "15")
        ]

        if let lat = latitude, let lon = longitude {
            queryItems.append(URLQueryItem(name: "x", value: String(lon)))
            queryItems.append(URLQueryItem(name: "y", value: String(lat)))
            queryItems.append(URLQueryItem(name: "sort", value: "distance"))
        }

        var components = URLComponents(string: baseURL)
        components?.queryItems = queryItems

        guard let url = components?.url else {
            throw HospitalServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.addValue("KakaoAK \(apiKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw HospitalServiceError.invalidResponse
        }

        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(KakaoLocalAPIResponse.self, from: data)

        return apiResponse.documents.compactMap { $0.toHospital() }
    }
}

// MARK: - Errors
enum HospitalServiceError: LocalizedError {
    case invalidAPIKey
    case invalidURL
    case invalidResponse
    case decodingError

    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "카카오 REST API 키를 설정해주세요. HospitalService.swift 파일에서 apiKey를 변경하세요."
        case .invalidURL:
            return "잘못된 URL입니다."
        case .invalidResponse:
            return "서버 응답이 올바르지 않습니다."
        case .decodingError:
            return "데이터 파싱에 실패했습니다."
        }
    }
}
