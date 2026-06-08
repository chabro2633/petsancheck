//
//  ProfileViewModel.swift
//  petsanCheck
//
//  Created on 2025-11-29.
//

import Foundation
import Combine

/// 프로필 관리 ViewModel
@MainActor
class ProfileViewModel: ObservableObject {
    @Published var dogs: [Dog] = []
    @Published var selectedDog: Dog?
    @Published var isShowingAddDog = false
    @Published var isShowingEditDog = false
    /// 저장/삭제 실패 시 사용자에게 보여줄 오류 메시지
    @Published var errorMessage: String?

    private let coreDataService = CoreDataService.shared

    init() {
        loadDogs()
    }

    /// 반려견 목록 로드
    func loadDogs() {
        dogs = coreDataService.fetchAllDogs()
        if dogs.isEmpty == false, selectedDog == nil {
            selectedDog = dogs.first
        }
    }

    /// 반려견 추가
    func addDog(_ dog: Dog) {
        do {
            try coreDataService.createDog(dog)
            loadDogs()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// 반려견 업데이트
    func updateDog(_ dog: Dog) {
        do {
            try coreDataService.updateDog(dog)
            loadDogs()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// 반려견 삭제
    func deleteDog(_ dog: Dog) {
        do {
            try coreDataService.deleteDog(dog)
            if selectedDog?.id == dog.id {
                selectedDog = nil
            }
            loadDogs()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
