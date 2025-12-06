//
//  FirebaseService.swift
//  petsanCheck
//
//  Created on 2025-12-06.
//

import Foundation
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
import CoreLocation

/// Firebase 연동을 담당하는 서비스
class FirebaseService {
    static let shared = FirebaseService()

    private var db: Firestore!
    private var currentUserId: String?
    private var isConfigured = false

    private init() {}

    // MARK: - 초기화

    /// Firebase 초기화 (앱 시작 시 호출)
    func configure() {
        guard !isConfigured else { return }

        FirebaseApp.configure()
        db = Firestore.firestore()
        isConfigured = true
        print("[Firebase] 초기화 완료")

        // 익명 인증으로 사용자 생성
        signInAnonymously()
    }

    /// 익명 로그인 (기기별 고유 사용자)
    private func signInAnonymously() {
        // 이미 로그인된 사용자가 있으면 사용
        if let user = Auth.auth().currentUser {
            self.currentUserId = user.uid
            print("[Firebase] 기존 사용자: \(user.uid)")
            return
        }

        Auth.auth().signInAnonymously { [weak self] result, error in
            if let error = error {
                print("[Firebase] 익명 로그인 실패: \(error.localizedDescription)")
                return
            }

            if let user = result?.user {
                self?.currentUserId = user.uid
                print("[Firebase] 익명 로그인 성공: \(user.uid)")
            }
        }
    }

    /// 현재 사용자 ID
    var userId: String? {
        return currentUserId ?? Auth.auth().currentUser?.uid
    }

    // MARK: - 사용자 통계 저장/조회

    /// 사용자 통계 저장 (산책 완료 시 호출)
    func saveUserStats(
        userName: String,
        petName: String,
        petBreed: String,
        totalDistance: Double,
        totalWalkCount: Int,
        totalDuration: TimeInterval,
        profileImageData: Data? = nil,
        location: CLLocation? = nil,
        kakaoId: String? = nil
    ) async throws {
        guard isConfigured else {
            throw FirebaseError.notConfigured
        }
        guard let userId = userId else {
            throw FirebaseError.notAuthenticated
        }

        var data: [String: Any] = [
            "userId": userId,
            "userName": userName,
            "petName": petName,
            "petBreed": petBreed,
            "totalDistance": totalDistance,
            "totalWalkCount": totalWalkCount,
            "totalDuration": totalDuration,
            "updatedAt": FieldValue.serverTimestamp()
        ]

        // 위치 정보 저장 (GeoHash 사용)
        if let location = location {
            data["latitude"] = location.coordinate.latitude
            data["longitude"] = location.coordinate.longitude
            data["geohash"] = GeoHashHelper.encode(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                precision: 5  // ~5km 정밀도
            )
        }

        // 카카오 ID 저장 (친구 랭킹용)
        if let kakaoId = kakaoId {
            data["kakaoId"] = kakaoId
        }

        // 프로필 이미지가 있으면 Base64로 저장 (작은 이미지만)
        if let imageData = profileImageData, imageData.count < 100000 {
            data["profileImageBase64"] = imageData.base64EncodedString()
        }

        try await db.collection("users").document(userId).setData(data, merge: true)
        print("[Firebase] 사용자 통계 저장 완료")
    }

    /// 카카오 ID 연동 (별도 저장)
    func linkKakaoId(_ kakaoId: String) async throws {
        guard isConfigured else {
            throw FirebaseError.notConfigured
        }
        guard let userId = userId else {
            throw FirebaseError.notAuthenticated
        }

        try await db.collection("users").document(userId).setData([
            "kakaoId": kakaoId,
            "updatedAt": FieldValue.serverTimestamp()
        ], merge: true)
        print("[Firebase] 카카오 ID 연동 완료: \(kakaoId)")
    }

