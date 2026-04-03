import SwiftUI

enum VisualTokens {
    static let bgBase = Color(hex: "#1A1A18")
    static let bgElevated = Color(hex: "#242422")
    static let bgFloating = Color(hex: "#2A2A27")

    static let textPrimary = Color(hex: "#FCF9F3")
    static let textSecondary = Color(hex: "#CCB89E")
    static let textTertiary = Color(hex: "#9C8E7B")

    static let success = Color(red: 0.37, green: 0.81, blue: 0.61)
    static let warning = Color(red: 0.97, green: 0.73, blue: 0.31)
    static let danger = Color(red: 0.94, green: 0.41, blue: 0.47)

    static let accentBlue = Color(red: 0.40, green: 0.71, blue: 0.96)
    static let accentViolet = Color(red: 0.60, green: 0.53, blue: 0.95)
    static let accentAmber = Color(hex: "#D97706")
    static let accentTerracotta = Color(hex: "#D97706")

    static let appBackground = LinearGradient(
        colors: [
            bgBase,
            bgBase,
            Color(hex: "#211F1C")
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let accent = LinearGradient(
        colors: [accentAmber, accentViolet],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let panelBackground = bgElevated
    static let sectionBackground = bgElevated
    static let sectionBorder = Color(hex: "#9C8E7B").opacity(0.28)
    static let mutedText = textSecondary
    static let violetAccent = accentViolet
    static let cyanAccent = accentBlue
    static let roseAccent = danger
}

extension VisualTokens {
    /// Returns ThemeTokens for a given theme (for test/preview use)
    static func current(for theme: ThemeStore.Theme = .dark) -> ThemeTokens {
        ThemeTokens(theme: theme)
    }
}
