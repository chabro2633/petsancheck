//
//  FeedView.swift
//  petsanCheck
//
//  Created on 2025-11-29.
//

import SwiftUI

/// 피드 화면
struct FeedView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: 80))
                    .foregroundColor(.purple)

                Text("커뮤니티 피드")
                    .font(.title)
                    .fontWeight(.bold)

                Text("다른 반려견과 산책 사진 공유")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()
            }
            .padding()
            .navigationTitle("피드")
        }
    }
}

#Preview {
    FeedView()
}
