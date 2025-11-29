# petsanCheck - 반려견 산책 도우미

## 프로젝트 구조

```
petsanCheck/
├── Models/              # 데이터 모델
│   ├── Domain/         # 비즈니스 로직 모델
│   ├── API/            # API 응답 모델
│   └── CoreData/       # CoreData 엔티티
│
├── Views/              # SwiftUI 뷰
│   ├── Home/           # 홈 화면
│   ├── Walk/           # 산책 관련 화면
│   ├── Hospital/       # 동물병원 검색
│   ├── Feed/           # 커뮤니티 피드
│   ├── Profile/        # 프로필 관리
│   ├── Onboarding/     # 온보딩
│   ├── Shared/         # 공유 컴포넌트
│   └── Main/           # 메인 탭 구조
│
├── ViewModels/         # 비즈니스 로직
│   ├── Home/
│   ├── Walk/
│   ├── Hospital/
│   ├── Feed/
│   ├── Profile/
│   └── Onboarding/
│
├── Services/           # 외부 서비스
│   ├── Network/        # API 통신
│   ├── Storage/        # 데이터 저장
│   └── External/       # 외부 API (날씨, 지도)
│
├── Managers/           # 시스템 관리자
│   # LocationManager, NotificationManager 등
│
├── Utils/              # 유틸리티
│   ├── Extensions/     # Swift 확장
│   ├── Helpers/        # 헬퍼 함수
│   └── Constants/      # 상수 정의
│
└── Components/         # 재사용 가능한 UI 컴포넌트
    ├── Cards/          # 카드 컴포넌트
    ├── Charts/         # 차트 컴포넌트
    ├── Common/         # 공통 컴포넌트
    └── Map/            # 지도 관련 컴포넌트
```

## 아키텍처

- **MVVM** (Model-View-ViewModel) 패턴
- **SwiftUI** UI 프레임워크
- **Combine** 반응형 프로그래밍
- **CoreData** 로컬 데이터 저장

## 주요 기능

1. 🌤️ 날씨 기반 산책 추천
2. 📍 실시간 산책 경로 추적
3. 🏥 주변 동물병원 검색
4. 📱 산책 기록 및 통계
5. 👥 커뮤니티 피드

## 개발 환경

- Xcode 26.1.1+
- iOS 17.0+
- Swift 5.0+
