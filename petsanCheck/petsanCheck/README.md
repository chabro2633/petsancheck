# petsanCheck 소스코드

## 폴더 구조

```
petsanCheck/
├── Info.plist           # API 키 설정 파일
├── petsanCheckApp.swift # 앱 진입점
├── ContentView.swift    # 루트 뷰
│
├── Models/              # 데이터 모델
│   ├── Domain/          # Dog, WalkSession, Hospital 등
│   ├── API/             # WeatherAPIResponse, KakaoLocalAPIResponse
│   └── CoreData/        # petsanCheck.xcdatamodeld
│
├── Views/               # SwiftUI 화면
│   ├── Home/            # HomeView - 날씨, 산책 추천
│   ├── Walk/            # WalkView, WalkMapView, WalkHistoryView
│   ├── Hospital/        # HospitalView, KakaoMapView
│   ├── Feed/            # FeedView - 커뮤니티
│   └── Profile/         # ProfileView - 반려견 관리
│
├── ViewModels/          # MVVM ViewModel
│   ├── Home/            # HomeViewModel
│   ├── Walk/            # WalkViewModel, WalkHistoryViewModel
│   ├── Hospital/        # HospitalViewModel
│   ├── Feed/            # FeedViewModel
│   └── Profile/         # ProfileViewModel
│
├── Services/            # 외부 서비스
│   ├── Weather/         # WeatherService (OpenWeatherMap)
│   ├── Hospital/        # HospitalService (카카오 로컬 API)
│   └── Storage/         # CoreDataService
│
├── Utils/               # 유틸리티
│   ├── LocationManager  # 위치 서비스 관리
│   └── Extensions/      # Swift 확장
│
└── Components/          # 재사용 컴포넌트
    ├── Cards/           # 카드 UI
    └── Common/          # 공통 버튼, 텍스트필드 등
```

## 주요 파일 설명

### 핵심 ViewModel

| 파일 | 설명 |
|------|------|
| `WalkViewModel.swift` | 산책 추적 싱글톤, Timer/GPS 관리 |
| `HomeViewModel.swift` | 날씨 정보, 한국어 위치명 |
| `HospitalViewModel.swift` | 주변 병원 검색 |

### 서비스

| 파일 | 설명 |
|------|------|
| `WeatherService.swift` | OpenWeatherMap API |
| `HospitalService.swift` | 카카오 로컬 API |
| `CoreDataService.swift` | 로컬 데이터 저장 |

### 지도 관련

| 파일 | 설명 |
|------|------|
| `WalkMapView.swift` | 산책 경로 표시 (카카오맵 WebView) |
| `KakaoMapView.swift` | 병원 마커 표시 (카카오맵 WebView) |
| `docs/walk.html` | 산책 지도 HTML |
| `docs/hospital.html` | 병원 지도 HTML |

## API 키 관리

API 키는 `Config/APIKeys.swift`에서 관리됩니다:

```swift
enum APIKeys {
    static let kakaoMapKey = "YOUR_KAKAO_MAP_KEY"
    static let kakaoRestKey = "YOUR_KAKAO_REST_KEY"
    static let openWeatherKey = "YOUR_OPENWEATHER_KEY"
}
```

코드에서 사용:
```swift
private let apiKey = APIKeys.kakaoMapKey
```

> **보안**: `APIKeys.swift`는 `.gitignore`에 포함되어 원격 저장소에 업로드되지 않습니다.
