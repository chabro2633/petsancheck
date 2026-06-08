//
//  CoreDataService.swift
//  petsanCheck
//
//  Created on 2025-11-29.
//

import Foundation
import CoreData
import os

/// CoreData 작업 중 발생하는 오류
enum CoreDataError: LocalizedError {
    case loadFailed(Error)
    case saveFailed(Error)
    case fetchFailed(Error)

    var errorDescription: String? {
        switch self {
        case .loadFailed:
            return "데이터 저장소를 불러오지 못했습니다."
        case .saveFailed:
            return "데이터를 저장하지 못했습니다. 잠시 후 다시 시도해주세요."
        case .fetchFailed:
            return "데이터를 불러오지 못했습니다."
        }
    }
}

/// CoreData 관리 서비스
///
/// 쓰기 작업(생성/수정/삭제/저장)은 실패 시 `CoreDataError`를 던져 호출자가
/// 사용자에게 알리거나 복구 처리를 할 수 있도록 한다.
/// 조회 작업은 실패 시 빈 배열을 반환하되, 오류는 로그로 남긴다.
class CoreDataService {
    static let shared = CoreDataService()

    private let logger = Logger(subsystem: "com.petsanCheck", category: "CoreData")

    private init() {}

    // MARK: - Core Data Stack

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "petsanCheck")
        container.loadPersistentStores { [logger] _, error in
            if let error = error as NSError? {
                logger.error("CoreData 로드 실패: \(error, privacy: .public), \(error.userInfo, privacy: .public)")
            }
        }
        return container
    }()

    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    // MARK: - Core Data Saving

    /// 변경사항 저장. 실패 시 `CoreDataError.saveFailed`를 던진다.
    func saveContext() throws {
        let context = persistentContainer.viewContext
        guard context.hasChanges else { return }

        do {
            try context.save()
        } catch {
            logger.error("CoreData 저장 실패: \(error as NSError, privacy: .public)")
            throw CoreDataError.saveFailed(error)
        }
    }

    // MARK: - Dog CRUD

    /// 반려견 생성
    @discardableResult
    func createDog(_ dog: Dog) throws -> DogEntity {
        let entity = DogEntity(context: context)
        entity.id = dog.id
        entity.name = dog.name
        entity.breed = dog.breed
        entity.birthDate = dog.birthDate
        entity.weight = dog.weight
        entity.gender = dog.gender.rawValue
        entity.profileImageData = dog.profileImageData
        entity.notes = dog.notes
        entity.createdAt = dog.createdAt
        entity.updatedAt = dog.updatedAt

        try saveContext()
        return entity
    }

    /// 모든 반려견 조회
    func fetchAllDogs() -> [Dog] {
        let request = DogEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        do {
            let entities = try context.fetch(request)
            return entities.map { $0.toDomain() }
        } catch {
            logger.error("반려견 조회 실패: \(error as NSError, privacy: .public)")
            return []
        }
    }

    /// 반려견 업데이트
    func updateDog(_ dog: Dog) throws {
        let request = DogEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", dog.id as CVarArg)

        do {
            let entities = try context.fetch(request)
            guard let entity = entities.first else {
                logger.warning("반려견 업데이트 대상 없음: id=\(dog.id, privacy: .public)")
                return
            }
            entity.update(from: dog)
        } catch {
            logger.error("반려견 업데이트 조회 실패: \(error as NSError, privacy: .public)")
            throw CoreDataError.fetchFailed(error)
        }

        try saveContext()
    }

    /// 반려견 삭제
    func deleteDog(_ dog: Dog) throws {
        let request = DogEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", dog.id as CVarArg)

        do {
            let entities = try context.fetch(request)
            guard let entity = entities.first else {
                logger.warning("반려견 삭제 대상 없음: id=\(dog.id, privacy: .public)")
                return
            }
            context.delete(entity)
        } catch {
            logger.error("반려견 삭제 조회 실패: \(error as NSError, privacy: .public)")
            throw CoreDataError.fetchFailed(error)
        }

        try saveContext()
    }

    // MARK: - Walk Record CRUD

    /// 산책 기록 생성
    @discardableResult
    func createWalkRecord(_ session: WalkSession, dogId: UUID? = nil) throws -> WalkRecordEntity {
        let entity = WalkRecordEntity(context: context)
        entity.update(from: session)

        // 반려견과 연결 (대상이 없으면 연결만 건너뛰고, 조회 자체가 실패하면 오류 전파)
        if let dogId = dogId {
            let dogRequest = DogEntity.fetchRequest()
            dogRequest.predicate = NSPredicate(format: "id == %@", dogId as CVarArg)

            do {
                if let dogEntity = try context.fetch(dogRequest).first {
                    entity.dog = dogEntity
                } else {
                    logger.warning("산책 기록 연결 실패: 반려견(id=\(dogId, privacy: .public)) 없음")
                }
            } catch {
                logger.error("산책 기록 연결용 반려견 조회 실패: \(error as NSError, privacy: .public)")
                throw CoreDataError.fetchFailed(error)
            }
        }

        try saveContext()
        return entity
    }

    /// 모든 산책 기록 조회
    func fetchAllWalkRecords() -> [WalkSession] {
        let request = WalkRecordEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]

        do {
            let entities = try context.fetch(request)
            return entities.map { $0.toDomain() }
        } catch {
            logger.error("산책 기록 조회 실패: \(error as NSError, privacy: .public)")
            return []
        }
    }

    /// 특정 반려견의 산책 기록 조회
    func fetchWalkRecords(for dogId: UUID) -> [WalkSession] {
        let request = WalkRecordEntity.fetchRequest()
        request.predicate = NSPredicate(format: "dog.id == %@", dogId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]

        do {
            let entities = try context.fetch(request)
            return entities.map { $0.toDomain() }
        } catch {
            logger.error("산책 기록 조회 실패: \(error as NSError, privacy: .public)")
            return []
        }
    }

    /// 산책 기록 삭제
    func deleteWalkRecord(_ sessionId: UUID) throws {
        let request = WalkRecordEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", sessionId as CVarArg)

        do {
            let entities = try context.fetch(request)
            guard let entity = entities.first else {
                logger.warning("산책 기록 삭제 대상 없음: id=\(sessionId, privacy: .public)")
                return
            }
            context.delete(entity)
        } catch {
            logger.error("산책 기록 삭제 조회 실패: \(error as NSError, privacy: .public)")
            throw CoreDataError.fetchFailed(error)
        }

        try saveContext()
    }

    /// 최근 산책 기록 조회 (개수 제한)
    func fetchRecentWalkRecords(limit: Int = 10) -> [WalkSession] {
        let request = WalkRecordEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]
        request.fetchLimit = limit

        do {
            let entities = try context.fetch(request)
            return entities.map { $0.toDomain() }
        } catch {
            logger.error("최근 산책 기록 조회 실패: \(error as NSError, privacy: .public)")
            return []
        }
    }
}
