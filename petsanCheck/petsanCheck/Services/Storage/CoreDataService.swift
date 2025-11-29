//
//  CoreDataService.swift
//  petsanCheck
//
//  Created on 2025-11-29.
//

import Foundation
import CoreData

/// CoreData 관리 서비스
class CoreDataService {
    static let shared = CoreDataService()

    private init() {}

    // MARK: - Core Data Stack

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "petsanCheck")
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                print("CoreData 로드 실패: \(error), \(error.userInfo)")
            }
        }
        return container
    }()

    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    // MARK: - Core Data Saving

    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                print("CoreData 저장 실패: \(nserror), \(nserror.userInfo)")
            }
        }
    }

    // MARK: - Dog CRUD

    /// 반려견 생성
    @discardableResult
    func createDog(_ dog: Dog) -> DogEntity? {
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

        saveContext()
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
            print("반려견 조회 실패: \(error)")
            return []
        }
    }

    /// 반려견 업데이트
    func updateDog(_ dog: Dog) {
        let request = DogEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", dog.id as CVarArg)

        do {
            let entities = try context.fetch(request)
            if let entity = entities.first {
                entity.update(from: dog)
                saveContext()
            }
        } catch {
            print("반려견 업데이트 실패: \(error)")
        }
    }

    /// 반려견 삭제
    func deleteDog(_ dog: Dog) {
        let request = DogEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", dog.id as CVarArg)

        do {
            let entities = try context.fetch(request)
            if let entity = entities.first {
                context.delete(entity)
                saveContext()
            }
        } catch {
            print("반려견 삭제 실패: \(error)")
        }
    }

    // MARK: - Walk Record CRUD

    /// 산책 기록 생성
    @discardableResult
    func createWalkRecord(_ session: WalkSession, dogId: UUID? = nil) -> WalkRecordEntity? {
        let entity = WalkRecordEntity(context: context)
        entity.update(from: session)

        // 반려견과 연결
        if let dogId = dogId {
            let dogRequest = DogEntity.fetchRequest()
            dogRequest.predicate = NSPredicate(format: "id == %@", dogId as CVarArg)

            if let dogEntity = try? context.fetch(dogRequest).first {
                entity.dog = dogEntity
            }
        }

        saveContext()
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
            print("산책 기록 조회 실패: \(error)")
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
            print("산책 기록 조회 실패: \(error)")
            return []
        }
    }

    /// 산책 기록 삭제
    func deleteWalkRecord(_ sessionId: UUID) {
        let request = WalkRecordEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", sessionId as CVarArg)

        do {
            let entities = try context.fetch(request)
            if let entity = entities.first {
                context.delete(entity)
                saveContext()
            }
        } catch {
            print("산책 기록 삭제 실패: \(error)")
        }
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
            print("최근 산책 기록 조회 실패: \(error)")
            return []
        }
    }
}
