import SwiftUI

// MARK: - Score Bar Component

private struct ScoreBar: View {
    let label: String
    let icon: String
    let score: Double
    let color: Color
    var staggerIndex: Int = 0

    @State private var animatedScore: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(color)
                .frame(width: 16)

            Text(label)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(Color(red: 0.4, green: 0.35, blue: 0.45))
                .frame(width: 60, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(red: 0.94, green: 0.92, blue: 0.96))
                        .frame(height: 8)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.6), color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * animatedScore, height: 8)
                }
                .frame(maxHeight: .infinity, alignment: .center)
            }
            .frame(height: 14)

            Text("\(Int(score * 100))")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(color)
                .frame(width: 28, alignment: .trailing)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label) \(Int(score * 100))점")
        .onAppear {
            if reduceMotion {
                animatedScore = score
            } else {
                // Staggered reveal: 40ms between each bar, faster animation
                withAnimation(.easeOut(duration: 0.4).delay(0.08 + Double(staggerIndex) * 0.04)) {
                    animatedScore = score
                }
            }
        }
    }
}

// MARK: - Rank Badge

private struct RankBadge: View {
    let rank: Int

    private var badgeSize: CGFloat {
        switch rank {
        case 1: return 48
        case 2: return 40
        default: return 36
        }
    }

    private var gradientColors: [Color] {
        switch rank {
        case 1: return [Color(red: 1.0, green: 0.75, blue: 0.3), Color(red: 1.0, green: 0.55, blue: 0.25)]
        case 2: return [Color(red: 0.88, green: 0.72, blue: 0.82), Color(red: 0.75, green: 0.55, blue: 0.7)]
        case 3: return [Color(red: 0.7, green: 0.78, blue: 0.9), Color(red: 0.5, green: 0.6, blue: 0.78)]
        default: return [Color.pink.opacity(0.6), Color.pink.opacity(0.4)]
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: badgeSize, height: badgeSize)
                .shadow(color: gradientColors[0].opacity(0.5), radius: 6, y: 2)

            VStack(spacing: 0) {
                if rank == 1 {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .offset(y: 1)
                }
                Text("\(rank)")
                    .font(.system(size: rank == 1 ? 16 : 15, weight: .black, design: .rounded))
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - Circular Score Ring

private struct ScoreRing: View {
    let score: Double
    let rank: Int

    @State private var animatedScore: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var ringColor: Color {
        switch rank {
        case 1: return Color(red: 1.0, green: 0.6, blue: 0.3)
        case 2: return Color(red: 0.82, green: 0.6, blue: 0.75)
        case 3: return Color(red: 0.55, green: 0.65, blue: 0.82)
        default: return Color.pink
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.5), lineWidth: 5)
                .frame(width: 60, height: 60)

            Circle()
                .trim(from: 0, to: animatedScore)
                .stroke(
                    LinearGradient(
                        colors: [ringColor.opacity(0.6), ringColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .frame(width: 60, height: 60)
                .rotationEffect(.degrees(-90))

            VStack(spacing: -1) {
                Text("\(Int(score * 100))")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("점")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .onAppear {
            if reduceMotion {
                animatedScore = score
            } else {
                withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                    animatedScore = score
                }
            }
        }
    }
}

// MARK: - ResultCardView

struct ResultCardView: View {
    let candidate: PhotoCandidate
    let rank: Int

    // Image aspect ratio (width:height). Higher = shorter image
    private var imageAspect: CGFloat {
        rank == 1 ? 0.85 : 1.0
    }

    private static let scoreIconMap: [String: String] = [
        "선명도": "camera.aperture",
        "얼굴 품질": "face.smiling",
        "눈 뜨임": "eye",
        "노출": "sun.max.fill",
        "구도": "squareshape.split.3x3"
    ]

    /// Each score category gets its own vivid color
    private static let scoreColorMap: [String: Color] = [
        "선명도": Color(red: 0.4, green: 0.7, blue: 1.0),       // bright sky blue
        "얼굴 품질": Color(red: 1.0, green: 0.5, blue: 0.6),    // coral pink
        "눈 뜨임": Color(red: 0.55, green: 0.8, blue: 0.45),    // fresh green
        "노출": Color(red: 1.0, green: 0.75, blue: 0.3),        // warm amber
        "구도": Color(red: 0.7, green: 0.5, blue: 0.9)          // soft violet
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                Image(uiImage: candidate.image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .aspectRatio(imageAspect, contentMode: .fit)
                    .clipped()

                VStack {
                    Spacer()
                    LinearGradient(
                        colors: [.clear, Color.black.opacity(0.4)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 100)
                }

                RankBadge(rank: rank)
                    .padding(12)

                if let scores = candidate.scores {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            ScoreRing(score: scores.totalScore, rank: rank)
                                .padding(12)
                        }
                    }
                }
            }
            .clipShape(Rectangle())

            if let scores = candidate.scores {
                VStack(spacing: 8) {
                    if !scores.faceDetected {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(Color.orange)
                            Text("얼굴이 감지되지 않아 일부 항목이 0점입니다")
                                .font(.system(size: 12, design: .rounded))
                                .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.4))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.orange.opacity(0.08))
                        )
                    }

                    ForEach(Array(scores.details.enumerated()), id: \.element.0) { index, detail in
                        ScoreBar(
                            label: detail.0,
                            icon: Self.scoreIconMap[detail.0] ?? "circle",
                            score: detail.1,
                            color: Self.scoreColorMap[detail.0] ?? scoreColor(detail.1),
                            staggerIndex: index
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            rank == 1
            ? RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.8, blue: 0.4),
                            Color(red: 1.0, green: 0.6, blue: 0.3),
                            Color(red: 1.0, green: 0.8, blue: 0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
            : nil
        )
        .shadow(
            color: rank == 1
                ? Color(red: 1.0, green: 0.6, blue: 0.3).opacity(0.2)
                : Color(red: 0.6, green: 0.4, blue: 0.7).opacity(0.15),
            radius: rank == 1 ? 16 : 12,
            y: 6
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(rank)위 사진, 총점 \(Int((candidate.scores?.totalScore ?? 0) * 100))점")
    }

    private func scoreColor(_ score: Double) -> Color {
        if score >= 0.7 { return Color(red: 0.35, green: 0.78, blue: 0.65) }
        if score >= 0.4 { return Color(red: 1.0, green: 0.65, blue: 0.35) }
        return Color(red: 0.9, green: 0.4, blue: 0.45)
    }
}
