import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let accentGradient = LinearGradient(
        colors: [Color(red: 1.0, green: 0.45, blue: 0.55), Color(red: 1.0, green: 0.6, blue: 0.4)],
        startPoint: .leading,
        endPoint: .trailing
    )

    private let pages: [(icon: String, iconColors: [Color], title: String, description: String)] = [
        (
            "photo.on.rectangle.angled",
            [Color(red: 1.0, green: 0.5, blue: 0.6), Color(red: 0.7, green: 0.5, blue: 0.9)],
            "사진을 선택하세요",
            "비슷한 인물 사진을 여러 장 선택하면\nAI가 자동으로 분석을 시작합니다"
        ),
        (
            "wand.and.stars",
            [Color(red: 0.55, green: 0.65, blue: 1.0), Color(red: 0.7, green: 0.5, blue: 0.9)],
            "AI가 분석합니다",
            "선명도, 얼굴 품질, 눈 뜨임, 노출, 구도\n5가지 기준으로 사진을 평가합니다"
        ),
        (
            "trophy.fill",
            [Color(red: 1.0, green: 0.7, blue: 0.3), Color(red: 1.0, green: 0.5, blue: 0.35)],
            "베스트 사진 확인",
            "가장 잘 나온 사진을 즐겨찾기에 등록하고\n나머지는 한번에 정리할 수 있습니다"
        )
    ]

    var body: some View {
        ZStack {
            // Background
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

            VStack(spacing: 0) {
                Spacer()

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        VStack(spacing: 24) {
                            // Icon
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: page.iconColors.map { $0.opacity(0.15) },
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 120, height: 120)

                                Image(systemName: page.icon)
                                    .font(.system(size: 48, weight: .medium))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: page.iconColors,
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }

                            // Title
                            Text(page.title)
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.25))

                            // Description
                            Text(page.description)
                                .font(.system(size: 16, design: .rounded))
                                .foregroundColor(Color(red: 0.45, green: 0.4, blue: 0.5))
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }
                        .padding(.horizontal, 40)
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                Spacer()

                // Page indicator
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Capsule()
                            .fill(index == currentPage ? Color(red: 1.0, green: 0.45, blue: 0.55) : Color.gray.opacity(0.3))
                            .frame(width: index == currentPage ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                    }
                }
                .padding(.bottom, 32)

                // Button
                Button {
                    if currentPage < pages.count - 1 {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            currentPage += 1
                        }
                    } else {
                        isPresented = false
                    }
                } label: {
                    Text(currentPage < pages.count - 1 ? "다음" : "시작하기")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(accentGradient)
                                .shadow(color: Color.pink.opacity(0.3), radius: 12, y: 4)
                        )
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 24)

                // Skip button (not on last page)
                if currentPage < pages.count - 1 {
                    Button {
                        isPresented = false
                    } label: {
                        Text("건너뛰기")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(Color(red: 0.45, green: 0.4, blue: 0.5))
                    }
                    .padding(.top, 12)
                }

                Spacer().frame(height: 40)
            }
        }
    }
}
