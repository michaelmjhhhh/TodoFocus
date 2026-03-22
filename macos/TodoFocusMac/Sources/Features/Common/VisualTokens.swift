import SwiftUI

enum VisualTokens {
    static let bgBase = Color(red: 0.07, green: 0.08, blue: 0.10)
    static let bgElevated = Color(red: 0.11, green: 0.12, blue: 0.15)
    static let bgFloating = Color(red: 0.15, green: 0.16, blue: 0.20)

    static let textPrimary = Color(red: 0.93, green: 0.94, blue: 0.97)
    static let textSecondary = Color(red: 0.71, green: 0.74, blue: 0.80)

    static let success = Color(red: 0.37, green: 0.81, blue: 0.61)
    static let warning = Color(red: 0.97, green: 0.73, blue: 0.31)
    static let danger = Color(red: 0.94, green: 0.41, blue: 0.47)

    static let accentBlue = Color(red: 0.40, green: 0.71, blue: 0.96)
    static let accentViolet = Color(red: 0.60, green: 0.53, blue: 0.95)
    static let accentAmber = Color(red: 0.95, green: 0.64, blue: 0.29)

    static let appBackground = LinearGradient(
        colors: [
            bgBase,
            bgElevated,
            Color(red: 0.10, green: 0.11, blue: 0.14)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let accent = LinearGradient(
        colors: [accentAmber, accentViolet],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let panelBackground = bgFloating
    static let sectionBackground = bgElevated
    static let sectionBorder = Color(red: 0.34, green: 0.36, blue: 0.40).opacity(0.65)
    static let mutedText = textSecondary
    static let violetAccent = accentViolet
    static let cyanAccent = accentBlue
    static let roseAccent = danger
}
