//
//  WalkViewModel.swift
//  petsanCheck
//
//  Created on 2025-11-29.
//

import Foundation
import CoreLocation
import Combine

/// 산책 기능을 관리하는 ViewModel (싱글톤으로 앱 전역에서 상태 유지)
@MainActor
class WalkViewModel: ObservableObject {
    /// 싱글톤 인스턴스
    static let shared = WalkViewModel()

    @Published var currentSession: WalkSession?
    @Published var isTracking = false
    @Published var isPaused = false
    @Published var showPermissionAlert = false
    @Published var selectedDogId: UUID?
    @Published var selectedDogName: String?

    private let locationManager: LocationManager
    private var cancellables = Set<AnyCancellable>()
    private var timer: Timer?
    private var elapsedTimeBeforePause: TimeInterval = 0
    private var lastResumeTime: Date?

    /// 산책 경로 위치들
    var routeLocations: [WalkLocation] {
        currentSession?.locations ?? []
    }

    private init(locationManager: LocationManager) {
        self.locationManager = locationManager

        // LocationManager의 변경사항 구독
        setupBindings()
    }

    private convenience init() {
        self.init(locationManager: LocationManager())
    }

    deinit {
        // Timer 메모리 누수 방지
        timer?.invalidate()
        timer = nil
        cancellables.removeAll()
    }

    private func setupBindings() {
        // 위치 업데이트 구독 - 실시간 현재 위치 표시용
        locationManager.$location
            .compactMap { $0 }
            .sink { [weak self] location in
                self?.handleLocationUpdate(location)
            }
            .store(in: &cancellables)

        // 경로 위치 업데이트 구독 - 필터링된 경로 데이터
        locationManager.$trackingLocations
            .sink { [weak self] locations in
                self?.handleTrackingLocationsUpdate(locations)
            }
            .store(in: &cancellables)

        // 추적 상태 구독
        locationManager.$isTracking
            .assign(to: &$isTracking)

        // 권한 상태 구독
        locationManager.$authorizationStatus
            .sink { [weak self] status in
                if status == .denied || status == .restricted {
                    self?.showPermissionAlert = true
                    self?.stopWalk()
                }
            }
            .store(in: &cancellables)
    }

    /// 산책 시작
    func startWalk(weatherInfo: WeatherInfo? = nil, dog: Dog? = nil) {
        // 권한 확인
        guard locationManager.authorizationStatus == .authorizedWhenInUse ||
              locationManager.authorizationStatus == .authorizedAlways else {
            locationManager.requestPermission()
            showPermissionAlert = true
            return
        }

        // 선택된 반려견 저장
        selectedDogId = dog?.id
        selectedDogName = dog?.name

        // 새 세션 생성
        currentSession = WalkSession(
            startTime: Date(),
            weatherAtStart: weatherInfo
        )

        // 타이머 관련 초기화
        elapsedTimeBeforePause = 0
        lastResumeTime = Date()
        isPaused = false

        // 위치 추적 시작
        locationManager.startTracking()

        // 타이머 시작
        startTimer()
    }

    /// 산책 종료
    func stopWalk() {
        guard var session = currentSession else { return }

        // 종료 시간 설정
        session.endTime = Date()
        currentSession = session

        // 위치 추적 중지
        locationManager.stopTracking()

        // 타이머 중지
        stopTimer()

        // 세션을 CoreData에 저장
        CoreDataService.shared.createWalkRecord(session, dogId: selectedDogId)

        // 세션 초기화
        currentSession = nil
        isPaused = false
        elapsedTimeBeforePause = 0
        lastResumeTime = nil
        selectedDogId = nil
        selectedDogName = nil
    }

    /// 산책 일시정지
    func pauseWalk() {
        guard isTracking, !isPaused else { return }

        isPaused = true

        // 현재까지의 시간 저장
        if let resumeTime = lastResumeTime {
            elapsedTimeBeforePause += Date().timeIntervalSince(resumeTime)
        }

        locationManager.stopUpdatingLocation()
        stopTimer()
    }

    /// 산책 재개
    func resumeWalk() {
        guard isTracking, isPaused else { return }

        isPaused = false
        lastResumeTime = Date()

        locationManager.startUpdatingLocation()
        startTimer()
    }

    /// 타이머 시작
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.objectWillChange.send()
            }
        }
    }

    /// 타이머 중지
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    /// 실제 산책 시간 (일시정지 시간 제외)
    var actualDuration: TimeInterval {
        var total = elapsedTimeBeforePause
        if !isPaused, let resumeTime = lastResumeTime {
            total += Date().timeIntervalSince(resumeTime)
        }
        return total
    }

    /// 현재 위치 업데이트 처리 (UI 업데이트용)
    private func handleLocationUpdate(_ location: CLLocation) {
        // 현재 위치가 업데이트되면 UI 갱신
        objectWillChange.send()
    }

    /// 경로 위치 업데이트 처리 (LocationManager에서 필터링된 위치)
    private func handleTrackingLocationsUpdate(_ locations: [CLLocation]) {
        guard var session = currentSession, isTracking, !isPaused else { return }

        // LocationManager에서 필터링된 위치를 세션에 동기화
        let walkLocations = locations.map { WalkLocation(from: $0) }
        session.locations = walkLocations
        currentSession = session
    }

    /// 현재 세션의 통계
    var currentStats: WalkStats {
        guard let session = currentSession else {
            return WalkStats(
                distance: 0,
                duration: 0,
                averageSpeed: 0,
                calories: 0
            )
        }

        let duration = actualDuration
        let distance = session.totalDistance
        let speed = duration > 0 ? (distance / 1000) / (duration / 3600) : 0
        let calories = Int(distance / 1000 * 50) // 간단한 칼로리 계산

        return WalkStats(
            distance: distance,
            duration: duration,
            averageSpeed: speed,
            calories: calories
        )
    }

    /// 현재 위치
    var currentLocation: CLLocation? {
        locationManager.location
    }

    /// 위치 권한 요청 및 위치 업데이트 시작
    func requestLocationUpdate() async {
        // 권한 확인
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestPermission()
            // 권한 요청 후 잠시 대기
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5초
        }

        // 위치 업데이트 시작 (추적 중이 아닐 때만)
        if !isTracking && (locationManager.authorizationStatus == .authorizedWhenInUse ||
                           locationManager.authorizationStatus == .authorizedAlways) {
            locationManager.startQuickLocationFetch()
        }
    }

    /// 위치를 찾는 중인지
    var isLocating: Bool {
        locationManager.isLocating
    }
}

/// 산책 통계 정보
struct WalkStats {
    let distance: Double // 미터
    let duration: TimeInterval // 초
    let averageSpeed: Double // km/h
    let calories: Int

    var distanceText: String {
        if distance < 1000 {
            return String(format: "%.0fm", distance)
        } else {
            return String(format: "%.2fkm", distance / 1000)
        }
    }

    var durationText: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    var speedText: String {
        String(format: "%.1f km/h", averageSpeed)
    }

    var caloriesText: String {
        "\(calories) kcal"
    }
}
