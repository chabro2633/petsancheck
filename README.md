# PetSanCheck - 반려견 산책 도우미

반려견과 함께하는 즐거운 산책을 위한 iOS 앱입니다.

## 주요 기능

- **날씨 기반 산책 추천**: 현재 날씨에 따른 산책 적합도 표시
- **실시간 산책 추적**: GPS 기반 경로 추적 및 거리/시간/칼로리 계산
- **산책 기록 관리**: 주간/월간 산책 통계 및 달력 뷰
- **주변 동물병원 검색**: 카카오맵 기반 주변 동물병원 찾기
- **커뮤니티 피드**: 인스타그램 스타일의 산책 사진 공유
- **반려견 프로필**: 다중 반려견 등록 및 관리

## 스크린샷

| 홈 화면 | 산책 추적 | 병원 검색 | 피드 |
|:---:|:---:|:---:|:---:|
| 날씨 & 산책 추천 | GPS 경로 추적 | 주변 동물병원 | 커뮤니티 |

## 기술 스택

- **UI**: SwiftUI
- **아키텍처**: MVVM
- **반응형 프로그래밍**: Combine
- **로컬 저장소**: CoreData
- **지도**: 카카오맵 SDK (WebView)
- **위치 서비스**: CoreLocation
- **외부 API**: OpenWeatherMap, 카카오 로컬 API

## 프로젝트 구조

```
petsanCheck/
├── Models/              # 데이터 모델
│   ├── Domain/          # 비즈니스 모델
│   ├── API/             # API 응답 모델
│   └── CoreData/        # CoreData 엔티티
│
├── Views/               # SwiftUI 뷰
│   ├── Home/            # 홈 화면
│   ├── Walk/            # 산책 관련 화면
│   ├── Hospital/        # 동물병원 검색
│   ├── Feed/            # 커뮤니티 피드
│   └── Profile/         # 프로필 관리
│
├── ViewModels/          # 비즈니스 로직
├── Services/            # 외부 서비스 연동
├── Utils/               # 유틸리티 및 확장
└── Components/          # 재사용 UI 컴포넌트
```

## 설치 및 실행

### 요구사항

- Xcode 15.0+
- iOS 17.0+
- Swift 5.9+

### API 키 설정

1. `petsanCheck/Info.plist` 파일에서 API 키 설정:

```xml
<key>KAKAO_MAP_API_KEY</key>
<string>YOUR_KAKAO_MAP_KEY</string>
<key>KAKAO_REST_API_KEY</key>
<string>YOUR_KAKAO_REST_KEY</string>
<key>OPENWEATHER_API_KEY</key>
<string>YOUR_OPENWEATHER_KEY</string>
```

2. 카카오 개발자 콘솔에서 도메인 등록:
   - JavaScript 키: `chabro2633.github.io` 등록

### 빌드

```bash
# 프로젝트 클론
git clone https://github.com/chabro2633/petsancheck.git

# Xcode에서 프로젝트 열기
open petsanCheck/petsanCheck.xcodeproj
```

## 라이선스

이 프로젝트는 개인 프로젝트입니다.
