import UIKit

struct AnalysisScores {
    let sharpness: Double
    let faceQuality: Double
    let eyesOpen: Double
    let exposure: Double
    let composition: Double

    var totalScore: Double {
        sharpness * 0.25
        + faceQuality * 0.25
        + eyesOpen * 0.25
        + exposure * 0.15
        + composition * 0.10
    }

    var faceDetected: Bool {
        faceQuality > 0 || eyesOpen > 0
    }

    var details: [(String, Double)] {
        [
            ("선명도", sharpness),
            ("얼굴 품질", faceQuality),
            ("눈 뜨임", eyesOpen),
            ("노출", exposure),
            ("구도", composition)
        ]
    }
}

struct PhotoCandidate: Identifiable {
    let id = UUID()
    let image: UIImage
    let assetIdentifier: String?
    var scores: AnalysisScores?
}

enum SortCriteria: String, CaseIterable {
    case totalScore = "총점순"
    case sharpness = "선명도순"
    case faceQuality = "얼굴 품질순"
    case eyesOpen = "눈 뜨임순"
    case exposure = "노출순"
    case composition = "구도순"

    func score(from s: AnalysisScores) -> Double {
        switch self {
        case .totalScore: return s.totalScore
        case .sharpness: return s.sharpness
        case .faceQuality: return s.faceQuality
        case .eyesOpen: return s.eyesOpen
        case .exposure: return s.exposure
        case .composition: return s.composition
        }
    }
}
