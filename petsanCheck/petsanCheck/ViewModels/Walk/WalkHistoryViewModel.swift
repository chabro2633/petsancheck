//
//  WalkHistoryViewModel.swift
//  petsanCheck
//
//  Created on 2025-11-29.
//

import Foundation
import Combine

/// 산책 기록 조회 ViewModel
@MainActor
class WalkHistoryViewModel: ObservableObject {
    @Published var walkRecords: [WalkSession] = []
    @Published var weeklyRecords: [WalkSession] = []
    @Published var selectedDogId: UUID?

    /// 이번 주 시작일 (월요일)
    @Published var weekStartDate: Date = Date()
    /// 이번 주 종료일 (일요일)
    @Published var weekEndDate: Date = Date()

    private let coreDataService = CoreDataService.shared
    private let calendar: Calendar = {
        var cal = Calendar.current
        cal.locale = Locale(identifier: "ko_KR")
        cal.firstWeekday = 2  // 월요일 시작
        return cal
    }()

    init() {
        calculateWeekDates()
        loadWalkRecords()
    }

    /// 이번 주 날짜 계산 (월~일)
    private func calculateWeekDates() {
        let today = Date()

        // 이번 주 월요일 찾기
        var startOfWeek = today
        var interval: TimeInterval = 0
        _ = calendar.dateInterval(of: .weekOfYear, start: &startOfWeek, interval: &interval, for: today)

        // 월요일 00:00:00
        weekStartDate = calendar.startOfDay(for: startOfWeek)

        // 일요일 23:59:59
        if let endOfWeek = calendar.date(byAdding: .day, value: 6, to: weekStartDate) {
            weekEndDate = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: endOfWeek) ?? endOfWeek
        }
    }

    /// 산책 기록 로드
    func loadWalkRecords() {
        var allRecords: [WalkSession]

        if let dogId = selectedDogId {
            allRecords = coreDataService.fetchWalkRecords(for: dogId)
        } else {
            allRecords = coreDataService.fetchAllWalkRecords()
        }

        walkRecords = allRecords

        // 이번 주 기록만 필터링
        weeklyRecords = allRecords.filter { record in
            record.startTime >= weekStartDate && record.startTime <= weekEndDate
        }
    }

    /// 반려견별 필터링
    func filterByDog(_ dogId: UUID?) {
        selectedDogId = dogId
        loadWalkRecords()
    }

    /// 산책 기록 삭제
    func deleteRecord(_ session: WalkSession) {
        coreDataService.deleteWalkRecord(session.id)
        loadWalkRecords()
    }

    // MARK: - 이번 주 통계

    /// 이번 주 산책 횟수
    var weeklyWalkCount: Int {
        weeklyRecords.count
    }

    /// 이번 주 산책 거리 (km)
    var weeklyDistance: Double {
        weeklyRecords.reduce(0) { $0 + $1.totalDistance } / 1000
    }

    /// 이번 주 산책 시간 (시간)
    var weeklyDuration: Double {
        weeklyRecords.reduce(0) { $0 + $1.duration } / 3600
    }

    /// 이번 주 평균 산책 거리 (km)
    var weeklyAverageDistance: Double {
        guard !weeklyRecords.isEmpty else { return 0 }
        return weeklyDistance / Double(weeklyRecords.count)
    }

    /// 요일별 산책 기록
    var dailyRecords: [Int: [WalkSession]] {
        var result: [Int: [WalkSession]] = [:]
        for day in 1...7 {
            result[day] = []
        }

        for record in weeklyRecords {
            // 요일 (월=1, 화=2, ..., 일=7)
            var weekday = calendar.component(.weekday, from: record.startTime)
            // Calendar의 weekday는 일=1, 월=2, ..., 토=7이므로 변환
            weekday = weekday == 1 ? 7 : weekday - 1
            result[weekday, default: []].append(record)
        }

        return result
    }

    /// 요일 이름
    func dayName(for day: Int) -> String {
        let names = ["", "월", "화", "수", "목", "금", "토", "일"]
        return names[day]
    }

    /// 해당 요일의 날짜
    func dateFor(day: Int) -> Date? {
        return calendar.date(byAdding: .day, value: day - 1, to: weekStartDate)
    }

    /// 해당 요일이 오늘인지
    func isToday(day: Int) -> Bool {
        guard let date = dateFor(day: day) else { return false }
        return calendar.isDateInToday(date)
    }

    /// 해당 요일이 미래인지
    func isFuture(day: Int) -> Bool {
        guard let date = dateFor(day: day) else { return false }
        return date > Date()
    }

    /// 요일별 산책 거리 (km)
    func distanceFor(day: Int) -> Double {
        let records = dailyRecords[day] ?? []
        return records.reduce(0) { $0 + $1.totalDistance } / 1000
    }

    /// 주간 날짜 범위 텍스트
    var weekRangeText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일"

        let start = formatter.string(from: weekStartDate)
        let end = formatter.string(from: weekEndDate)
        return "\(start) ~ \(end)"
    }

    // MARK: - 전체 통계 (기존 호환성 유지)

    /// 총 산책 횟수
    var totalWalkCount: Int {
        walkRecords.count
    }

    /// 총 산책 거리 (km)
    var totalDistance: Double {
        walkRecords.reduce(0) { $0 + $1.totalDistance } / 1000
    }

    /// 총 산책 시간 (시간)
    var totalDuration: Double {
        walkRecords.reduce(0) { $0 + $1.duration } / 3600
    }

    /// 평균 산책 거리 (km)
    var averageDistance: Double {
        guard !walkRecords.isEmpty else { return 0 }
        return totalDistance / Double(walkRecords.count)
    }
}
