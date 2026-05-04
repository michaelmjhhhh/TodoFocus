import SwiftUI

enum VisualTokens {
    static let bgBase = Color(hex: "faf9f5")
    static let bgElevated = Color(hex: "efe9de")
    static let bgFloating = Color(hex: "f5f0e8")

    static let textPrimary = Color(hex: "141413")
    static let textSecondary = Color(hex: "3d3d3a")
    static let textTertiary = Color(hex: "6c6a64")

    static let success = Color(hex: "5db872")
    static let warning = Color(hex: "d4a017")
    static let danger = Color(hex: "c64545")

    static let accentBlue = Color(hex: "5db8a6")
    static let accentViolet = Color(hex: "8b5cf6")
    static let accentAmber = Color(hex: "e8a55a")
    static let accentTerracotta = Color(hex: "cc785c")

    static let hairline = Color(hex: "e6dfd8")
    static let hairlineSoft = Color(hex: "ebe6df")
    static let surfaceCreamStrong = Color(hex: "e8e0d2")
    static let primaryActive = Color(hex: "a9583e")
    static let primaryDisabled = Color(hex: "e6dfd8")

    static let appBackground = LinearGradient(
        colors: [Color(hex: "faf9f5"), Color(hex: "f5f0e8")],
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
    static let sectionBorder = hairline
    static let mutedText = textSecondary
    static let violetAccent = accentViolet
    static let cyanAccent = accentBlue
    static let roseAccent = danger
}

extension VisualTokens {
    static func current(for theme: ThemeStore.Theme = .light) -> ThemeTokens {
        ThemeTokens(theme: theme)
    }
}