    /// 전체 랭킹 조회 (상위 N명)
    func fetchRankings(type: RankingType, limit: Int = 50) async throws -> [RankingUser] {
        guard isConfigured else {
            throw FirebaseError.notConfigured
        }

        let sortField: String
        switch type {
        case .distance:
            sortField = "totalDistance"
        case .walkCount:
            sortField = "totalWalkCount"
        case .duration:
            sortField = "totalDuration"
        }

        let snapshot = try await db.collection("users")
            .order(by: sortField, descending: true)
            .limit(to: limit)
            .getDocuments()

        var rankings: [RankingUser] = []

        for (index, document) in snapshot.documents.enumerated() {
            let data = document.data()

            // 프로필 이미지 디코딩
            var profileImageData: Data? = nil
            if let base64String = data["profileImageBase64"] as? String {
                profileImageData = Data(base64Encoded: base64String)
            }

            let user = RankingUser(
                id: UUID(),
                name: data["userName"] as? String ?? "익명",
                petName: data["petName"] as? String ?? "반려동물",
                petBreed: data["petBreed"] as? String ?? "",
                profileImageData: profileImageData,
                totalDistance: data["totalDistance"] as? Double ?? 0,
                totalWalkCount: data["totalWalkCount"] as? Int ?? 0,
                totalDuration: data["totalDuration"] as? TimeInterval ?? 0,
                badges: [],  // 뱃지는 로컬에서 계산
                rank: index + 1,
                isCurrentUser: document.documentID == userId
            )
            rankings.append(user)
        }

        print("[Firebase] 랭킹 조회 완료: \(rankings.count)명")
        return rankings
    }

    /// 내 순위 조회
    func fetchMyRank(type: RankingType) async throws -> Int? {
        guard isConfigured else { return nil }
        guard let userId = userId else { return nil }

        // 내 통계 조회
        let myDoc = try await db.collection("users").document(userId).getDocument()
        guard let myData = myDoc.data() else { return nil }

        let sortField: String
        let myValue: Double

        switch type {
        case .distance:
            sortField = "totalDistance"
            myValue = myData["totalDistance"] as? Double ?? 0
        case .walkCount:
            sortField = "totalWalkCount"
            myValue = Double(myData["totalWalkCount"] as? Int ?? 0)
        case .duration:
            sortField = "totalDuration"
            myValue = myData["totalDuration"] as? Double ?? 0
        }

        // 나보다 높은 사람 수 카운트
        let higherCount = try await db.collection("users")
            .whereField(sortField, isGreaterThan: myValue)
            .count
            .getAggregation(source: .server)

        return Int(truncating: higherCount.count) + 1
    }

    /// 내 통계 조회
    func fetchMyStats() async throws -> (distance: Double, walkCount: Int, duration: TimeInterval)? {
        guard isConfigured else { return nil }
        guard let userId = userId else { return nil }

        let document = try await db.collection("users").document(userId).getDocument()
        guard let data = document.data() else { return nil }

        return (
            distance: data["totalDistance"] as? Double ?? 0,
            walkCount: data["totalWalkCount"] as? Int ?? 0,
            duration: data["totalDuration"] as? TimeInterval ?? 0
        )
    }

