import SwiftUI
import PhotosUI

struct ContentView: View {
    @StateObject private var viewModel = PhotoViewModel()
    @State private var pulseAnalyze = false
    @State private var showResults = false

    // Warm pink-coral accent
    private let accentGradient = LinearGradient(
        colors: [Color(red: 1.0, green: 0.45, blue: 0.55), Color(red: 1.0, green: 0.6, blue: 0.4)],
        startPoint: .leading,
        endPoint: .trailing
    )

    // Text colors
    private let textPrimary = Color(red: 0.2, green: 0.15, blue: 0.25)
    private let textSecondary = Color(red: 0.45, green: 0.4, blue: 0.5)
    private let textTertiary = Color(red: 0.55, green: 0.50, blue: 0.58)

    // Card / surface
    private let cardFill = Color.white
    private let surfaceFill = Color(red: 0.96, green: 0.94, blue: 0.98)

    var body: some View {
        ZStack {
            // Warm cream → blush → lavender background
            LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.97, blue: 0.95),
                    Color(red: 0.98, green: 0.94, blue: 0.97),
                    Color(red: 0.95, green: 0.93, blue: 0.99)
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
                            .padding(.top, 16)
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
        #if DEBUG
        .onAppear {
            if CommandLine.arguments.contains("--auto-test") {
                viewModel.debugAutoTest()
            }
        }
        #endif
        .onChange(of: viewModel.isAnalyzing) { newValue in
            if !newValue && !viewModel.candidates.isEmpty {
                showResults = false
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    showResults = true
                }
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
        }
        .onChange(of: viewModel.candidates.count) { newCount in
            if newCount == 0 { showResults = false }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(accentGradient)

                Text("AI Photo Selector")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(textTertiary)
                    .tracking(1.5)
                    .textCase(.uppercase)

                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(accentGradient)
            }
            .padding(.top, 16)

            Text("베스트 사진 선별")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(textPrimary)

            Text("여러 장의 인물 사진 중 가장 잘 나온 사진을\nAI가 자동으로 골라드립니다")
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(textSecondary)
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
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.pink.opacity(0.12), Color.orange.opacity(0.08)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 72, height: 72)

                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 28, weight: .medium))
                                .foregroundStyle(accentGradient)
                        }

                        Text("사진 선택하기")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(textPrimary)

                        Text("인물 사진을 여러 장 선택해주세요")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(cardFill)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(
                                style: StrokeStyle(lineWidth: 1.5, dash: [8, 6])
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.pink.opacity(0.4), Color.orange.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .shadow(color: Color.pink.opacity(0.08), radius: 12, y: 4)
                } else {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.pink.opacity(0.1))
                                .frame(width: 44, height: 44)

                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(accentGradient)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("사진 선택됨")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(textPrimary)
                            Text("탭하여 변경하기")
                                .font(.system(size: 12, design: .rounded))
                                .foregroundColor(textTertiary)
                        }

                        Spacer()

                        countBadge
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(cardFill)
                    )
                    .shadow(color: Color.pink.opacity(0.08), radius: 8, y: 3)
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
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.85))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(accentGradient)
        )
        .shadow(color: Color.pink.opacity(0.2), radius: 5, y: 2)
    }

    // MARK: - Analyze Section

    private var analyzeSection: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else if viewModel.isAnalyzing {
                analyzingView
            } else if !viewModel.candidates.isEmpty {
                EmptyView()
            } else {
                analyzeButton
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color.pink))
                .scaleEffect(1.2)

            Text("사진 불러오는 중...")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    private var analyzingView: some View {
        let total = max(viewModel.progressTotal, 1)
        let progress = Double(viewModel.progressCurrent) / Double(total)
        let percentage = Int(progress * 100)

        return VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.pink.opacity(0.12), lineWidth: 6)
                    .frame(width: 80, height: 80)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        accentGradient,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: progress)

                Text("\(percentage)%")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(textPrimary)
            }

            VStack(spacing: 4) {
                Text("분석 중")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(textPrimary)

                Text("\(viewModel.progressCurrent) / \(viewModel.progressTotal)장 완료")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(textTertiary)
            }

            Button {
                viewModel.cancelAnalysis()
            } label: {
                Text("취소")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(textSecondary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(
                        Capsule().fill(Color.gray.opacity(0.12))
                    )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(cardFill)
        )
        .shadow(color: Color.pink.opacity(0.06), radius: 10, y: 4)
    }

    private var topNSelector: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text("선별 장수")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(textPrimary)
                Text("상위 몇 장을 선별할지 선택하세요")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(textTertiary)
            }

            Spacer()

            HStack(spacing: 0) {
                Button {
                    if viewModel.topN > 1 { viewModel.topN -= 1 }
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(viewModel.topN > 1 ? Color.pink : textTertiary.opacity(0.4))
                        .frame(width: 44, height: 44)
                }
                .disabled(viewModel.topN <= 1)

                Text("\(viewModel.topN)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(textPrimary)
                    .frame(width: 36, height: 44)

                Button {
                    let maxN = max(viewModel.selectedItems.count - 1, 1)
                    if viewModel.topN < maxN { viewModel.topN += 1 }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(viewModel.topN < viewModel.selectedItems.count - 1 ? Color.pink : textTertiary.opacity(0.4))
                        .frame(width: 44, height: 44)
                }
                .disabled(viewModel.topN >= viewModel.selectedItems.count - 1)
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.pink.opacity(0.08))
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(cardFill)
        )
        .shadow(color: Color.pink.opacity(0.06), radius: 8, y: 3)
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
                    .font(.system(size: 17, weight: .bold, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Group {
                    if isEnabled {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(accentGradient)
                            .shadow(color: Color.pink.opacity(0.35), radius: 16, y: 4)
                            .scaleEffect(pulseAnalyze ? 1.02 : 1.0)
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.gray.opacity(0.22))
                    }
                }
            )
            .foregroundColor(isEnabled ? .white : textTertiary)
        }
        .accessibilityLabel(isEnabled ? "분석 시작" : "분석 시작 불가, 사진을 더 선택해주세요")
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
                    // TOP N Header
                    topNHeader
                        .transition(.opacity.combined(with: .move(edge: .top)))

                    // Top N cards with staggered animation
                    ForEach(Array(viewModel.candidates.prefix(viewModel.topN).enumerated()), id: \.element.id) { index, candidate in
                        ResultCardView(candidate: candidate, rank: index + 1)
                            .opacity(showResults ? 1 : 0)
                            .offset(y: showResults ? 0 : 40)
                            .animation(
                                .spring(response: 0.6, dampingFraction: 0.8)
                                .delay(Double(index) * 0.15),
                                value: showResults
                            )
                    }

                    // Favorite button
                    favoriteButton

                    // The rest
                    if viewModel.candidates.count > viewModel.topN {
                        remainingSection
                    }

                    // Re-select button at bottom
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.reset()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 15, weight: .semibold))
                            Text("처음부터 다시 하기")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(cardFill)
                        )
                        .shadow(color: Color.black.opacity(0.06), radius: 6, y: 2)
                    }
                }
            }
        }
    }

    private var topNHeader: some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, Color.pink.opacity(0.25)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            HStack(spacing: 6) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 1.0, green: 0.7, blue: 0.3), Color(red: 1.0, green: 0.5, blue: 0.35)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                Text("TOP \(viewModel.topN)")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(textPrimary)
                    .tracking(2)
            }
            .fixedSize()

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.pink.opacity(0.25), .clear],
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
                    .font(.system(size: 17, weight: .bold, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        viewModel.isFavorited
                        ? LinearGradient(colors: [Color.pink.opacity(0.08), Color.pink.opacity(0.05)], startPoint: .leading, endPoint: .trailing)
                        : LinearGradient(colors: [Color(red: 1.0, green: 0.45, blue: 0.55), Color(red: 0.95, green: 0.35, blue: 0.5)], startPoint: .leading, endPoint: .trailing)
                    )
            )
            .foregroundColor(viewModel.isFavorited ? Color.pink : .white)
        }
        .disabled(viewModel.isFavorited)
        .animation(.easeInOut(duration: 0.3), value: viewModel.isFavorited)
    }

    private var remainingSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, textTertiary.opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)

                Text("나머지")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(textTertiary)
                    .tracking(1)
                    .fixedSize()

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [textTertiary.opacity(0.3), .clear],
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

            LinearGradient(
                colors: [.clear, .clear, Color.black.opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )

            if let scores = candidate.scores {
                HStack(spacing: 4) {
                    Text("\(Int(scores.totalScore * 100))")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("점")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(.regularMaterial)
                )
                .padding(10)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.1), radius: 6, y: 3)
    }
}
