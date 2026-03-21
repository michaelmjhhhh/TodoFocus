import SwiftUI

enum VisualTokens {
    static let appBackground = LinearGradient(
        colors: [
            Color(red: 0.10, green: 0.13, blue: 0.18),
            Color(red: 0.12, green: 0.16, blue: 0.22),
            Color(red: 0.10, green: 0.14, blue: 0.19)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let accent = LinearGradient(
        colors: [Color(red: 0.26, green: 0.64, blue: 1.0), Color(red: 0.32, green: 0.42, blue: 0.98)],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let panelBackground = Color(red: 0.13, green: 0.16, blue: 0.22)
    static let sectionBackground = Color(red: 0.16, green: 0.19, blue: 0.26)
    static let sectionBorder = Color(red: 0.29, green: 0.34, blue: 0.45).opacity(0.5)
    static let mutedText = Color(red: 0.66, green: 0.71, blue: 0.80)
}
