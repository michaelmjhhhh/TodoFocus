import SwiftUI

enum VisualTokens {
    static let bgBase = Color(red: 0.039, green: 0.039, blue: 0.039)
    static let bgElevated = Color(red: 0.11, green: 0.11, blue: 0.11)
    static let bgFloating = Color(red: 0.15, green: 0.15, blue: 0.15)

    static let textPrimary = Color(red: 0.98, green: 0.98, blue: 0.98)
    static let textSecondary = Color(red: 0.55, green: 0.55, blue: 0.55)
    static let textTertiary = Color(red: 0.40, green: 0.40, blue: 0.40)

    static let success = Color(red: 0.37, green: 0.81, blue: 0.61)
    static let warning = Color(red: 0.97, green: 0.73, blue: 0.31)
    static let danger = Color(red: 0.94, green: 0.41, blue: 0.47)

    static let accentBlue = Color(red: 0.40, green: 0.71, blue: 0.96)
    static let accentViolet = Color(red: 0.60, green: 0.53, blue: 0.95)
    static let accentAmber = Color(red: 0.95, green: 0.64, blue: 0.29)
    static let accentTerracotta = Color(red: 0.769, green: 0.408, blue: 0.286)

    static let appBackground = LinearGradient(
        colors: [
            bgBase,
            bgBase,
            Color(red: 0.05, green: 0.05, blue: 0.05)
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
    static let sectionBorder = Color.white.opacity(0.06)
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
