//
//  HospitalView.swift
//  petsanCheck
//
//  Created on 2025-11-29.
//

import SwiftUI

/// 병원 검색 화면
struct HospitalView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "cross.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.red)

                Text("동물병원 검색")
                    .font(.title)
                    .fontWeight(.bold)

                Text("주변 동물병원 찾기 및 정보 확인")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()
            }
            .padding()
            .navigationTitle("병원")
        }
    }
}

#Preview {
    HospitalView()
}
