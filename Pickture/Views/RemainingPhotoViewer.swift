import SwiftUI

struct RemainingPhotoViewer: View {
    let candidates: [PhotoCandidate]
    @Binding var currentIndex: Int
    let onToggleProtection: (PhotoCandidate) -> Void
    let onDismiss: () -> Void

    private let textPrimary = Color(red: 0.2, green: 0.15, blue: 0.25)
    private let lockColor = Color(red: 0.4, green: 0.65, blue: 0.95)

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView(selection: $currentIndex) {
                ForEach(Array(candidates.enumerated()), id: \.element.id) { index, candidate in
                    ZStack {
                        Image(uiImage: candidate.image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))

            // Top bar: close + lock
            VStack {
                HStack {
                    // Close button
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }

                    Spacer()

                    // Lock toggle
                    if currentIndex >= 0 && currentIndex < candidates.count {
                        let candidate = candidates[currentIndex]
                        Button {
                            onToggleProtection(candidate)
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            Image(systemName: candidate.isProtected ? "lock.fill" : "lock.open")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(candidate.isProtected ? lockColor : .white.opacity(0.8))
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle().fill(
                                        candidate.isProtected
                                        ? lockColor.opacity(0.25)
                                        : Color.white.opacity(0.2)
                                    )
                                )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                Spacer()

                // Bottom: score badge
                if currentIndex >= 0 && currentIndex < candidates.count,
                   let scores = candidates[currentIndex].scores {
                    HStack(spacing: 6) {
                        Text("\(Int(scores.totalScore * 100))")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("점")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule().fill(.ultraThinMaterial)
                    )
                    .padding(.bottom, 40)
                }
            }
        }
    }
}
