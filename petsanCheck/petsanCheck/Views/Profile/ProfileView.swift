//
//  ProfileView.swift
//  petsanCheck
//
//  Created on 2025-11-29.
//

import SwiftUI

/// 프로필 화면
struct ProfileView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "person.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)

                Text("마이 프로필")
                    .font(.title)
                    .fontWeight(.bold)

                Text("반려견 정보 및 설정 관리")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()
            }
            .padding()
            .navigationTitle("프로필")
        }
    }
}

#Preview {
    ProfileView()
}
