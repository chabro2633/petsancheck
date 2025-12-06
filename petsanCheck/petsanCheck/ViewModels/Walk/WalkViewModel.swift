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
    @Published var showBackgroundPermissionAlert = false  // "항상" 권한 유도 알럿
    @Published var selectedDogId: UUID?
    @Published var selectedDogName: String?
    @Published var showCompletionPopup = false
    @Published var completedWalkStats: WalkStats?
    @Published var completedDogName: String?

    // 백그라운드 권한 알럿 후 산책 시작을 위한 임시 저장
    private var pendingDog: Dog?

    private let locationManager: LocationManager
    private var cancellables = Set<AnyCancellable>()
    private var timer: Timer?
    private var elapsedTimeBeforePause: TimeInterval = 0
    private var lastResumeTime: Date?

    /// 산책 경로 위치들
    var routeLocations: [WalkLocation] {
        currentSession?.locations ?? []
    }

    private init() {
        self.locationManager = LocationManager()

        // LocationManager의 변경사항 구독
        setupBindings()
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

        // "항상" 권한이 아니면 백그라운드 권한 유도 알럿 표시
        if locationManager.authorizationStatus != .authorizedAlways {
            pendingDog = dog
            showBackgroundPermissionAlert = true
            return
        }

        // 실제 산책 시작
        performStartWalk(weatherInfo: weatherInfo, dog: dog)
    }

    /// 백그라운드 권한 없이 산책 시작 (사용자가 "나중에" 선택 시)
    func startWalkWithoutBackgroundPermission() {
        performStartWalk(weatherInfo: nil, dog: pendingDog)
        pendingDog = nil
    }

    /// 실제 산책 시작 로직
    private func performStartWalk(weatherInfo: WeatherInfo? = nil, dog: Dog? = nil) {
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

    /// 백그라운드 권한 알럿 취소
    func cancelBackgroundPermissionAlert() {
        pendingDog = nil
        showBackgroundPermissionAlert = false
    }

    /// 산책 종료
    func stopWalk() {
        guard var session = currentSession else { return }

        // 종료 시간 설정
        session.endTime = Date()
        currentSession = session

        // 완료 팝업을 위한 데이터 저장
        completedWalkStats = currentStats
        completedDogName = selectedDogName

        // 위치 추적 중지
        locationManager.stopTracking()

        // 타이머 중지
        stopTimer()

        // 세션을 CoreData에 저장
        CoreDataService.shared.createWalkRecord(session, dogId: selectedDogId)

        // Firebase에 누적 통계 업로드
        syncStatsToFirebase()

        // 세션 초기화
        currentSession = nil
        isPaused = false
        elapsedTimeBeforePause = 0
        lastResumeTime = nil
        selectedDogId = nil
        selectedDogName = nil

        // 완료 팝업 표시
        showCompletionPopup = true
    }

    /// Firebase에 누적 통계 동기화
    private func syncStatsToFirebase() {
        let coreDataService = CoreDataService.shared
        let walkRecords = coreDataService.fetchAllWalkRecords()

        let totalDistance = walkRecords.reduce(into: 0.0) { $0 += $1.totalDistance }
        let totalWalkCount = walkRecords.count
        let totalDuration = walkRecords.reduce(into: 0.0) { $0 += $1.duration }

        // 반려견 정보 가져오기
        guard let dog = coreDataService.fetchAllDogs().first else { return }

        Task {
            do {
                try await FirebaseService.shared.saveUserStats(
                    userName: "나",
                    petName: dog.name,
                    petBreed: dog.breed,
                    totalDistance: totalDistance,
                    totalWalkCount: totalWalkCount,
                    totalDuration: totalDuration,
                    profileImageData: dog.profileImageData
                )
                print("[Walk] Firebase 통계 동기화 완료 - 총 거리: \(totalDistance)m, 횟수: \(totalWalkCount)")
            } catch {
                print("[Walk] Firebase 동기화 실패: \(error.localizedDescription)")
            }
        }
    }

    /// 완료 팝업 닫기
    func dismissCompletionPopup() {
        showCompletionPopup = false
        completedWalkStats = nil
        completedDogName = nil
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
        print("[WalkViewModel] requestLocationUpdate 호출 - 권한: \(locationManager.authorizationStatus.rawValue)")

        // 권한 확인
        if locationManager.authorizationStatus == .notDetermined {
            print("[WalkViewModel] 권한 미결정 - 권한 요청")
            locationManager.requestPermission()
            // 권한 요청 후 대기 (최대 2초)
            for _ in 0..<20 {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1초
                if locationManager.authorizationStatus != .notDetermined {
                    break
                }
            }
        }

        // 위치 업데이트 시작 (추적 중이 아닐 때만)
        if !isTracking && (locationManager.authorizationStatus == .authorizedWhenInUse ||
                           locationManager.authorizationStatus == .authorizedAlways) {
            print("[WalkViewModel] 위치 업데이트 시작 요청")
            locationManager.startQuickLocationFetch()

            // 위치가 업데이트될 때까지 최대 3초 대기
            for _ in 0..<30 {
                if locationManager.location != nil {
                    print("[WalkViewModel] 위치 확보됨!")
                    break
                }
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1초
            }
        } else {
            print("[WalkViewModel] 위치 업데이트 건너뜀 - isTracking: \(isTracking), 권한: \(locationManager.authorizationStatus.rawValue)")
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
