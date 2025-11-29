//
//  WeatherEvaluator.swift
//  petsanCheck
//
//  Created on 2025-11-29.
//

import Foundation

/// 날씨 데이터를 평가하여 산책 추천 정보를 생성하는 서비스
struct WeatherEvaluator {

    /// 날씨 정보를 바탕으로 산책 추천 생성
    static func evaluateWalkConditions(weather: WeatherInfo) -> WalkRecommendation {
        // 각 요소별 점수 계산
        let temperatureScore = evaluateTemperature(weather.temperature)
        let humidityScore = evaluateHumidity(weather.humidity)
        let precipitationScore = evaluatePrecipitation(weather.precipitation)
        let windScore = evaluateWind(weather.windSpeed)
        let uvScore = evaluateUV(weather.uvIndex)
        let airQualityScore = evaluateAirQuality(weather.airQuality)

        // 가중 평균으로 총점 계산
        let totalScore = Int(
            temperatureScore * 0.3 +
            humidityScore * 0.15 +
            precipitationScore * 0.25 +
            windScore * 0.1 +
            uvScore * 0.1 +
            airQualityScore * 0.1
        )

        // 경고 메시지 생성
        let warnings = generateWarnings(weather: weather)

        // 추천 의류 생성
        let clothing = recommendClothing(weather: weather)

        // 최적 시간대 추천
        let timeSlots = recommendTimeSlots(weather: weather, score: totalScore)

        // 메시지 생성
        let message = generateMessage(score: totalScore, weather: weather)

        return WalkRecommendation(
            score: totalScore,
            message: message,
            recommendedClothing: clothing,
            warnings: warnings,
            bestTimeSlots: timeSlots
        )
    }

    // MARK: - 개별 요소 평가

    /// 온도 평가 (0-100점)
    private static func evaluateTemperature(_ temp: Double) -> Double {
        switch temp {
        case 15...25:
            return 100.0  // 최적 온도
        case 10..<15, 25..<30:
            return 80.0   // 좋은 온도
        case 5..<10, 30..<32:
            return 60.0   // 보통
        case 0..<5, 32..<35:
            return 40.0   // 나쁨
        default:
            return 20.0   // 위험
        }
    }

    /// 습도 평가 (0-100점)
    private static func evaluateHumidity(_ humidity: Int) -> Double {
        switch humidity {
        case 40...60:
            return 100.0  // 쾌적
        case 30..<40, 60..<70:
            return 80.0   // 좋음
        case 20..<30, 70..<80:
            return 60.0   // 보통
        default:
            return 40.0   // 불쾌
        }
    }

    /// 강수량 평가 (0-100점)
    private static func evaluatePrecipitation(_ precipitation: Double) -> Double {
        switch precipitation {
        case 0:
            return 100.0  // 맑음
        case 0..<1:
            return 80.0   // 약간의 비
        case 1..<5:
            return 50.0   // 비
        case 5..<10:
            return 30.0   // 많은 비
        default:
            return 10.0   // 폭우
        }
    }

    /// 풍속 평가 (0-100점)
    private static func evaluateWind(_ windSpeed: Double) -> Double {
        switch windSpeed {
        case 0..<5:
            return 100.0  // 약한 바람
        case 5..<10:
            return 70.0   // 보통 바람
        case 10..<15:
            return 40.0   // 강한 바람
        default:
            return 20.0   // 매우 강한 바람
        }
    }

    /// 자외선 평가 (0-100점)
    private static func evaluateUV(_ uvIndex: Int) -> Double {
        switch uvIndex {
        case 0...2:
            return 100.0  // 낮음
        case 3...5:
            return 80.0   // 보통
        case 6...7:
            return 60.0   // 높음
        case 8...10:
            return 40.0   // 매우 높음
        default:
            return 20.0   // 위험
        }
    }

    /// 미세먼지 평가 (0-100점)
    private static func evaluateAirQuality(_ airQuality: Int) -> Double {
        switch airQuality {
        case 0...30:
            return 100.0  // 좋음
        case 31...80:
            return 80.0   // 보통
        case 81...150:
            return 50.0   // 나쁨
        default:
            return 20.0   // 매우 나쁨
        }
    }

    // MARK: - 경고 생성

