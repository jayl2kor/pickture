import UIKit
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins

final class ImageAnalyzer {
    private let ciContext = CIContext()

    /// Max concurrent analyses to balance speed vs memory
    private let maxConcurrency = 3

    func analyze(images: [(UIImage, String?)], progress: @escaping (Int, Int) -> Void) async -> [PhotoCandidate] {
        let total = images.count
        var results = [(Int, PhotoCandidate)]()
        results.reserveCapacity(total)

        var completed = 0

        // Process in chunks for bounded concurrency
        for chunkStart in stride(from: 0, to: total, by: maxConcurrency) {
            let chunkEnd = min(chunkStart + maxConcurrency, total)
            let chunk = Array(images[chunkStart..<chunkEnd])

            await withTaskGroup(of: (Int, PhotoCandidate).self) { group in
                for (offset, (image, identifier)) in chunk.enumerated() {
                    let globalIndex = chunkStart + offset
                    group.addTask {
                        let scores = await self.analyzeOnBackground(image)
                        return (globalIndex, PhotoCandidate(image: image, assetIdentifier: identifier, scores: scores))
                    }
                }

                for await result in group {
                    results.append(result)
                    completed += 1
                    await MainActor.run { progress(completed, total) }
                }
            }
        }

        // Restore original order
        return results.sorted(by: { $0.0 < $1.0 }).map(\.1)
    }

