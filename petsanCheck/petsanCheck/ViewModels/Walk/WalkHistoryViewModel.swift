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
    @Published var selectedDogId: UUID?

    private let coreDataService = CoreDataService.shared

    init() {
        loadWalkRecords()
    }

    /// 산책 기록 로드
    func loadWalkRecords() {
        if let dogId = selectedDogId {
            walkRecords = coreDataService.fetchWalkRecords(for: dogId)
        } else {
            walkRecords = coreDataService.fetchAllWalkRecords()
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