    private static func generateWarnings(weather: WeatherInfo) -> [WalkRecommendation.Warning] {
        var warnings: [WalkRecommendation.Warning] = []

        // 고온 경고
        if weather.temperature > 30 {
            warnings.append(WalkRecommendation.Warning(
                type: .heat,
                message: "폭염 주의! 시원한 시간대에 짧게 산책하세요.",
                severity: weather.temperature > 35 ? .critical : .high
            ))
        }

        // 저온 경고
        if weather.temperature < 5 {
            warnings.append(WalkRecommendation.Warning(
                type: .cold,
                message: "기온이 매우 낮습니다. 따뜻한 옷을 준비하세요.",
                severity: weather.temperature < 0 ? .critical : .high
            ))
        }

        // 강수 경고
        if weather.precipitation > 1 {
            warnings.append(WalkRecommendation.Warning(
                type: .rain,
                message: "비가 오고 있습니다. 레인코트를 착용하세요.",
                severity: weather.precipitation > 10 ? .high : .medium
            ))
        }

        // 강풍 경고
        if weather.windSpeed > 10 {
            warnings.append(WalkRecommendation.Warning(
                type: .wind,
                message: "바람이 강합니다. 실내 활동을 권장합니다.",
                severity: weather.windSpeed > 15 ? .high : .medium
            ))
        }

        // 자외선 경고
        if weather.uvIndex > 7 {
            warnings.append(WalkRecommendation.Warning(
                type: .uv,
                message: "자외선이 강합니다. 그늘진 곳에서 산책하세요.",
                severity: weather.uvIndex > 10 ? .critical : .high
            ))
        }

        // 미세먼지 경고
        if weather.airQuality > 80 {
            warnings.append(WalkRecommendation.Warning(
                type: .air,
                message: "미세먼지가 나쁩니다. 짧게 산책하세요.",
                severity: weather.airQuality > 150 ? .critical : .high
            ))
        }

        return warnings
    }

    // MARK: - 의류 추천

    private static func recommendClothing(weather: WeatherInfo) -> [WalkRecommendation.ClothingItem] {
        var clothing: [WalkRecommendation.ClothingItem] = []

        // 온도별 의류
        if weather.temperature < 10 {
            clothing.append(.warmJacket)
        } else if weather.temperature > 30 {
            clothing.append(.coolingVest)
        } else if weather.temperature < 15 {
            clothing.append(.lightVest)
        }

        // 날씨별 의류
        if weather.precipitation > 0 {
            clothing.append(.raincoat)
            clothing.append(.boots)
        }

        return clothing.isEmpty ? [.none] : clothing
    }

    // MARK: - 시간대 추천

    private static func recommendTimeSlots(weather: WeatherInfo, score: Int) -> [WalkRecommendation.TimeSlot] {
        guard score >= 40 else { return [] }  // 점수가 너무 낮으면 추천 안함

        let calendar = Calendar.current
        let now = Date()
        var timeSlots: [WalkRecommendation.TimeSlot] = []

        // 아침 시간대 (6-9시)
        if let morningStart = calendar.date(bySettingHour: 6, minute: 0, second: 0, of: now),
           let morningEnd = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now) {

            let morningScore = calculateTimeSlotScore(weather: weather, hour: 7)
            timeSlots.append(WalkRecommendation.TimeSlot(
                startTime: morningStart,
                endTime: morningEnd,
                reason: "시원한 아침 공기",
                score: morningScore
            ))
        }

        // 오후 시간대 (15-18시)
        if let afternoonStart = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: now),
           let afternoonEnd = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: now) {

            let afternoonScore = calculateTimeSlotScore(weather: weather, hour: 16)
            timeSlots.append(WalkRecommendation.TimeSlot(
                startTime: afternoonStart,
                endTime: afternoonEnd,
                reason: "따뜻한 오후",
                score: afternoonScore
            ))
        }

        // 저녁 시간대 (18-21시)
        if let eveningStart = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: now),
           let eveningEnd = calendar.date(bySettingHour: 21, minute: 0, second: 0, of: now) {

            let eveningScore = calculateTimeSlotScore(weather: weather, hour: 19)
            timeSlots.append(WalkRecommendation.TimeSlot(
                startTime: eveningStart,
                endTime: eveningEnd,
                reason: "선선한 저녁",
                score: eveningScore
            ))
        }

        // 점수 순으로 정렬하여 상위 2개만 반환
        return timeSlots.sorted { $0.score > $1.score }.prefix(2).map { $0 }
    }

    private static func calculateTimeSlotScore(weather: WeatherInfo, hour: Int) -> Int {
        var score = 70  // 기본 점수

        // 여름철 아침/저녁 가점
        if weather.temperature > 25 && (hour < 9 || hour > 18) {
            score += 15
        }

        // 겨울철 오후 가점
        if weather.temperature < 15 && hour >= 12 && hour <= 16 {
            score += 15
        }

        // 자외선 높을 때 아침/저녁 가점
        if weather.uvIndex > 7 && (hour < 10 || hour > 17) {
            score += 10
        }

        return min(100, score)
    }

    // MARK: - 메시지 생성

    private static func generateMessage(score: Int, weather: WeatherInfo) -> String {
        let level = WalkRecommendation.RecommendationLevel.from(score: score)

        switch level {
        case .excellent:
            return "오늘은 산책하기 완벽한 날씨입니다!"
        case .good:
            return "산책하기 좋은 날씨네요!"
        case .moderate:
            if weather.temperature > 28 {
                return "더운 날씨니까 짧게 산책하세요."
            } else if weather.temperature < 10 {
                return "쌀쌀한 날씨니까 따뜻하게 입으세요."
            } else {
                return "산책할 수 있지만 주의가 필요해요."
            }
        case .poor:
            return "산책을 짧게 하거나 미루는 것이 좋겠어요."
        case .dangerous:
            return "오늘은 실내에서 놀아주는 것이 안전해요."
        }
    }
}
