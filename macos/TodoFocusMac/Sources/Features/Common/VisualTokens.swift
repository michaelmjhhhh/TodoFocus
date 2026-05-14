import SwiftUI

enum VisualTokens {
    static let bgBase = Color(red: 0.067, green: 0.067, blue: 0.063)
    static let bgElevated = Color(red: 0.102, green: 0.098, blue: 0.090)
    static let bgFloating = Color(red: 0.141, green: 0.137, blue: 0.125)
    static let bgSubtle = Color(red: 0.118, green: 0.114, blue: 0.106)

    static let textPrimary = Color(red: 0.941, green: 0.929, blue: 0.902)
    static let textSecondary = Color(red: 0.608, green: 0.584, blue: 0.565)
    static let textTertiary = Color(red: 0.420, green: 0.396, blue: 0.376)

    static let success = Color(red: 0.37, green: 0.81, blue: 0.61)
    static let warning = Color(red: 0.97, green: 0.73, blue: 0.31)
    static let danger = Color(red: 0.90, green: 0.42, blue: 0.42)

    static let accentBlue = Color(red: 0.478, green: 0.671, blue: 0.859)
    static let accentViolet = Color(red: 0.608, green: 0.561, blue: 0.831)
    static let accentAmber = Color(red: 0.95, green: 0.64, blue: 0.29)
    static let accentTerracotta = Color(red: 0.831, green: 0.443, blue: 0.306)

    static let appBackground = LinearGradient(
        colors: [
            bgBase,
            bgBase,
            Color(red: 0.075, green: 0.075, blue: 0.071)
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
    static let sectionBorder = Color(red: 0.941, green: 0.929, blue: 0.902).opacity(0.05)
    static let mutedText = textSecondary
    static let violetAccent = accentViolet
    static let cyanAccent = accentBlue
    static let roseAccent = danger
}

extension VisualTokens {
    static func current(for theme: ThemeStore.Theme = .dark) -> ThemeTokens {
        ThemeTokens()
    }
}
