import SwiftUI

struct ComparisonView: View {
    let left: PhotoCandidate
    let right: PhotoCandidate
    let onDismiss: () -> Void

    private let textPrimary = Color(red: 0.2, green: 0.15, blue: 0.25)
    private let textSecondary = Color(red: 0.45, green: 0.4, blue: 0.5)

    var body: some View {
        ZStack(alignment: .topTrailing) {
            LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.97, blue: 0.95),
                    Color(red: 0.95, green: 0.93, blue: 0.99)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    Text("사진 비교")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(textPrimary)
                        .padding(.top, 50)

                    // Side-by-side photos
                    HStack(spacing: 8) {
                        let leftTotal = left.scores?.totalScore ?? 0
                        let rightTotal = right.scores?.totalScore ?? 0
                        photoCard(candidate: left, isWinner: leftTotal > rightTotal + 0.001)
                        photoCard(candidate: right, isWinner: rightTotal > leftTotal + 0.001)
                    }
                    .padding(.horizontal, 16)

                    // Score comparison
                    if let ls = left.scores, let rs = right.scores {
                        VStack(spacing: 12) {
                            compareRow(label: "총점", leftScore: ls.totalScore, rightScore: rs.totalScore, bold: true)

                            Divider().padding(.horizontal, 8)

                            ForEach(Array(zip(ls.details, rs.details)), id: \.0.0) { leftDetail, rightDetail in
                                compareRow(label: leftDetail.0, leftScore: leftDetail.1, rightScore: rightDetail.1)
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white)
                        )
                        .shadow(color: Color(red: 0.6, green: 0.4, blue: 0.7).opacity(0.1), radius: 10, y: 4)
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 40)
            }

            // Close button
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(textSecondary)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.white))
                    .shadow(color: Color.black.opacity(0.1), radius: 4, y: 2)
            }
            .padding(.top, 12)
            .padding(.trailing, 20)
        }
    }

    private func photoCard(candidate: PhotoCandidate, isWinner: Bool) -> some View {
        VStack(spacing: 8) {
            Image(uiImage: candidate.image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 220)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    isWinner
                    ? RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [Color(red: 1.0, green: 0.8, blue: 0.4), Color(red: 1.0, green: 0.5, blue: 0.35)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2.5
                        )
                    : nil
                )

            if let scores = candidate.scores {
                HStack(spacing: 4) {
                    if isWinner {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color(red: 1.0, green: 0.65, blue: 0.3))
                    }
                    Text("\(Int(scores.totalScore * 100))점")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(textPrimary)
                }
            }
        }
    }

    private func compareRow(label: String, leftScore: Double, rightScore: Double, bold: Bool = false) -> some View {
        let leftWins = leftScore > rightScore + 0.001
        let rightWins = rightScore > leftScore + 0.001
        let winColor = Color(red: 1.0, green: 0.45, blue: 0.55)

        return HStack(spacing: 0) {
            HStack(spacing: 4) {
                Text("\(Int(leftScore * 100))")
                    .font(.system(size: bold ? 18 : 15, weight: leftWins ? .bold : .regular, design: .rounded))
                    .foregroundColor(leftWins ? winColor : textSecondary)

                if leftWins {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(winColor)
                }
            }
            .frame(width: 56, alignment: .trailing)

            Text(label)
                .font(.system(size: bold ? 14 : 13, weight: bold ? .bold : .medium, design: .rounded))
                .foregroundColor(textPrimary)
                .frame(maxWidth: .infinity)

            HStack(spacing: 4) {
                if rightWins {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(winColor)
                }

                Text("\(Int(rightScore * 100))")
                    .font(.system(size: bold ? 18 : 15, weight: rightWins ? .bold : .regular, design: .rounded))
                    .foregroundColor(rightWins ? winColor : textSecondary)
            }
            .frame(width: 56, alignment: .leading)
        }
        .padding(.vertical, 2)
    }
}
