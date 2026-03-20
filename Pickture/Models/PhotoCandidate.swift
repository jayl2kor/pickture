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
