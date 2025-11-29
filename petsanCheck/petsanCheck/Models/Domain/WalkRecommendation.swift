//
//  WalkRecommendation.swift
//  petsanCheck
//
//  Created on 2025-11-29.
//

import Foundation

/// 산책 추천 정보
struct WalkRecommendation: Codable {
    let score: Int                          // 0-100
    let level: RecommendationLevel
    let message: String
    let recommendedClothing: [ClothingItem]
    let warnings: [Warning]
    let bestTimeSlots: [TimeSlot]

    /// 추천 등급
    enum RecommendationLevel: String, Codable {
        case excellent = "최고"
        case good = "좋음"
        case moderate = "보통"
        case poor = "나쁨"
        case dangerous = "위험"

        var color: String {
            switch self {
            case .excellent: return "green"
            case .good: return "blue"
            case .moderate: return "yellow"
            case .poor: return "orange"
            case .dangerous: return "red"
            }
        }

        var icon: String {
            switch self {
            case .excellent: return "star.fill"
            case .good: return "hand.thumbsup.fill"
            case .moderate: return "minus.circle.fill"
            case .poor: return "hand.thumbsdown.fill"
            case .dangerous: return "exclamationmark.triangle.fill"
            }
        }

        static func from(score: Int) -> RecommendationLevel {
            switch score {
            case 80...100: return .excellent
            case 60..<80: return .good
            case 40..<60: return .moderate
            case 20..<40: return .poor
            default: return .dangerous
            }
        }
    }

    /// 추천 의류
    enum ClothingItem: String, Codable {
        case none = "특별 의류 불필요"
        case lightVest = "가벼운 조끼"
        case warmJacket = "따뜻한 외투"
        case raincoat = "레인코트"
        case boots = "신발"
        case coolingVest = "쿨링 조끼"

        var icon: String {
            switch self {
            case .none: return "checkmark.circle"
            case .lightVest: return "tshirt"
            case .warmJacket: return "hands.and.sparkles"
            case .raincoat: return "umbrella"
            case .boots: return "shoe"
            case .coolingVest: return "snowflake"
            }
        }
    }

    /// 경고 정보
    struct Warning: Codable {
        let type: WarningType
        let message: String
        let severity: Severity

        enum WarningType: String, Codable {
            case heat = "고온"
            case cold = "저온"
            case uv = "자외선"
            case air = "미세먼지"
            case rain = "강우"
            case wind = "강풍"
            case humidity = "습도"

            var icon: String {
                switch self {
                case .heat: return "sun.max.fill"
                case .cold: return "snowflake"
                case .uv: return "sun.and.horizon.fill"
                case .air: return "aqi.medium"
                case .rain: return "cloud.rain.fill"
                case .wind: return "wind"
                case .humidity: return "humidity.fill"
                }
            }
        }

        enum Severity: String, Codable {
            case low = "낮음"
            case medium = "보통"
            case high = "높음"
            case critical = "매우높음"

            var color: String {
                switch self {
                case .low: return "yellow"
                case .medium: return "orange"
                case .high: return "red"
                case .critical: return "purple"
                }
            }
        }
    }

    /// 추천 시간대
    struct TimeSlot: Codable, Identifiable {
        let id: UUID
        let startTime: Date
        let endTime: Date
        let reason: String
        let score: Int

        init(
            id: UUID = UUID(),
            startTime: Date,
            endTime: Date,
            reason: String,
            score: Int
        ) {
            self.id = id
            self.startTime = startTime
            self.endTime = endTime
            self.reason = reason
            self.score = score
        }

        var displayTimeRange: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "a h:mm"
            formatter.locale = Locale(identifier: "ko_KR")
            return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
        }
    }

    /// 개별 강아지 이름을 포함한 메시지
    func personalizedMessage(for dogName: String) -> String {
        switch level {
        case .excellent:
            return "\(dogName)와 산책하기 완벽한 날씨예요!"
        case .good:
            return "\(dogName)와 함께 산책하기 좋아요!"
        case .moderate:
            return "\(dogName)와 산책할 수 있지만 주의가 필요해요."
        case .poor:
            return "\(dogName)와의 산책은 짧게 하는 것이 좋아요."
        case .dangerous:
            return "\(dogName)의 안전을 위해 실내에서 놀아주세요!"
        }
    }

    /// 상세 메시지 생성
    var detailedMessage: String {
        var details = [message]

        if !warnings.isEmpty {
            let warningMessages = warnings.map { $0.message }
            details.append(contentsOf: warningMessages)
        }

        if !recommendedClothing.isEmpty && recommendedClothing != [.none] {
            let clothingList = recommendedClothing.map { $0.rawValue }.joined(separator: ", ")
            details.append("추천 의류: \(clothingList)")
        }

        return details.joined(separator: "\n")
    }

    /// 완전한 초기화
    init(
        score: Int,
        level: RecommendationLevel,
        message: String,
        recommendedClothing: [ClothingItem] = [],
        warnings: [Warning] = [],
        bestTimeSlots: [TimeSlot] = []
    ) {
        self.score = max(0, min(100, score))
        self.level = level
        self.message = message
        self.recommendedClothing = recommendedClothing
        self.warnings = warnings
        self.bestTimeSlots = bestTimeSlots
    }

    /// 편의 초기화 (level 자동 계산)
    init(
        score: Int,
        message: String,
        recommendedClothing: [ClothingItem] = [],
        warnings: [Warning] = [],
        bestTimeSlots: [TimeSlot] = []
    ) {
        self.init(
            score: score,
            level: RecommendationLevel.from(score: score),
            message: message,
            recommendedClothing: recommendedClothing,
            warnings: warnings,
            bestTimeSlots: bestTimeSlots
        )
    }
}

// MARK: - Preview Helper
extension WalkRecommendation {
    static var preview: WalkRecommendation {
        let calendar = Calendar.current
        let now = Date()

        // 안전하게 날짜 생성
        let morningStart = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now) ?? now
        let morningEnd = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: now) ?? now
        let eveningStart = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: now) ?? now
        let eveningEnd = calendar.date(bySettingHour: 19, minute: 0, second: 0, of: now) ?? now

        return WalkRecommendation(
            score: 85,
            level: .excellent,
            message: "산책하기 완벽한 날씨입니다!",
            recommendedClothing: [.none],
            warnings: [],
            bestTimeSlots: [
                TimeSlot(
                    startTime: morningStart,
                    endTime: morningEnd,
                    reason: "선선한 아침 날씨",
                    score: 90
                ),
                TimeSlot(
                    startTime: eveningStart,
                    endTime: eveningEnd,
                    reason: "쾌적한 저녁",
                    score: 85
                )
            ]
        )
    }

    static var previews: [WalkRecommendation] {
        [
            WalkRecommendation(
                score: 90,
                message: "산책하기 최고예요!",
                recommendedClothing: [.none]
            ),
            WalkRecommendation(
                score: 60,
                message: "괜찮은 날씨",
                recommendedClothing: [.warmJacket],
                warnings: [
                    Warning(type: .cold, message: "아침엔 쌀쌀하니 외투를 챙기세요", severity: .medium)
                ]
            ),
            WalkRecommendation(
                score: 15,
                message: "산책을 자제하세요",
                recommendedClothing: [],
                warnings: [
                    Warning(type: .heat, message: "폭염 주의보 발령 중입니다", severity: .critical),
                    Warning(type: .uv, message: "자외선 지수가 매우 높습니다", severity: .high)
                ]
            )
        ]
    }
}
