//
//  WeatherInfo.swift
//  petsanCheck
//
//  Created on 2025-11-29.
//

import Foundation

/// 날씨 정보 모델
struct WeatherInfo: Codable, Identifiable {
    let id: UUID
    let temperature: Double        // 온도 (°C)
    let humidity: Int              // 습도 (%)
    let precipitation: Double      // 강수량 (mm)
    let windSpeed: Double          // 풍속 (m/s)
    let uvIndex: Int              // 자외선 지수
    let airQuality: Int           // 미세먼지 (㎍/m³)
    let weatherCondition: WeatherCondition
    let timestamp: Date
    let locationName: String?      // 위치명 (도시/지역)

    /// 날씨 상태
    enum WeatherCondition: String, Codable {
        case sunny = "맑음"
        case cloudy = "흐림"
        case rainy = "비"
        case snowy = "눈"
        case foggy = "안개"

        var icon: String {
            switch self {
            case .sunny: return "sun.max.fill"
            case .cloudy: return "cloud.fill"
            case .rainy: return "cloud.rain.fill"
            case .snowy: return "cloud.snow.fill"
            case .foggy: return "cloud.fog.fill"
            }
        }
    }

    /// 온도 카테고리
    enum TemperatureCategory {
        case cold      // 10°C 이하
        case cool      // 10-15°C
        case moderate  // 15-25°C
        case warm      // 25-30°C
        case hot       // 30°C 이상

        var description: String {
            switch self {
            case .cold: return "추운 날씨"
            case .cool: return "선선한 날씨"
            case .moderate: return "적당한 날씨"
            case .warm: return "따뜻한 날씨"
            case .hot: return "더운 날씨"
            }
        }

        var emoji: String {
            switch self {
            case .cold: return "🥶"
            case .cool: return "😊"
            case .moderate: return "🌸"
            case .warm: return "☀️"
            case .hot: return "🔥"
            }
        }
    }

    /// 기본 초기화
    init(
        id: UUID = UUID(),
        temperature: Double,
        humidity: Int,
        precipitation: Double,
        windSpeed: Double,
        uvIndex: Int,
        airQuality: Int,
        weatherCondition: WeatherCondition,
        timestamp: Date = Date(),
        locationName: String? = nil
    ) {
        self.id = id
        self.temperature = temperature
        self.humidity = humidity
        self.precipitation = precipitation
        self.windSpeed = windSpeed
        self.uvIndex = uvIndex
        self.airQuality = airQuality
        self.weatherCondition = weatherCondition
        self.timestamp = timestamp
        self.locationName = locationName
    }

    /// 온도 카테고리 반환
    var temperatureCategory: TemperatureCategory {
        switch temperature {
        case ..<10: return .cold
        case 10..<15: return .cool
        case 15..<25: return .moderate
        case 25..<30: return .warm
        default: return .hot
        }
    }

    /// 산책하기 적합한지 판단
    var isSuitableForWalk: Bool {
        guard precipitation < 5.0 else { return false }  // 강수량 5mm 이상이면 부적합
        guard windSpeed < 10.0 else { return false }     // 풍속 10m/s 이상이면 부적합
        guard airQuality < 150 else { return false }     // 미세먼지 나쁨 이상이면 부적합
        return true
    }

    /// 날씨 설명 문자열
    var displayDescription: String {
        let temp = String(format: "%.1f°C", temperature)
        return "\(weatherCondition.rawValue) • \(temp)"
    }
}

// MARK: - Preview Helper
extension WeatherInfo {
    /// 프리뷰용 샘플 데이터
    static var preview: WeatherInfo {
        WeatherInfo(
            temperature: 22.5,
            humidity: 60,
            precipitation: 0,
            windSpeed: 3.2,
            uvIndex: 5,
            airQuality: 45,
            weatherCondition: .sunny
        )
    }

    /// 다양한 날씨 상태 샘플
    static var previews: [WeatherInfo] {
        [
            WeatherInfo(
                temperature: 22.5,
                humidity: 60,
                precipitation: 0,
                windSpeed: 3.2,
                uvIndex: 5,
                airQuality: 45,
                weatherCondition: .sunny
            ),
            WeatherInfo(
                temperature: 8.0,
                humidity: 75,
                precipitation: 0,
                windSpeed: 5.0,
                uvIndex: 2,
                airQuality: 30,
                weatherCondition: .cloudy
            ),
            WeatherInfo(
                temperature: 15.0,
                humidity: 85,
                precipitation: 10.5,
                windSpeed: 7.0,
                uvIndex: 1,
                airQuality: 55,
                weatherCondition: .rainy
            )
        ]
    }
}
