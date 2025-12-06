//
//  ProfileView.swift
//  petsanCheck
//
//  Created on 2025-11-29.
//

import SwiftUI
import PhotosUI

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
                            .foregroundColor(AppTheme.textSecondary)

                        Text("등록된 반려견이 없습니다")
                            .font(.headline)
                            .foregroundColor(AppTheme.textSecondary)

                        Button(action: {
                            viewModel.isShowingAddDog = true
                        }) {
                            Label("반려견 추가하기", systemImage: "plus.circle.fill")
                                .font(.headline)
                                .foregroundColor(AppTheme.primary)
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
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.selectedDog = dog
                                viewModel.isShowingEditDog = true
                            }
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
                                .tint(AppTheme.primary)
                            }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(AppTheme.background)
            .navigationTitle("프로필")
            .toolbarBackground(AppTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.isShowingAddDog = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(AppTheme.primary)
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
                        .foregroundColor(AppTheme.primary)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(dog.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.textPrimary)

                    Text(dog.breed)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)

                    HStack(spacing: 12) {
                        Label(dog.ageText, systemImage: "calendar")
                        Label(dog.gender.rawValue, systemImage: "heart.fill")
                        Label("\(String(format: "%.1f", dog.weight))kg", systemImage: "scalemass")
                    }
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
                }

                Spacer()
            }

            if let notes = dog.notes {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
        .shadow(color: AppTheme.shadow, radius: 10, x: 0, y: 4)
    }
}

// MARK: - 반려견 등록/수정 폼
struct DogFormView: View {
    @Environment(\.dismiss) var dismiss
    let onSave: (Dog) -> Void

    @State private var name: String
    @State private var breed: String
    @State private var birthDateText: String  // yyyy, yyyy-mm, yyyy-mm-dd 형식
    @State private var weight: String
    @State private var gender: Dog.Gender
    @State private var notes: String
    @State private var profileImageData: Data?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var birthDateError: String?

    private let existingDog: Dog?

    init(dog: Dog? = nil, onSave: @escaping (Dog) -> Void) {
        self.existingDog = dog
        self.onSave = onSave

        _name = State(initialValue: dog?.name ?? "")
        _breed = State(initialValue: dog?.breed ?? "")

        // 기존 생년월일을 yyyy-mm-dd 형식으로 변환
        if let dog = dog {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            _birthDateText = State(initialValue: formatter.string(from: dog.birthDate))
        } else {
            _birthDateText = State(initialValue: "")
        }

        _weight = State(initialValue: dog != nil ? String(format: "%.1f", dog!.weight) : "")
        _gender = State(initialValue: dog?.gender ?? .male)
        _notes = State(initialValue: dog?.notes ?? "")
        _profileImageData = State(initialValue: dog?.profileImageData)
    }

    /// 생년월일 텍스트를 Date로 파싱 (yyyy, yyyy-mm, yyyy-mm-dd 지원)
    private func parseBirthDate(_ text: String) -> Date? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")

        // yyyy-mm-dd 형식
        if trimmed.count == 10 && trimmed.contains("-") {
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.date(from: trimmed)
        }

        // yyyy-mm 형식 (일은 1일로 설정)
        if trimmed.count == 7 && trimmed.contains("-") {
            formatter.dateFormat = "yyyy-MM"
            if let date = formatter.date(from: trimmed) {
                return date
            }
        }

        // yyyy 형식 (월은 1월, 일은 1일로 설정)
        if trimmed.count == 4, let year = Int(trimmed), year >= 1990 && year <= Calendar.current.component(.year, from: Date()) {
            formatter.dateFormat = "yyyy"
            return formatter.date(from: trimmed)
        }