    /// 위치 기반 랭킹 조회 (근처 사용자들)
    func fetchNearbyRankings(
        type: RankingType,
        location: CLLocation,
        radiusKm: Double = 5.0,
        limit: Int = 50
    ) async throws -> [RankingUser] {
        guard isConfigured else {
            throw FirebaseError.notConfigured
        }

        let sortField: String
        switch type {
        case .distance:
            sortField = "totalDistance"
        case .walkCount:
            sortField = "totalWalkCount"
        case .duration:
            sortField = "totalDuration"
        }

        // GeoHash 범위 계산
        let geohashRanges = GeoHashHelper.queryBounds(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            radiusKm: radiusKm
        )

        var allUsers: [RankingUser] = []

        // 각 GeoHash 범위에서 사용자 조회
        for range in geohashRanges {
            let snapshot = try await db.collection("users")
                .whereField("geohash", isGreaterThanOrEqualTo: range.start)
                .whereField("geohash", isLessThanOrEqualTo: range.end)
                .getDocuments()

            for document in snapshot.documents {
                let data = document.data()

                // 실제 거리 계산으로 필터링
                if let lat = data["latitude"] as? Double,
                   let lng = data["longitude"] as? Double {
                    let userLocation = CLLocation(latitude: lat, longitude: lng)
                    let distanceFromMe = location.distance(from: userLocation) / 1000  // km로 변환

                    if distanceFromMe <= radiusKm {
                        var profileImageData: Data? = nil
                        if let base64String = data["profileImageBase64"] as? String {
                            profileImageData = Data(base64Encoded: base64String)
                        }

                        let user = RankingUser(
                            id: UUID(),
                            name: data["userName"] as? String ?? "익명",
                            petName: data["petName"] as? String ?? "반려동물",
                            petBreed: data["petBreed"] as? String ?? "",
                            profileImageData: profileImageData,
                            totalDistance: data["totalDistance"] as? Double ?? 0,
                            totalWalkCount: data["totalWalkCount"] as? Int ?? 0,
                            totalDuration: data["totalDuration"] as? TimeInterval ?? 0,
                            badges: [],
                            rank: 0,
                            isCurrentUser: document.documentID == userId
                        )
                        allUsers.append(user)
                    }
                }
            }
        }

        // 중복 제거 및 정렬
        var uniqueUsers: [String: RankingUser] = [:]
        for user in allUsers {
            uniqueUsers[user.id.uuidString] = user
        }

        var sortedUsers = Array(uniqueUsers.values)
        switch type {
        case .distance:
            sortedUsers.sort { $0.totalDistance > $1.totalDistance }
        case .walkCount:
            sortedUsers.sort { $0.totalWalkCount > $1.totalWalkCount }
        case .duration:
            sortedUsers.sort { $0.totalDuration > $1.totalDuration }
        }

        // 순위 할당
        let rankedUsers = sortedUsers.prefix(limit).enumerated().map { index, user in
            RankingUser(
                id: user.id,
                name: user.name,
                petName: user.petName,
                petBreed: user.petBreed,
                profileImageData: user.profileImageData,
                totalDistance: user.totalDistance,
                totalWalkCount: user.totalWalkCount,
                totalDuration: user.totalDuration,
                badges: user.badges,
                rank: index + 1,
                isCurrentUser: user.isCurrentUser
            )
        }

        print("[Firebase] 근처 랭킹 조회 완료: \(rankedUsers.count)명 (반경 \(radiusKm)km)")
        return Array(rankedUsers)
    }

    /// 친구 기반 랭킹 조회 (카카오 친구 ID로 필터)
    func fetchFriendsRankings(
        type: RankingType,
        kakaoFriendIds: [String],
        limit: Int = 50
    ) async throws -> [RankingUser] {
        guard isConfigured else {
            throw FirebaseError.notConfigured
        }

        // Firestore는 whereIn 쿼리가 최대 10개까지만 지원
        // 친구가 10명 이상이면 여러 번 쿼리해야 함
        let chunks = kakaoFriendIds.chunked(into: 10)
        var allUsers: [RankingUser] = []

        for chunk in chunks {
            let snapshot = try await db.collection("users")
                .whereField("kakaoId", in: chunk)
                .getDocuments()

            for document in snapshot.documents {
                let data = document.data()

                var profileImageData: Data? = nil
                if let base64String = data["profileImageBase64"] as? String {
                    profileImageData = Data(base64Encoded: base64String)
                }

                let user = RankingUser(
                    id: UUID(),
                    name: data["userName"] as? String ?? "익명",
                    petName: data["petName"] as? String ?? "반려동물",
                    petBreed: data["petBreed"] as? String ?? "",
                    profileImageData: profileImageData,
                    totalDistance: data["totalDistance"] as? Double ?? 0,
                    totalWalkCount: data["totalWalkCount"] as? Int ?? 0,
                    totalDuration: data["totalDuration"] as? TimeInterval ?? 0,
                    badges: [],
                    rank: 0,
                    isCurrentUser: document.documentID == userId
                )
                allUsers.append(user)
            }
        }

        // 정렬
        switch type {
        case .distance:
            allUsers.sort { $0.totalDistance > $1.totalDistance }
        case .walkCount:
            allUsers.sort { $0.totalWalkCount > $1.totalWalkCount }
        case .duration:
            allUsers.sort { $0.totalDuration > $1.totalDuration }
        }

        // 순위 할당
        let rankedUsers = allUsers.prefix(limit).enumerated().map { index, user in
            RankingUser(
                id: user.id,
                name: user.name,
                petName: user.petName,
                petBreed: user.petBreed,
                profileImageData: user.profileImageData,
                totalDistance: user.totalDistance,
                totalWalkCount: user.totalWalkCount,
                totalDuration: user.totalDuration,
                badges: user.badges,
                rank: index + 1,
                isCurrentUser: user.isCurrentUser
            )
        }

        print("[Firebase] 친구 랭킹 조회 완료: \(rankedUsers.count)명")
        return Array(rankedUsers)
    }
}

