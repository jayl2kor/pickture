import UIKit

enum PhotoMode: String, CaseIterable {
    case portrait = "인물 사진"
    case fullBody = "전신 사진"
}

struct AnalysisScores {
    let photoMode: PhotoMode
    let sharpness: Double
    // Portrait-specific
    let faceQuality: Double
    let eyesOpen: Double
    // Full-body-specific
    let bodyDetection: Double
    let poseStability: Double
    // Shared
    let exposure: Double
    let composition: Double

    var totalScore: Double {
        switch photoMode {
        case .portrait:
            return sharpness * 0.25
                + faceQuality * 0.25
                + eyesOpen * 0.25
                + exposure * 0.15
                + composition * 0.10
        case .fullBody:
            return sharpness * 0.30
                + bodyDetection * 0.25
                + poseStability * 0.15
                + exposure * 0.15
                + composition * 0.15
        }
    }

    var subjectDetected: Bool {
        switch photoMode {
        case .portrait: return faceQuality > 0 || eyesOpen > 0
        case .fullBody: return bodyDetection > 0
        }
    }

    var details: [(String, Double)] {
        switch photoMode {
        case .portrait:
            return [
                ("선명도", sharpness),
                ("얼굴 품질", faceQuality),
                ("눈 뜨임", eyesOpen),
                ("노출", exposure),
                ("구도", composition)
            ]
        case .fullBody:
            return [
                ("선명도", sharpness),
                ("신체 감지", bodyDetection),
                ("포즈", poseStability),
                ("노출", exposure),
                ("구도", composition)
            ]
        }
    }

    // Convenience initializer for portrait mode (backward compat)
    init(sharpness: Double, faceQuality: Double, eyesOpen: Double, exposure: Double, composition: Double) {
        self.photoMode = .portrait
        self.sharpness = sharpness
        self.faceQuality = faceQuality
        self.eyesOpen = eyesOpen
        self.bodyDetection = 0
        self.poseStability = 0
        self.exposure = exposure
        self.composition = composition
    }

    // Full initializer
    init(photoMode: PhotoMode, sharpness: Double, faceQuality: Double = 0, eyesOpen: Double = 0,
         bodyDetection: Double = 0, poseStability: Double = 0, exposure: Double, composition: Double) {
        self.photoMode = photoMode
        self.sharpness = sharpness
        self.faceQuality = faceQuality
        self.eyesOpen = eyesOpen
        self.bodyDetection = bodyDetection
        self.poseStability = poseStability
        self.exposure = exposure
        self.composition = composition
    }
}

struct PhotoCandidate: Identifiable {
    let id = UUID()
    let image: UIImage
    let assetIdentifier: String?
    var scores: AnalysisScores?
    var isProtected: Bool = false
}

enum SortCriteria: String, CaseIterable {
    case totalScore = "총점순"
    case sharpness = "선명도순"
    case faceQuality = "얼굴 품질순"
    case eyesOpen = "눈 뜨임순"
    case bodyDetection = "신체 감지순"
    case poseStability = "포즈순"
    case exposure = "노출순"
    case composition = "구도순"

    func score(from s: AnalysisScores) -> Double {
        switch self {
        case .totalScore: return s.totalScore
        case .sharpness: return s.sharpness
        case .faceQuality: return s.faceQuality
        case .eyesOpen: return s.eyesOpen
        case .bodyDetection: return s.bodyDetection
        case .poseStability: return s.poseStability
        case .exposure: return s.exposure
        case .composition: return s.composition
        }
    }

    static func cases(for mode: PhotoMode) -> [SortCriteria] {
        switch mode {
        case .portrait:
            return [.totalScore, .sharpness, .faceQuality, .eyesOpen, .exposure, .composition]
        case .fullBody:
            return [.totalScore, .sharpness, .bodyDetection, .poseStability, .exposure, .composition]
        }
    }
}