        return nil
    }

    /// 입력값 유효성 검사
    private var isValidBirthDate: Bool {
        guard !birthDateText.isEmpty else { return true } // 빈 값은 저장 시 체크
        return parseBirthDate(birthDateText) != nil
    }

    /// 저장 가능 여부
    private var canSave: Bool {
        !name.isEmpty && !breed.isEmpty && !weight.isEmpty && !birthDateText.isEmpty && isValidBirthDate
    }

    var body: some View {
        NavigationStack {
            Form {
                // 프로필 사진 섹션
                Section {
                    HStack {
                        Spacer()

                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            ZStack {
                                if let imageData = profileImageData,
                                   let uiImage = UIImage(data: imageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(AppTheme.primary, lineWidth: 3)
                                        )
                                } else {
                                    Circle()
                                        .fill(AppTheme.cardBackground)
                                        .frame(width: 120, height: 120)
                                        .overlay(
                                            VStack(spacing: 8) {
                                                Image(systemName: "camera.fill")
                                                    .font(.title)
                                                    .foregroundColor(AppTheme.primary)
                                                Text("사진 추가")
                                                    .font(.caption)
                                                    .foregroundColor(.black.opacity(0.6))
                                            }
                                        )
                                }

                                // 편집 버튼
                                Circle()
                                    .fill(AppTheme.primary)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Image(systemName: "pencil")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                    )
                                    .offset(x: 40, y: 40)
                            }
                        }

                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }

                Section {
                    TextField("이름", text: $name)
                        .foregroundColor(.black)
                        .listRowBackground(AppTheme.cardBackground)
                    TextField("품종", text: $breed)
                        .foregroundColor(.black)
                        .listRowBackground(AppTheme.cardBackground)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("생년월일")
                                .foregroundColor(.black)
                            Spacer()
                            TextField("yyyy-mm-dd", text: $birthDateText)
                                .foregroundColor(.black)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.numbersAndPunctuation)
                                .autocapitalization(.none)
                                .onChange(of: birthDateText) { _, newValue in
                                    // 자동으로 하이픈 추가
                                    var formatted = newValue.filter { $0.isNumber || $0 == "-" }

                                    // 숫자만 추출
                                    let numbers = formatted.filter { $0.isNumber }

                                    if numbers.count >= 4 && !formatted.contains("-") {
                                        // yyyy 다음에 자동으로 하이픈 추가
                                        let year = String(numbers.prefix(4))
                                        let rest = String(numbers.dropFirst(4))
                                        if rest.isEmpty {
                                            formatted = year
                                        } else if rest.count <= 2 {
                                            formatted = "\(year)-\(rest)"
                                        } else {
                                            let month = String(rest.prefix(2))
                                            let day = String(rest.dropFirst(2).prefix(2))
                                            if day.isEmpty {
                                                formatted = "\(year)-\(month)"
                                            } else {
                                                formatted = "\(year)-\(month)-\(day)"
                                            }
                                        }
                                    }

                                    if formatted != birthDateText && formatted.count <= 10 {
                                        birthDateText = formatted
                                    }
                                }
                        }

                        if !birthDateText.isEmpty && !isValidBirthDate {
                            Text("형식: yyyy 또는 yyyy-mm 또는 yyyy-mm-dd")
                                .font(.caption2)
                                .foregroundColor(AppTheme.danger)
                        } else if birthDateText.isEmpty {
                            Text("예: 2020 또는 2020-05 또는 2020-05-15")
                                .font(.caption2)
                                .foregroundColor(.black.opacity(0.4))
                        }
                    }
                    .listRowBackground(AppTheme.cardBackground)
                } header: {
                    Text("기본 정보")
                        .foregroundColor(.black.opacity(0.7))
                }

                Section {
                    HStack {
                        TextField("몸무게", text: $weight)
                            .keyboardType(.decimalPad)
                            .foregroundColor(.black)
                        Text("kg")
                            .foregroundColor(.black.opacity(0.6))
                    }
                    .listRowBackground(AppTheme.cardBackground)

                    Picker("성별", selection: $gender) {
                        ForEach(Dog.Gender.allCases, id: \.self) { gender in
                            Text(gender.rawValue).tag(gender)
                        }
                    }
                    .foregroundColor(.black)
                    .listRowBackground(AppTheme.cardBackground)
                } header: {
                    Text("상세 정보")
                        .foregroundColor(.black.opacity(0.7))
                }

                Section {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                        .foregroundColor(.black)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .listRowBackground(AppTheme.cardBackground)
                } header: {
                    Text("메모")
                        .foregroundColor(.black.opacity(0.7))
                }

                // 사진 삭제 버튼 (사진이 있을 때만)
                if profileImageData != nil {
                    Section {
                        Button(role: .destructive) {
                            profileImageData = nil
                            selectedPhoto = nil
                        } label: {
                            HStack {
                                Spacer()
                                Label("사진 삭제", systemImage: "trash")
                                Spacer()
                            }
                        }
                        .listRowBackground(AppTheme.cardBackground)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.background)
            .navigationTitle(existingDog == nil ? "반려견 추가" : "반려견 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.textSecondary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        saveDog()
                    }
                    .foregroundColor(canSave ? AppTheme.primary : AppTheme.primary.opacity(0.5))
                    .disabled(!canSave)
                }
            }
            .onChange(of: selectedPhoto) { _, newItem in
                Task {
                    if let newItem = newItem,
                       let data = try? await newItem.loadTransferable(type: Data.self) {
                        // 이미지 리사이즈 (프로필용 적당한 크기로)
                        if let uiImage = UIImage(data: data),
                           let resizedImage = resizeImage(uiImage, targetSize: CGSize(width: 400, height: 400)),
                           let jpegData = resizedImage.jpegData(compressionQuality: 0.8) {
                            await MainActor.run {
                                profileImageData = jpegData
                            }
                        } else {
                            await MainActor.run {
                                profileImageData = data
                            }
                        }
                    }
                }
            }
        }
    }

    private func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage? {
        let size = image.size
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        let ratio = min(widthRatio, heightRatio)

        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let renderer = UIGraphicsImageRenderer(size: newSize)

        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    private func saveDog() {
        guard let weightValue = Double(weight),
              let birthDate = parseBirthDate(birthDateText) else { return }

        let dog = Dog(
            id: existingDog?.id ?? UUID(),
            name: name,
            breed: breed,
            birthDate: birthDate,
            weight: weightValue,
            gender: gender,
            profileImageData: profileImageData,
            notes: notes.isEmpty ? nil : notes,
            createdAt: existingDog?.createdAt ?? Date()
        )

        onSave(dog)
    }
}

#Preview {
    ProfileView()
}
