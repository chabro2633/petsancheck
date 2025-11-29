//
//  WeatherService.swift
//  petsanCheck
//
//  Created on 2025-11-30.
//

import Foundation
import CoreLocation

/// OpenWeatherMap API 서비스
class WeatherService {
    static let shared = WeatherService()

    private init() {}

    // TODO: 본인의 OpenWeatherMap API 키로 변경하세요
    // https://openweathermap.org/api 에서 무료 API 키를 발급받을 수 있습니다
    private let apiKey = "YOUR_API_KEY_HERE"
    private let baseURL = "https://api.openweathermap.org/data/2.5/weather"

    /// 현재 위치의 날씨 정보 가져오기
    func fetchWeather(latitude: Double, longitude: Double) async throws -> WeatherInfo {
        // API 키 확인
        guard apiKey != "YOUR_API_KEY_HERE" else {
            throw WeatherServiceError.invalidAPIKey
        }

        // URL 구성
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "lat", value: String(latitude)),
            URLQueryItem(name: "lon", value: String(longitude)),
            URLQueryItem(name: "appid", value: apiKey),
            URLQueryItem(name: "units", value: "metric"), // 섭씨 온도
            URLQueryItem(name: "lang", value: "kr") // 한국어
        ]

        guard let url = components?.url else {
            throw WeatherServiceError.invalidURL
        }

        // API 호출
        let (data, response) = try await URLSession.shared.data(from: url)

        // 응답 확인
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw WeatherServiceError.invalidResponse
        }

        // JSON 파싱
        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(WeatherAPIResponse.self, from: data)

        // 도메인 모델로 변환
        return apiResponse.toWeatherInfo()
    }

    /// 도시 이름으로 날씨 정보 가져오기
    func fetchWeather(city: String) async throws -> WeatherInfo {
        guard apiKey != "YOUR_API_KEY_HERE" else {
            throw WeatherServiceError.invalidAPIKey
        }

        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "q", value: city),
            URLQueryItem(name: "appid", value: apiKey),
            URLQueryItem(name: "units", value: "metric"),
            URLQueryItem(name: "lang", value: "kr")
        ]

        guard let url = components?.url else {
            throw WeatherServiceError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw WeatherServiceError.invalidResponse
        }

        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(WeatherAPIResponse.self, from: data)

        return apiResponse.toWeatherInfo()
    }
}

// MARK: - Errors
enum WeatherServiceError: LocalizedError {
    case invalidAPIKey
    case invalidURL
    case invalidResponse
    case decodingError

    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "OpenWeatherMap API 키를 설정해주세요. WeatherService.swift 파일에서 apiKey를 변경하세요."
        case .invalidURL:
            return "잘못된 URL입니다."
        case .invalidResponse:
            return "서버 응답이 올바르지 않습니다."
        case .decodingError:
            return "데이터 파싱에 실패했습니다."
        }
    }
}
