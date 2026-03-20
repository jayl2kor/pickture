import SwiftUI

enum AppColors {
    static let textPrimary = Color(red: 0.2, green: 0.15, blue: 0.25)
    static let textSecondary = Color(red: 0.45, green: 0.4, blue: 0.5)
    static let textTertiary = Color(red: 0.35, green: 0.32, blue: 0.38)
    static let cardFill = Color.white
    static let cardShadow = Color(red: 0.6, green: 0.4, blue: 0.7).opacity(0.15)
    static let scoreLabel = Color(red: 0.4, green: 0.35, blue: 0.45)

    static let accentGradient = LinearGradient(
        colors: [Color(red: 1.0, green: 0.45, blue: 0.55), Color(red: 1.0, green: 0.6, blue: 0.4)],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 1.0, green: 0.97, blue: 0.95),
            Color(red: 0.98, green: 0.94, blue: 0.97),
            Color(red: 0.95, green: 0.93, blue: 0.99)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}

func displayScore(_ value: Double) -> Int {
    Int(value * 100)
}
