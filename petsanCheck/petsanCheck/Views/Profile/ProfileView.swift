//
//  ProfileView.swift
//  petsanCheck
//
//  Created on 2025-11-29.
//

import SwiftUI

/// 프로필 화면
struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()

    var body: some View {
        NavigationStack {
            List {
                if viewModel.dogs.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)

                        Text("등록된 반려견이 없습니다")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Button(action: {
                            viewModel.isShowingAddDog = true
                        }) {
                            Label("반려견 추가하기", systemImage: "plus.circle.fill")
                                .font(.headline)
                                .foregroundColor(.blue)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(viewModel.dogs) { dog in
                        DogProfileCard(dog: dog)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    viewModel.deleteDog(dog)
                                } label: {
                                    Label("삭제", systemImage: "trash")
                                }

                                Button {
                                    viewModel.selectedDog = dog
                                    viewModel.isShowingEditDog = true
                                } label: {
                                    Label("수정", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("프로필")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.isShowingAddDog = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $viewModel.isShowingAddDog) {
                DogFormView { dog in
                    viewModel.addDog(dog)
                    viewModel.isShowingAddDog = false
                }
            }
            .sheet(isPresented: $viewModel.isShowingEditDog) {
                if let dog = viewModel.selectedDog {
                    DogFormView(dog: dog) { updatedDog in
                        viewModel.updateDog(updatedDog)
                        viewModel.isShowingEditDog = false
                    }
                }
            }
        }
    }
}

// MARK: - 반려견 프로필 카드
struct DogProfileCard: View {
    let dog: Dog

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // 프로필 이미지
                if let imageData = dog.profileImageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "pawprint.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.gray)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(dog.name)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(dog.breed)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack(spacing: 12) {
                        Label(dog.ageText, systemImage: "calendar")
                        Label(dog.gender.rawValue, systemImage: "heart.fill")
                        Label("\(String(format: "%.1f", dog.weight))kg", systemImage: "scalemass")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                Spacer()
            }

            if let notes = dog.notes {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
    }
}

// MARK: - 반려견 등록/수정 폼
struct DogFormView: View {
    @Environment(\.dismiss) var dismiss
    let onSave: (Dog) -> Void

    @State private var name: String
    @State private var breed: String
    @State private var birthDate: Date
    @State private var weight: String
    @State private var gender: Dog.Gender
    @State private var notes: String

    private let existingDog: Dog?

    init(dog: Dog? = nil, onSave: @escaping (Dog) -> Void) {
        self.existingDog = dog
        self.onSave = onSave

        _name = State(initialValue: dog?.name ?? "")
        _breed = State(initialValue: dog?.breed ?? "")
        _birthDate = State(initialValue: dog?.birthDate ?? Date())
        _weight = State(initialValue: dog != nil ? String(format: "%.1f", dog!.weight) : "")
        _gender = State(initialValue: dog?.gender ?? .male)
        _notes = State(initialValue: dog?.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("기본 정보") {
                    TextField("이름", text: $name)
                    TextField("품종", text: $breed)
                    DatePicker("생년월일", selection: $birthDate, displayedComponents: .date)
                }

                Section("상세 정보") {
                    HStack {
                        TextField("몸무게", text: $weight)
                            .keyboardType(.decimalPad)
                        Text("kg")
                            .foregroundColor(.secondary)
                    }

                    Picker("성별", selection: $gender) {
                        ForEach(Dog.Gender.allCases, id: \.self) { gender in
                            Text(gender.rawValue).tag(gender)
                        }
                    }
                }

                Section("메모") {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            .navigationTitle(existingDog == nil ? "반려견 추가" : "반려견 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        saveDog()
                    }
                    .disabled(name.isEmpty || breed.isEmpty || weight.isEmpty)
                }
            }
        }
    }

    private func saveDog() {
        guard let weightValue = Double(weight) else { return }

        let dog = Dog(
            id: existingDog?.id ?? UUID(),
            name: name,
            breed: breed,
            birthDate: birthDate,
            weight: weightValue,
            gender: gender,
            notes: notes.isEmpty ? nil : notes,
            createdAt: existingDog?.createdAt ?? Date()
        )

        onSave(dog)
    }
}

#Preview {
    ProfileView()
}
