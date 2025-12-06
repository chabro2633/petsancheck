//
//  AppTheme.swift
//  petsanCheck
//
//  Created on 2025-12-06.
//

import SwiftUI

/// 앱 테마 색상 정의
struct AppTheme {
    // MARK: - Primary Colors (연한 하늘색 톤)

    /// 메인 하늘색
    static let primary = Color(red: 0.4, green: 0.7, blue: 0.95)

    /// 밝은 하늘색 (배경용)
    static let primaryLight = Color(red: 0.9, green: 0.95, blue: 1.0)

    /// 진한 하늘색 (강조용)
    static let primaryDark = Color(red: 0.2, green: 0.5, blue: 0.8)

    // MARK: - Background Colors

    /// 메인 배경색 (연한 하늘색)
    static let background = Color(red: 0.94, green: 0.97, blue: 1.0)

    /// 카드 배경색
    static let cardBackground = Color.white

    /// 그라데이션 배경
    static let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.9, green: 0.95, blue: 1.0),
            Color(red: 0.85, green: 0.92, blue: 0.98)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    // MARK: - Accent Colors

    /// 성공/긍정 (연한 민트)
    static let success = Color(red: 0.4, green: 0.8, blue: 0.7)

    /// 경고 (연한 주황)
    static let warning = Color(red: 1.0, green: 0.7, blue: 0.4)

    /// 위험/에러 (연한 빨강)
    static let danger = Color(red: 0.95, green: 0.5, blue: 0.5)

    /// 보조색 (연한 보라)
    static let secondary = Color(red: 0.7, green: 0.6, blue: 0.9)

    // MARK: - Text Colors

    /// 기본 텍스트
    static let textPrimary = Color(red: 0.2, green: 0.25, blue: 0.35)

    /// 보조 텍스트
    static let textSecondary = Color(red: 0.5, green: 0.55, blue: 0.6)

    /// 밝은 텍스트 (어두운 배경용)
    static let textLight = Color.white

    // MARK: - Shadow

    /// 기본 그림자 색상
    static let shadow = Color.black.opacity(0.08)
}

// MARK: - View Modifier Extensions

extension View {
    /// 앱 테마 카드 스타일 적용
    func appCard() -> some View {
        self
            .background(AppTheme.cardBackground)
            .cornerRadius(16)
            .shadow(color: AppTheme.shadow, radius: 10, x: 0, y: 4)
    }

    /// 앱 테마 배경 적용
    func appBackground() -> some View {
        self
            .background(AppTheme.background)
    }

    /// 그라데이션 배경 적용
    func gradientBackground() -> some View {
        self
            .background(AppTheme.backgroundGradient)
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(configuration.isPressed ? AppTheme.primaryDark : AppTheme.primary)
            .cornerRadius(12)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(AppTheme.primary)
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppTheme.primaryLight)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.primary, lineWidth: 1)
            )
    }
}
