import SwiftUI
import PhotosUI
import Photos

private extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

/// Press scale feedback for buttons (scale 0.97 on press, spring release)
private struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Shimmer effect for skeleton loading states
private struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        Color.white.opacity(0.4),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase * 300)
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

private extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

struct ContentView: View {
    @StateObject private var viewModel = PhotoViewModel()
    @State private var showResults = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Warm pink-coral accent
    private let accentGradient = LinearGradient(
        colors: [Color(red: 1.0, green: 0.45, blue: 0.55), Color(red: 1.0, green: 0.6, blue: 0.4)],
        startPoint: .leading,
        endPoint: .trailing
    )

    // Text colors
    private let textPrimary = Color(red: 0.2, green: 0.15, blue: 0.25)
    private let textSecondary = Color(red: 0.45, green: 0.4, blue: 0.5)
    private let textTertiary = Color(red: 0.35, green: 0.32, blue: 0.38)

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
        .task {
            await PHPhotoLibrary.requestAuthorization(for: .readWrite)
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
                if reduceMotion {
                    showResults = true
                } else {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        showResults = true
                    }
                }
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
        }
        .alert("사진 라이브러리 접근 필요", isPresented: $viewModel.showFavoriteError) {
            Button("설정으로 이동") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("즐겨찾기 등록을 위해 사진 라이브러리 쓰기 권한이 필요합니다. 설정에서 권한을 허용해주세요.")
        }
        .alert("사진 로드 실패", isPresented: .init(
            get: { viewModel.loadFailCount > 0 && !viewModel.candidates.isEmpty },
            set: { if !$0 { viewModel.loadFailCount = 0 } }
        )) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("\(viewModel.loadFailCount)장의 사진을 불러오지 못했습니다. 나머지 사진으로 분석이 완료되었습니다.")
        }
        .onChange(of: viewModel.candidates.count) { newCount in
            if newCount == 0 { showResults = false }
        }
        .fullScreenCover(isPresented: $viewModel.showComparison) {
            if viewModel.compareSelection.count == 2 {
                ComparisonView(
                    left: viewModel.compareSelection[0],
                    right: viewModel.compareSelection[1]
                ) {
                    viewModel.exitCompareMode()
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(accentGradient)

                Text("Pickture")
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

            if viewModel.selectedItems.isEmpty {
                HStack(spacing: 16) {
                    stepBubble(number: "1", text: "사진 선택", color: Color(red: 1.0, green: 0.5, blue: 0.6))
                    stepArrow
                    stepBubble(number: "2", text: "AI 분석", color: Color(red: 0.55, green: 0.65, blue: 1.0))
                    stepArrow
                    stepBubble(number: "3", text: "베스트 확인", color: Color(red: 0.5, green: 0.82, blue: 0.55))
                }
                .padding(.top, 12)
            }
        }
        .padding(.bottom, 8)
    }

    private func stepBubble(number: String, text: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(number)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(color))
            Text(text)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(textSecondary)
        }
    }

    private var stepArrow: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(accentGradient)
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
                                        colors: [Color(red: 1.0, green: 0.5, blue: 0.6).opacity(0.15), Color(red: 0.7, green: 0.5, blue: 0.9).opacity(0.12)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 72, height: 72)

                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 28, weight: .medium))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(red: 1.0, green: 0.45, blue: 0.55), Color(red: 0.7, green: 0.5, blue: 0.9)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
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
                                .fill(
                                    LinearGradient(
                                        colors: [Color(red: 1.0, green: 0.5, blue: 0.6).opacity(0.12), Color(red: 0.7, green: 0.5, blue: 0.9).opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 44, height: 44)

                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(red: 1.0, green: 0.45, blue: 0.55), Color(red: 0.7, green: 0.5, blue: 0.9)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
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
            } else if !viewModel.selectedItems.isEmpty {
                analyzeButton
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 20) {
            // Skeleton card placeholders
            ForEach(0..<2, id: \.self) { _ in
                VStack(alignment: .leading, spacing: 12) {
                    // Image placeholder
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.pink.opacity(0.08))
                        .frame(height: 160)
                        .shimmer()

                    // Score bar placeholders
                    ForEach(0..<3, id: \.self) { _ in
                        HStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.pink.opacity(0.06))
                                .frame(width: 60, height: 12)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.pink.opacity(0.06))
                                .frame(height: 8)
                        }
                        .shimmer()
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(cardFill)
                )
                .shadow(color: Color.pink.opacity(0.06), radius: 8, y: 3)
            }

            Text("사진 불러오는 중...")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

    private var analyzingView: some View {
        let total = max(viewModel.progressTotal, 1)
        let progress = Double(viewModel.progressCurrent) / Double(total)
        let percentage = Int(progress * 100)

        return VStack(spacing: 20) {
            ZStack {
                // Background track
                Circle()
                    .stroke(Color.pink.opacity(0.1), lineWidth: 6)
                    .frame(width: 80, height: 80)

                // Progress arc
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        accentGradient,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: progress)

                VStack(spacing: -2) {
                    Text("\(percentage)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(textPrimary)
                        .contentTransition(.numericText())
                    Text("%")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(textTertiary)
                }
            }

            VStack(spacing: 4) {
                Text("AI 분석 중")
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
            .buttonStyle(ScaleButtonStyle())
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
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(viewModel.topN > 1 ? accentGradient : LinearGradient(colors: [textTertiary.opacity(0.3), textTertiary.opacity(0.3)], startPoint: .leading, endPoint: .trailing))
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
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(viewModel.topN < viewModel.selectedItems.count - 1 ? accentGradient : LinearGradient(colors: [textTertiary.opacity(0.3), textTertiary.opacity(0.3)], startPoint: .leading, endPoint: .trailing))
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
        let needed = viewModel.topN + 1

        return VStack(spacing: 8) {
            Button {
                viewModel.loadAndAnalyze()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 18, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)

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
                                .shadow(color: Color.pink.opacity(0.3), radius: 12, y: 4)
                        } else {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.gray.opacity(0.22))
                        }
                    }
                )
                .foregroundColor(isEnabled ? .white : textTertiary)
            }
            .buttonStyle(ScaleButtonStyle())
            .accessibilityLabel(isEnabled ? "분석 시작" : "분석 시작 불가, 사진을 더 선택해주세요")
            .disabled(!isEnabled)

            if !isEnabled && !viewModel.selectedItems.isEmpty {
                Text("최소 \(needed)장 이상 선택해주세요 (현재 \(viewModel.selectedItems.count)장)")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(textTertiary)
            }
        }
    }

    // MARK: - Results

    private var resultsSection: some View {
        Group {
            if !viewModel.candidates.isEmpty {
                VStack(spacing: 24) {
                    // Mini header with app name + reset
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 12))
                                .foregroundStyle(accentGradient)
                            Text("Pickture")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .tracking(1)
                                .foregroundColor(textTertiary)
                        }

                        Spacer()

                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                viewModel.reset()
                            }
                        } label: {
                            Text("다시 선택")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(accentGradient)
                        }
                    }

                    // TOP N Header
                    topNHeader
                        .transition(.opacity.combined(with: .move(edge: .top)))

                    // Compare mode toggle
                    compareToggleButton

                    if viewModel.isCompareMode {
                        Text("비교할 사진 2장을 탭해주세요 (\(viewModel.compareSelection.count)/2)")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(textSecondary)
                    }

                    // Top N cards with staggered animation
                    ForEach(Array(viewModel.sortedCandidates.prefix(viewModel.topN).enumerated()), id: \.element.id) { index, candidate in
                        candidateCard(candidate: candidate, rank: index + 1)
                            .opacity(showResults ? 1 : 0)
                            .offset(y: showResults ? 0 : 30)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.82)
                                .delay(Double(index) * 0.1),
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
                                .foregroundStyle(accentGradient)
                            Text("처음부터 다시 하기")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(cardFill)
                        )
                        .shadow(color: Color.black.opacity(0.06), radius: 6, y: 2)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
        }
    }

    private var compareToggleButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.toggleCompareMode()
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: viewModel.isCompareMode ? "xmark" : "rectangle.on.rectangle")
                    .font(.system(size: 14, weight: .semibold))
                Text(viewModel.isCompareMode ? "비교 모드 해제" : "사진 비교하기")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .foregroundColor(viewModel.isCompareMode ? .white : Color(red: 0.4, green: 0.55, blue: 1.0))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule().fill(
                    viewModel.isCompareMode
                    ? AnyShapeStyle(LinearGradient(colors: [Color(red: 0.4, green: 0.55, blue: 1.0), Color(red: 0.55, green: 0.65, blue: 1.0)], startPoint: .leading, endPoint: .trailing))
                    : AnyShapeStyle(Color(red: 0.4, green: 0.55, blue: 1.0).opacity(0.1))
                )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private func candidateCard(candidate: PhotoCandidate, rank: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            ResultCardView(candidate: candidate, rank: rank)

            if viewModel.isCompareMode {
                // Dim overlay for unselected cards
                let isSelected = viewModel.isSelectedForCompare(candidate)
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(isSelected ? 0 : 0.15))
                    .allowsHitTesting(false)

                // Check badge
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.pink : Color.white.opacity(0.8))
                        .frame(width: 32, height: 32)
                        .shadow(color: Color.black.opacity(0.15), radius: 3, y: 1)

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                            .frame(width: 32, height: 32)
                    }
                }
                .padding(16)
                .allowsHitTesting(false)
            }
        }
        .if(viewModel.isCompareMode) { view in
            view
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.toggleCompareSelection(candidate)
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
        }
    }

    private var topNHeader: some View {
        VStack(spacing: 12) {
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

            // Sort picker
            Menu {
                ForEach(SortCriteria.allCases, id: \.self) { criteria in
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            viewModel.sortCriteria = criteria
                        }
                    } label: {
                        if viewModel.sortCriteria == criteria {
                            Label(criteria.rawValue, systemImage: "checkmark")
                        } else {
                            Text(criteria.rawValue)
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 0.7, green: 0.5, blue: 0.9), Color(red: 1.0, green: 0.5, blue: 0.6)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    Text(viewModel.sortCriteria.rawValue)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(red: 0.7, green: 0.5, blue: 0.9))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    Capsule().fill(Color(red: 0.7, green: 0.5, blue: 0.9).opacity(0.1))
                )
            }
        }
        .padding(.vertical, 4)
    }

    private var favoriteButton: some View {
        HStack(spacing: 12) {
            Button {
                viewModel.favoriteTopN()
            } label: {
                HStack(spacing: 10) {
                    if viewModel.isFavoriting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: viewModel.isFavorited ? "heart.fill" : "heart")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(viewModel.isFavorited ? Color(red: 1.0, green: 0.35, blue: 0.45) : .white)
                    }
                    Text(viewModel.isFavoriting ? "등록 중..." : viewModel.isFavorited ? "등록 완료" : "즐겨찾기")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            viewModel.isFavorited
                            ? LinearGradient(colors: [Color(red: 1.0, green: 0.35, blue: 0.45).opacity(0.1), Color(red: 1.0, green: 0.35, blue: 0.45).opacity(0.06)], startPoint: .leading, endPoint: .trailing)
                            : LinearGradient(colors: [Color(red: 1.0, green: 0.4, blue: 0.5), Color(red: 0.95, green: 0.3, blue: 0.5)], startPoint: .leading, endPoint: .trailing)
                        )
                )
                .foregroundColor(viewModel.isFavorited ? Color(red: 1.0, green: 0.35, blue: 0.45) : .white)
            }
            .buttonStyle(ScaleButtonStyle())
            .disabled(viewModel.isFavorited || viewModel.isFavoriting)
            .animation(.easeInOut(duration: 0.3), value: viewModel.isFavorited)

            Button {
                shareTopPhotos()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color(red: 0.4, green: 0.65, blue: 1.0))
                    Text("공유")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(textPrimary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(cardFill)
                )
                .shadow(color: Color.black.opacity(0.06), radius: 6, y: 2)
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }

    private func shareTopPhotos() {
        let images = viewModel.sortedCandidates.prefix(viewModel.topN).map(\.image)
        guard !images.isEmpty else { return }

        let activityVC = UIActivityViewController(activityItems: images, applicationActivities: nil)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }
        rootVC.present(activityVC, animated: true)
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
                ForEach(Array(viewModel.sortedCandidates.dropFirst(viewModel.topN).enumerated()), id: \.element.id) { _, candidate in
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
        .overlay(alignment: .topTrailing) {
            if viewModel.isCompareMode {
                let isSelected = viewModel.isSelectedForCompare(candidate)
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.pink : Color.white.opacity(0.8))
                        .frame(width: 28, height: 28)
                        .shadow(color: Color.black.opacity(0.15), radius: 2, y: 1)
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                            .frame(width: 28, height: 28)
                    }
                }
                .padding(8)
                .allowsHitTesting(false)
            }
        }
        .if(viewModel.isCompareMode) { view in
            view
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.toggleCompareSelection(candidate)
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("사진, 총점 \(Int((candidate.scores?.totalScore ?? 0) * 100))점")
    }
}