    private func analyzeOnBackground(_ image: UIImage) async -> AnalysisScores {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [self] in
                let resized = resizeForAnalysis(image)
                let scores = analyzeImage(resized)
                continuation.resume(returning: scores)
            }
        }
    }

    // MARK: - Resize

    private func resizeForAnalysis(_ image: UIImage) -> UIImage {
        let maxDimension: CGFloat = 1024
        let size = image.size
        guard max(size.width, size.height) > maxDimension else { return image }

        let scale = maxDimension / max(size.width, size.height)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    // MARK: - Full Analysis

    private func analyzeImage(_ image: UIImage) -> AnalysisScores {
        guard let cgImage = image.cgImage else {
            return AnalysisScores(sharpness: 0, faceQuality: 0, eyesOpen: 0, exposure: 0.5, composition: 0.5)
        }

        let ciImage = CIImage(cgImage: cgImage)
        let sharpness = measureSharpness(ciImage)

        // Batch all Vision requests to share face detection pass
        let faceRectsRequest = VNDetectFaceRectanglesRequest()
        let faceQualityRequest = VNDetectFaceCaptureQualityRequest()
        let faceLandmarksRequest = VNDetectFaceLandmarksRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([faceRectsRequest, faceQualityRequest, faceLandmarksRequest])

        let faceObservations = faceRectsRequest.results ?? []
        let faceQuality = (faceQualityRequest.results ?? [])
            .compactMap { $0.faceCaptureQuality }
            .map { Double($0) }
            .reduce(0, +) / max(Double((faceQualityRequest.results ?? []).count), 1)
        let eyesOpen = measureEyesOpenFrom(faceLandmarksRequest.results ?? [], imageSize: CGSize(width: cgImage.width, height: cgImage.height))
        let composition = measureComposition(faceObservations, imageSize: image.size)

        // Measure exposure in face region if available, otherwise whole image
        let largestFace = faceObservations.max(by: { $0.boundingBox.width * $0.boundingBox.height < $1.boundingBox.width * $1.boundingBox.height })
        let exposure = measureExposure(ciImage, faceRegion: largestFace?.boundingBox)

        return AnalysisScores(
            sharpness: sharpness,
            faceQuality: faceQuality,
            eyesOpen: eyesOpen,
            exposure: exposure,
            composition: composition
        )
    }

    // MARK: - Sharpness

    private func measureSharpness(_ ciImage: CIImage) -> Double {
        let edges = CIFilter.edges()
        edges.inputImage = ciImage
        edges.intensity = 1.0

        guard let edgeOutput = edges.outputImage else { return 0 }

        let average = CIFilter.areaAverage()
        average.inputImage = edgeOutput
        average.extent = edgeOutput.extent

        guard let avgOutput = average.outputImage else { return 0 }

        var pixel = [Float32](repeating: 0, count: 4)
        ciContext.render(avgOutput,
                         toBitmap: &pixel,
                         rowBytes: 4 * MemoryLayout<Float32>.size,
                         bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                         format: .RGBAf,
                         colorSpace: CGColorSpaceCreateDeviceRGB())

        let edgeStrength = Double(pixel[0] + pixel[1] + pixel[2]) / 3.0
        #if DEBUG
        print("[Sharpness] raw edgeStrength=\(edgeStrength)")
        #endif
        return min(pow(edgeStrength, 0.35) * 3.0, 1.0)
    }

    // MARK: - Exposure

    private func measureExposure(_ ciImage: CIImage, faceRegion: CGRect? = nil) -> Double {
        // If face detected, measure exposure in face region only
        let targetImage: CIImage
        if let faceBox = faceRegion {
            // Vision boundingBox is normalized (0-1), convert to pixel coordinates
            let extent = ciImage.extent
            let faceRect = CGRect(
                x: extent.origin.x + faceBox.origin.x * extent.width,
                y: extent.origin.y + faceBox.origin.y * extent.height,
                width: faceBox.width * extent.width,
                height: faceBox.height * extent.height
            )
            targetImage = ciImage.cropped(to: faceRect)
        } else {
            targetImage = ciImage
        }

        let average = CIFilter.areaAverage()
        average.inputImage = targetImage
        average.extent = targetImage.extent

        guard let avgOutput = average.outputImage else { return 0.5 }

        var pixel = [UInt8](repeating: 0, count: 4)
        ciContext.render(avgOutput,
                         toBitmap: &pixel,
                         rowBytes: 4,
                         bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                         format: .RGBA8,
                         colorSpace: CGColorSpaceCreateDeviceRGB())

        let r = Double(pixel[0]) / 255.0
        let g = Double(pixel[1]) / 255.0
        let b = Double(pixel[2]) / 255.0
        let luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b

        let deviation = abs(luminance - 0.5)
        return max(1.0 - deviation * 2.0, 0.0)
    }

    // MARK: - Face Detection

    private func detectFaces(_ cgImage: CGImage) -> [VNFaceObservation] {
        let request = VNDetectFaceRectanglesRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])
        return request.results ?? []
    }

    // MARK: - Face Quality

    private func measureFaceQuality(_ cgImage: CGImage) -> Double {
        let request = VNDetectFaceCaptureQualityRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])

        guard let results = request.results, !results.isEmpty else { return 0 }

        let qualities = results.compactMap { $0.faceCaptureQuality }.map { Double($0) }
        guard !qualities.isEmpty else { return 0 }
        return qualities.reduce(0, +) / Double(qualities.count)
    }

    // MARK: - Eyes Open

    private func measureEyesOpenFrom(_ results: [VNFaceObservation], imageSize: CGSize) -> Double {
        guard !results.isEmpty else { return 0 }

        var eyeRatios: [Double] = []

        for face in results {
            guard let landmarks = face.landmarks else { continue }
            var faceMinRatio: Double = 1.0

            if let leftEye = landmarks.leftEye {
                let points = leftEye.pointsInImage(imageSize: imageSize)
                let ratio = eyeAspectRatio(points)
                faceMinRatio = min(faceMinRatio, ratio)
            }
            if let rightEye = landmarks.rightEye {
                let points = rightEye.pointsInImage(imageSize: imageSize)
                let ratio = eyeAspectRatio(points)
                faceMinRatio = min(faceMinRatio, ratio)
            }

            eyeRatios.append(faceMinRatio)
        }

        guard !eyeRatios.isEmpty else { return 0 }
        let minRatio = eyeRatios.min() ?? 0
        return min(max((minRatio - 0.08) / 0.32, 0), 1.0)
    }

    private func eyeAspectRatio(_ points: [CGPoint]) -> Double {
        guard points.count >= 4 else { return 0 }
        let ys = points.map(\.y)
        let xs = points.map(\.x)
        let height = (ys.max() ?? 0) - (ys.min() ?? 0)
        let width = (xs.max() ?? 0) - (xs.min() ?? 0)
        guard width > 0 else { return 0 }
        return height / width
    }

    // MARK: - Composition

    private func measureComposition(_ faces: [VNFaceObservation], imageSize: CGSize) -> Double {
        guard let face = faces.max(by: { $0.boundingBox.width * $0.boundingBox.height < $1.boundingBox.width * $1.boundingBox.height }) else {
            return 0.5
        }

        let box = face.boundingBox
        let centerX = box.midX
        let centerY = box.midY

        // --- Position score: center or rule-of-thirds ---
        let centerDist = sqrt(pow(centerX - 0.5, 2) + pow(centerY - 0.5, 2))

        let thirdPoints: [(Double, Double)] = [
            (1.0/3, 1.0/3), (1.0/3, 2.0/3),
            (2.0/3, 1.0/3), (2.0/3, 2.0/3)
        ]
        let thirdDist = thirdPoints.map { sqrt(pow(centerX - $0.0, 2) + pow(centerY - $0.1, 2)) }.min() ?? 1.0

        let bestDist = min(centerDist, thirdDist)
        let positionScore = max(1.0 - bestDist * 2.5, 0)

        // --- Face size score: 10~45% of frame is ideal ---
        let faceArea = box.width * box.height
        let sizeScore: Double
        if faceArea < 0.03 {
            // Very small face — poor framing
            sizeScore = faceArea / 0.03
        } else if faceArea <= 0.45 {
            // Good range
            sizeScore = 1.0
        } else {
            // Too close / cropped
            sizeScore = max(1.0 - (faceArea - 0.45) * 3.0, 0.3)
        }

        return positionScore * 0.6 + sizeScore * 0.4
    }
}