// MARK: - Array Extension
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

// MARK: - GeoHash Helper
struct GeoHashHelper {
    private static let base32 = Array("0123456789bcdefghjkmnpqrstuvwxyz")

    /// 위도/경도를 GeoHash로 인코딩
    static func encode(latitude: Double, longitude: Double, precision: Int = 5) -> String {
        var latRange = (-90.0, 90.0)
        var lngRange = (-180.0, 180.0)
        var hash = ""
        var bit = 0
        var ch = 0
        var isEven = true

        while hash.count < precision {
            if isEven {
                let mid = (lngRange.0 + lngRange.1) / 2
                if longitude >= mid {
                    ch |= (1 << (4 - bit))
                    lngRange.0 = mid
                } else {
                    lngRange.1 = mid
                }
            } else {
                let mid = (latRange.0 + latRange.1) / 2
                if latitude >= mid {
                    ch |= (1 << (4 - bit))
                    latRange.0 = mid
                } else {
                    latRange.1 = mid
                }
            }
            isEven.toggle()
            bit += 1

            if bit == 5 {
                hash.append(base32[ch])
                bit = 0
                ch = 0
            }
        }

        return hash
    }

    /// 주어진 위치와 반경에 대한 GeoHash 쿼리 범위 반환
    static func queryBounds(latitude: Double, longitude: Double, radiusKm: Double) -> [(start: String, end: String)] {
        // 간단한 구현: 중심 GeoHash의 인접 셀들 포함
        let precision = radiusKm <= 1 ? 6 : (radiusKm <= 5 ? 5 : 4)
        let centerHash = encode(latitude: latitude, longitude: longitude, precision: precision)

        // 인접 GeoHash 계산
        let neighbors = getNeighbors(geohash: centerHash)
        var allHashes = [centerHash] + neighbors

        // 각 해시에 대한 범위 생성
        return allHashes.map { hash in
            (start: hash, end: hash + "~")
        }
    }

    /// GeoHash의 8방향 이웃 반환
    private static func getNeighbors(geohash: String) -> [String] {
        guard !geohash.isEmpty else { return [] }

        // 간단한 구현: 마지막 문자만 조절
        let lastChar = geohash.last!
        guard let index = base32.firstIndex(of: lastChar) else { return [] }

        let prefix = String(geohash.dropLast())
        var neighbors: [String] = []

        // 인접 문자들
        let adjacentIndices = [index - 1, index + 1, index - 4, index + 4, index - 5, index + 5, index - 3, index + 3]

        for adjIndex in adjacentIndices {
            if adjIndex >= 0 && adjIndex < base32.count {
                neighbors.append(prefix + String(base32[adjIndex]))
            }
        }

        return neighbors
    }
}

// MARK: - Firebase 에러
enum FirebaseError: Error, LocalizedError {
    case notConfigured
    case notAuthenticated
    case documentNotFound
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Firebase가 초기화되지 않았습니다."
        case .notAuthenticated:
            return "로그인이 필요합니다."
        case .documentNotFound:
            return "데이터를 찾을 수 없습니다."
        case .unknown(let message):
            return message
        }
    }
}
