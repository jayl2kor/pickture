import UIKit
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins

final class ImageAnalyzer {
    private let ciContext = CIContext()

    func analyze(images: [(UIImage, String?)], progress: @escaping (Int, Int) -> Void) async -> [PhotoCandidate] {
        let total = images.count
        var candidates: [PhotoCandidate] = []

        for (index, (image, identifier)) in images.enumerated() {
            let scores = await analyzeOnBackground(image)
            candidates.append(PhotoCandidate(image: image, assetIdentifier: identifier, scores: scores))
            await MainActor.run { progress(index + 1, total) }
        }

        return candidates
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
        let exposure = measureExposure(ciImage)

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
        return min(sqrt(edgeStrength) * 4.5, 1.0)
    }

    // MARK: - Exposure

    private func measureExposure(_ ciImage: CIImage) -> Double {
        let average = CIFilter.areaAverage()
        average.inputImage = ciImage
        average.extent = ciImage.extent

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
        return min(max((minRatio - 0.1) / 0.3, 0), 1.0)
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

        // Distance to image center
        let centerDist = sqrt(pow(centerX - 0.5, 2) + pow(centerY - 0.5, 2))

        // Distance to nearest rule-of-thirds intersection
        let thirdPoints: [(Double, Double)] = [
            (1.0/3, 1.0/3), (1.0/3, 2.0/3),
            (2.0/3, 1.0/3), (2.0/3, 2.0/3)
        ]
        let thirdDist = thirdPoints.map { sqrt(pow(centerX - $0.0, 2) + pow(centerY - $0.1, 2)) }.min() ?? 1.0

        // Use the better score of center vs thirds
        let bestDist = min(centerDist, thirdDist)
        // Max possible distance is ~0.47 (corner to thirds point); normalize
        return max(1.0 - bestDist * 2.5, 0)
    }
}
