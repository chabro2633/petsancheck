//
//  WeatherAPIResponse.swift
//  petsanCheck
//
//  Created on 2025-11-30.
//

import Foundation

/// OpenWeatherMap API 응답 모델
struct WeatherAPIResponse: Codable {
    let coord: Coordinates
    let weather: [Weather]
    let main: Main
    let wind: Wind
    let clouds: Clouds
    let dt: Int
    let sys: Sys
    let timezone: Int
    let name: String

    struct Coordinates: Codable {
        let lon: Double
        let lat: Double
    }

    struct Weather: Codable {
        let id: Int
        let main: String
        let description: String
        let icon: String
    }

    struct Main: Codable {
        let temp: Double
        let feels_like: Double
        let temp_min: Double
        let temp_max: Double
        let pressure: Int
        let humidity: Int
    }

    struct Wind: Codable {
        let speed: Double
        let deg: Int?
    }

    struct Clouds: Codable {
        let all: Int
    }

    struct Sys: Codable {
        let country: String?
        let sunrise: Int
        let sunset: Int
    }

    /// WeatherInfo 도메인 모델로 변환
    func toWeatherInfo() -> WeatherInfo {
        // 날씨 상태 매핑
        let condition: WeatherInfo.WeatherCondition
        if let firstWeather = weather.first {
            switch firstWeather.main.lowercased() {
            case "clear":
                condition = .sunny
            case "clouds":
                condition = main.temp > 15 ? .cloudy : .cloudy
            case "rain", "drizzle":
                condition = .rainy
            case "snow":
                condition = .snowy
            case "thunderstorm":
                condition = .rainy
            default:
                condition = .cloudy
            }
        } else {
            condition = .cloudy
        }

        // 대기질은 별도 API가 필요하므로 기본값 사용
        let airQuality = 50 // 보통

        // UV 인덱스도 별도 API가 필요하므로 시간대로 추정
        let hour = Calendar.current.component(.hour, from: Date())
        let uvIndex: Int
        if hour >= 10 && hour <= 14 {
            uvIndex = 7 // 높음
        } else if hour >= 9 && hour <= 15 {
            uvIndex = 5 // 보통
        } else {
            uvIndex = 2 // 낮음
        }

        return WeatherInfo(
            id: UUID(),
            temperature: main.temp,
            humidity: main.humidity,
            precipitation: 0, // 현재 날씨 API에는 강수량 정보가 없음
            windSpeed: wind.speed,
            uvIndex: uvIndex,
            airQuality: airQuality,
            weatherCondition: condition,
            timestamp: Date(),
            locationName: name  // 도시명 추가
        )
    }
}
