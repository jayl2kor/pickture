import SwiftUI
import PhotosUI
import Photos

@MainActor
final class PhotoViewModel: ObservableObject {
    @Published var selectedItems: [PhotosPickerItem] = [] {
        didSet { candidates = [] }
    }
    @Published var candidates: [PhotoCandidate] = []
    @Published var isLoading = false
    @Published var isAnalyzing = false
    @Published var progressCurrent = 0
    @Published var progressTotal = 0
    @Published var isFavorited = false
    @Published var topN = 3

    private let analyzer = ImageAnalyzer()
    private var analysisTask: Task<Void, Never>?

    func reset() {
        cancelAnalysis()
        selectedItems = []
        candidates = []
        isFavorited = false
        topN = 3
    }

    func cancelAnalysis() {
        analysisTask?.cancel()
        analysisTask = nil
        isLoading = false
        isAnalyzing = false
    }

    func loadAndAnalyze() {
        guard selectedItems.count > topN else { return }

        analysisTask = Task {
            isLoading = true
            candidates = []

            var images: [(UIImage, String?)] = []
            for item in selectedItems {
                guard !Task.isCancelled else { return }
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    images.append((image, item.itemIdentifier))
                }
            }

            isLoading = false
            guard !Task.isCancelled, !images.isEmpty else { return }

            await runAnalysis(images: images)
        }
    }

    func runAnalysis(images: [(UIImage, String?)]) async {
        isAnalyzing = true
        progressCurrent = 0
        progressTotal = images.count

        candidates = await analyzer.analyze(images: images) { [weak self] current, total in
            self?.progressCurrent = current
            self?.progressTotal = total
        }

        isAnalyzing = false

        #if DEBUG
        print("=== Analysis Complete: \(candidates.count) candidates ===")
        for (i, c) in candidates.enumerated() {
            if let s = c.scores {
                print("[\(i+1)] total=\(Int(s.totalScore*100)) sharp=\(Int(s.sharpness*100)) face=\(Int(s.faceQuality*100)) eyes=\(Int(s.eyesOpen*100)) expo=\(Int(s.exposure*100)) comp=\(Int(s.composition*100))")
            }
        }
        #endif
    }

    func favoriteTopN() {
        let identifiers = candidates.prefix(topN).compactMap(\.assetIdentifier)
        guard !identifiers.isEmpty else { return }

        Task {
            let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            guard status == .authorized || status == .limited else { return }

            let assets = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
            guard assets.count > 0 else { return }

            do {
                try await PHPhotoLibrary.shared().performChanges {
                    assets.enumerateObjects { asset, _, _ in
                        let request = PHAssetChangeRequest(for: asset)
                        request.isFavorite = true
                    }
                }
                isFavorited = true
            } catch {
                #if DEBUG
                print("Failed to favorite: \(error)")
                #endif
            }
        }
    }

    #if DEBUG
    func debugAutoTest() {
        Task {
            isLoading = true
            candidates = []

            // Generate test images with different characteristics
            var images: [(UIImage, String?)] = []
            let configs: [(CGFloat, CGFloat, CGFloat, CGSize)] = [
                (0.9, 0.3, 0.2, CGSize(width: 600, height: 800)),
                (0.2, 0.7, 0.3, CGSize(width: 800, height: 600)),
                (0.3, 0.2, 0.8, CGSize(width: 700, height: 700)),
                (0.8, 0.6, 0.1, CGSize(width: 500, height: 900)),
                (0.5, 0.5, 0.5, CGSize(width: 800, height: 800)),
            ]
            for (r, g, b, size) in configs {
                let renderer = UIGraphicsImageRenderer(size: size)
                let img = renderer.image { ctx in
                    UIColor(red: r, green: g, blue: b, alpha: 1).setFill()
                    ctx.fill(CGRect(origin: .zero, size: size))
                    // Draw a simple face-like oval
                    let cx = size.width / 2, cy = size.height * 0.4
                    UIColor(red: 0.9, green: 0.8, blue: 0.7, alpha: 1).setFill()
                    ctx.cgContext.fillEllipse(in: CGRect(x: cx - 60, y: cy - 80, width: 120, height: 160))
                }
                images.append((img, nil))
            }

            isLoading = false
            await runAnalysis(images: images)
        }
    }
    #endif
}
