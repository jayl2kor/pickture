import SwiftUI

// MARK: - Score Bar Component

private struct ScoreBar: View {
    let label: String
    let icon: String
    let score: Double
    let color: Color

    @State private var animatedScore: Double = 0

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(color.opacity(0.9))
                .frame(width: 16)

            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 56, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 6)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.7), color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * animatedScore, height: 6)
                }
                .frame(maxHeight: .infinity, alignment: .center)
            }
            .frame(height: 14)

            Text("\(Int(score * 100))")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(color)
                .frame(width: 28, alignment: .trailing)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.1)) {
                animatedScore = score
            }
        }
    }
}

// MARK: - Rank Badge

private struct RankBadge: View {
    let rank: Int

    private var badgeSize: CGFloat {
        rank == 1 ? 44 : 38
    }

    private var iconName: String {
        switch rank {
        case 1: return "crown.fill"
        case 2: return "star.fill"
        case 3: return "star.fill"
        default: return "circle.fill"
        }
    }

    private var gradientColors: [Color] {
        switch rank {
        case 1: return [Color(red: 1.0, green: 0.84, blue: 0.3), Color(red: 0.95, green: 0.7, blue: 0.1)]
        case 2: return [Color(red: 0.82, green: 0.84, blue: 0.88), Color(red: 0.65, green: 0.67, blue: 0.72)]
        case 3: return [Color(red: 0.85, green: 0.6, blue: 0.35), Color(red: 0.72, green: 0.45, blue: 0.2)]
        default: return [.blue, .blue]
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

            VStack(spacing: -2) {
                if rank == 1 {
                    Image(systemName: iconName)
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

    private var ringColor: Color {
        switch rank {
        case 1: return Color(red: 1.0, green: 0.84, blue: 0.3)
        case 2: return Color(red: 0.82, green: 0.84, blue: 0.88)
        case 3: return Color(red: 0.85, green: 0.6, blue: 0.35)
        default: return .blue
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 4)
                .frame(width: 60, height: 60)

            Circle()
                .trim(from: 0, to: animatedScore)
                .stroke(
                    LinearGradient(
                        colors: [ringColor.opacity(0.6), ringColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 60, height: 60)
                .rotationEffect(.degrees(-90))

            VStack(spacing: -1) {
                Text("\(Int(score * 100))")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("점")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0).delay(0.2)) {
                animatedScore = score
            }
        }
    }
}

// MARK: - ResultCardView

struct ResultCardView: View {
    let candidate: PhotoCandidate
    let rank: Int

    private var imageHeight: CGFloat {
        rank == 1 ? 340 : 280
    }

    private var scoreIconMap: [String: String] {
        [
            "선명도": "camera.aperture",
            "얼굴 품질": "face.smiling",
            "눈 뜨임": "eye",
            "노출": "sun.max",
            "구도": "squareshape.split.3x3"
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Photo with overlays
            ZStack(alignment: .topLeading) {
                Image(uiImage: candidate.image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .frame(height: imageHeight)
                    .clipped()

                // Bottom gradient overlay for readability
                VStack {
                    Spacer()
                    LinearGradient(
                        colors: [.clear, Color.black.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 100)
                }

                // Rank badge
                RankBadge(rank: rank)
                    .padding(12)

                // Score ring in bottom-right
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
            .frame(height: imageHeight)
            .clipped()

            // Score details
            if let scores = candidate.scores {
                VStack(spacing: 8) {
                    ForEach(scores.details, id: \.0) { name, score in
                        ScoreBar(
                            label: name,
                            icon: scoreIconMap[name] ?? "circle",
                            score: score,
                            color: scoreColor(score)
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.12), Color.white.opacity(0.04)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.3), radius: 12, y: 6)
    }

    private func scoreColor(_ score: Double) -> Color {
        if score >= 0.7 { return Color(red: 0.3, green: 0.85, blue: 0.6) }
        if score >= 0.4 { return Color(red: 1.0, green: 0.75, blue: 0.3) }
        return Color(red: 1.0, green: 0.4, blue: 0.4)
    }
}
