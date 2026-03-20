# ImageChooser - Claude Code 가이드

## 프로젝트 개요

여러 장의 비슷한 인물 사진 중 가장 잘 나온 사진 3장을 자동 선별하는 iOS 앱.
상세 요구사항은 `REQUIREMENTS.md` 참조.

## 빌드 & 실행

```bash
# Xcode 프로젝트 생성 (xcodegen 필요)
xcodegen generate

# 빌드 (Xcode 필요)
xcodebuild -project ImageChooser.xcodeproj -scheme ImageChooser -sdk iphonesimulator build
```

## 프로젝트 구조

```
ImageChooser/
├── ImageChooserApp.swift          # @main 앱 진입점
├── Info.plist                     # NSPhotoLibraryUsageDescription 포함
├── Models/
│   └── PhotoCandidate.swift       # PhotoCandidate, AnalysisScores 모델
├── Services/
│   └── ImageAnalyzer.swift        # 이미지 분석 엔진
├── ViewModels/
│   └── PhotoViewModel.swift       # ObservableObject, UI 상태 관리
└── Views/
    ├── ContentView.swift          # 메인 화면 (선택 → 분석 → 결과)
    └── ResultCardView.swift       # 순위 카드 컴포넌트
```

## 구현 규칙

### 타겟 환경
- iOS 16.0+, iPhone only
- Swift 5.10, SwiftUI
- 외부 의존성 없음 (Apple 프레임워크만 사용)

### 사용 프레임워크
- `PhotosUI`: PhotosPicker로 다중 사진 선택
- `Vision`: VNDetectFaceCaptureQualityRequest (얼굴 품질), VNDetectFaceLandmarksRequest (눈 분석)
- `CoreImage`: CIEdges (선명도), CIAreaAverage (노출)

### 이미지 분석 (ImageAnalyzer)

5가지 평가 기준, 각각 0~1 점수:

1. **선명도 (0.25)**: CIEdges 필터 적용 → CIAreaAverage로 엣지 강도 평균 산출
2. **얼굴 품질 (0.25)**: VNDetectFaceCaptureQualityRequest → faceCaptureQuality 속성 사용
3. **눈 뜨임 (0.25)**: VNDetectFaceLandmarksRequest → leftEye/rightEye 랜드마크의 normalizedPoints에서 종횡비(세로/가로) 계산. 비율 높을수록 눈이 열려있음. 여러 얼굴일 경우 최솟값 사용 (한 명이라도 눈 감으면 감점)
4. **노출 (0.15)**: CIAreaAverage로 평균 밝기 측정. 이상적 밝기(0.45~0.55) 대비 편차로 점수 산출
5. **구도 (0.10)**: 얼굴 boundingBox 중심이 화면 중앙 또는 삼등분선에 가까울수록 고점수

성능 최적화:
- 분석 전 이미지를 긴 변 기준 1024px로 리사이즈
- 사진별 분석은 순차 처리 (메모리 보호), 진행률 콜백 제공

얼굴 미감지 시: faceQuality=0, eyesOpen=0, composition=0.5

### ViewModel (PhotoViewModel)

ObservableObject로 구현. @Published 프로퍼티:
- `selectedItems: [PhotosPickerItem]` - 선택된 사진
- `candidates: [PhotoCandidate]` - 분석 결과 (총점 내림차순 정렬)
- `isLoading: Bool` - 이미지 로딩 중
- `isAnalyzing: Bool` - 분석 중
- `progress: (current: Int, total: Int)` - 분석 진행률

### UI (Views)

**ContentView**: 단일 화면, ScrollView 기반
- 상단: PhotosPicker 버튼 + 선택된 사진 수
- 중단: "분석 시작" 버튼 (4장 이상 선택 시 활성화), 분석 중 ProgressView
- 하단: 결과 영역
  - 상위 3장: ResultCardView (큰 카드, 순위 표시, 항목별 점수 바)
  - 나머지: 2열 그리드, 사진 + 총점

**ResultCardView**: 순위 카드
- 사진 썸네일, 순위 번호, 총점 (100점 환산)
- 항목별 점수를 ProgressView 바로 시각화
- 항목 이름은 한국어 (선명도, 얼굴 품질, 눈 뜨임, 노출, 구도)

### 코딩 컨벤션
- 한국어 UI 텍스트, 영어 코드
- 간결한 SwiftUI 코드, 불필요한 추상화 금지
- 에러 처리는 최소한으로 (guard + 기본값 반환)
