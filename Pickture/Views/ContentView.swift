import SwiftUI
import PhotosUI

struct ContentView: View {
    @StateObject private var viewModel = PhotoViewModel()
    @State private var pulseAnalyze = false

    // Accent gradient used throughout the app
    private let accentGradient = LinearGradient(
        colors: [Color(red: 0.4, green: 0.35, blue: 1.0), Color(red: 0.7, green: 0.3, blue: 0.95)],
        startPoint: .leading,
        endPoint: .trailing
    )

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.09, green: 0.08, blue: 0.20),
                    Color(red: 0.11, green: 0.09, blue: 0.22),
                    Color(red: 0.07, green: 0.07, blue: 0.16)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    if viewModel.candidates.isEmpty {
                        headerSection
                        selectionSection
                            .padding(.top, 8)
                        if !viewModel.selectedItems.isEmpty {
                            topNSelector
                                .padding(.top, 16)
                        }
                        analyzeSection
                            .padding(.top, 24)
                    }
                    resultsSection
                        .padding(.top, viewModel.candidates.isEmpty ? 28 : 16)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark)
        #if DEBUG
        .onAppear {
            if CommandLine.arguments.contains("--auto-test") {
                viewModel.debugAutoTest()
            }
        }
        #endif
        .onChange(of: viewModel.isAnalyzing) { newValue in
            // When analysis finishes (isAnalyzing goes from true to false)
            if !newValue && !viewModel.candidates.isEmpty {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    // triggers resultsSection animation
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            // Decorative top element
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(accentGradient)

                Text("AI Photo Selector")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(2)
                    .textCase(.uppercase)

                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(accentGradient)
            }
            .padding(.top, 16)

            Text("베스트 사진 선별")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            Text("여러 장의 인물 사진 중 가장 잘 나온 사진을\nAI가 자동으로 골라드립니다")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.45))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.top, 2)
        }
        .padding(.bottom, 8)
    }

    // MARK: - Photo Selection

    private var selectionSection: some View {
        VStack(spacing: 16) {
            PhotosPicker(
                selection: $viewModel.selectedItems,
                maxSelectionCount: 50,
                matching: .images
            ) {
                if viewModel.selectedItems.isEmpty {
                    // Empty state - dashed border card
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.06))
                                .frame(width: 64, height: 64)

                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 26, weight: .medium))
                                .foregroundStyle(accentGradient)
                        }

                        Text("사진 선택하기")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.85))

                        Text("4장 이상의 인물 사진을 선택해주세요")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.35))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.03))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(
                                style: StrokeStyle(lineWidth: 1.5, dash: [8, 6])
                            )
                            .foregroundColor(.white.opacity(0.12))
                    )
                } else {
                    // Has selection - compact button with count
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.06))
                                .frame(width: 44, height: 44)

                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(accentGradient)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("사진 선택됨")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white.opacity(0.85))
                            Text("탭하여 변경하기")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.35))
                        }

                        Spacer()

                        // Count pill badge
                        countBadge
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.06))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                }
            }
        }
    }

    private var countBadge: some View {
        HStack(spacing: 4) {
            Text("\(viewModel.selectedItems.count)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text("장")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.4, green: 0.35, blue: 1.0), Color(red: 0.7, green: 0.3, blue: 0.95)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
        .shadow(color: Color(red: 0.5, green: 0.3, blue: 1.0).opacity(0.3), radius: 8, y: 2)
    }

    // MARK: - Analyze Section

    private var analyzeSection: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else if viewModel.isAnalyzing {
                analyzingView
            } else if !viewModel.candidates.isEmpty {
                // Analysis done, don't show button
                EmptyView()
            } else {
                analyzeButton
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white.opacity(0.6)))
                .scaleEffect(1.2)

            Text("사진 불러오는 중...")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    private var analyzingView: some View {
        let total = max(viewModel.progressTotal, 1)
        let progress = Double(viewModel.progressCurrent) / Double(total)
        let percentage = Int(progress * 100)

        return VStack(spacing: 20) {
            // Circular progress
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.06), lineWidth: 6)
                    .frame(width: 80, height: 80)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: [Color(red: 0.4, green: 0.35, blue: 1.0), Color(red: 0.7, green: 0.3, blue: 0.95)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: progress)

                Text("\(percentage)%")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            VStack(spacing: 4) {
                Text("분석 중")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))

                Text("\(viewModel.progressCurrent) / \(viewModel.progressTotal)장 완료")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.04))
        )
    }

    private var topNSelector: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text("선별 장수")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
                Text("상위 몇 장을 선별할지 선택하세요")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.35))
            }

            Spacer()

            HStack(spacing: 0) {
                Button {
                    if viewModel.topN > 1 { viewModel.topN -= 1 }
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(viewModel.topN > 1 ? .white : .white.opacity(0.2))
                        .frame(width: 36, height: 36)
                }
                .disabled(viewModel.topN <= 1)

                Text("\(viewModel.topN)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)

                Button {
                    let maxN = max(viewModel.selectedItems.count - 1, 1)
                    if viewModel.topN < maxN { viewModel.topN += 1 }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(viewModel.topN < viewModel.selectedItems.count - 1 ? .white : .white.opacity(0.2))
                        .frame(width: 36, height: 36)
                }
                .disabled(viewModel.topN >= viewModel.selectedItems.count - 1)
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.08))
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var analyzeButton: some View {
        let isEnabled = viewModel.selectedItems.count > viewModel.topN

        return Button {
            viewModel.loadAndAnalyze()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 17, weight: .semibold))

                Text("분석 시작")
                    .font(.system(size: 17, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Group {
                    if isEnabled {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.4, green: 0.35, blue: 1.0),
                                        Color(red: 0.65, green: 0.3, blue: 0.95)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: Color(red: 0.5, green: 0.3, blue: 1.0).opacity(0.4), radius: 16, y: 4)
                            .scaleEffect(pulseAnalyze ? 1.02 : 1.0)
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.08))
                    }
                }
            )
            .foregroundColor(isEnabled ? .white : .white.opacity(0.3))
        }
        .disabled(!isEnabled)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseAnalyze = true
            }
        }
        .onDisappear {
            pulseAnalyze = false
        }
    }

    // MARK: - Results

    private var resultsSection: some View {
        Group {
            if !viewModel.candidates.isEmpty {
                VStack(spacing: 24) {
                    // Re-select button
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.reset()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 15, weight: .semibold))
                            Text("처음부터 다시 하기")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(.white.opacity(0.85))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.1))
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                    }

                    // TOP N Header
                    topNHeader
                        .transition(.opacity.combined(with: .move(edge: .top)))

                    // Top N cards
                    ForEach(Array(viewModel.candidates.prefix(viewModel.topN).enumerated()), id: \.element.id) { index, candidate in
                        ResultCardView(candidate: candidate, rank: index + 1)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .offset(y: 30)),
                                removal: .opacity
                            ))
                    }

                    // Favorite button
                    favoriteButton

                    // The rest
                    if viewModel.candidates.count > viewModel.topN {
                        remainingSection
                    }
                }
            }
        }
    }

    private var topNHeader: some View {
        HStack(spacing: 8) {
            // Decorative line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, Color.white.opacity(0.15)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            HStack(spacing: 6) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 1.0, green: 0.84, blue: 0.3), Color(red: 0.95, green: 0.7, blue: 0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                Text("TOP \(viewModel.topN)")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
                    .tracking(2)
            }
            .fixedSize()

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.15), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
        }
        .padding(.vertical, 4)
    }

    private var favoriteButton: some View {
        Button {
            viewModel.favoriteTopN()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: viewModel.isFavorited ? "heart.fill" : "heart")
                    .font(.system(size: 17, weight: .semibold))

                Text(viewModel.isFavorited ? "즐겨찾기 등록 완료" : "TOP \(viewModel.topN) 즐겨찾기 등록")
                    .font(.system(size: 17, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        viewModel.isFavorited
                        ? LinearGradient(colors: [Color.pink.opacity(0.3), Color.pink.opacity(0.2)], startPoint: .leading, endPoint: .trailing)
                        : LinearGradient(colors: [Color.pink, Color.red.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                    )
            )
            .foregroundColor(.white)
        }
        .disabled(viewModel.isFavorited)
        .animation(.easeInOut(duration: 0.3), value: viewModel.isFavorited)
    }

    private var remainingSection: some View {
        VStack(spacing: 16) {
            // Section header
            HStack(spacing: 8) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, Color.white.opacity(0.1)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)

                Text("나머지")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(1)
                    .fixedSize()

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.1), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
            }

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(Array(viewModel.candidates.dropFirst(viewModel.topN).enumerated()), id: \.element.id) { _, candidate in
                    remainingCard(candidate: candidate)
                }
            }
        }
    }

    private func remainingCard(candidate: PhotoCandidate) -> some View {
        ZStack(alignment: .bottomLeading) {
            Image(uiImage: candidate.image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 180)
                .clipped()

            // Gradient overlay
            LinearGradient(
                colors: [.clear, .clear, Color.black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )

            // Score overlay
            if let scores = candidate.scores {
                HStack(spacing: 4) {
                    Text("\(Int(scores.totalScore * 100))")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("점")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)
                )
                .padding(10)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}
