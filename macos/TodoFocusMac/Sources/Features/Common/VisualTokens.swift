import SwiftUI

enum VisualTokens {
    static let appBackground = LinearGradient(
        colors: [
            Color(red: 0.08, green: 0.09, blue: 0.10),
            Color(red: 0.10, green: 0.11, blue: 0.12),
            Color(red: 0.09, green: 0.10, blue: 0.11)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let accent = LinearGradient(
        colors: [Color(red: 0.95, green: 0.45, blue: 0.16), Color(red: 0.96, green: 0.65, blue: 0.20)],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let panelBackground = Color(red: 0.12, green: 0.13, blue: 0.15)
    static let sectionBackground = Color(red: 0.15, green: 0.16, blue: 0.18)
    static let sectionBorder = Color(red: 0.34, green: 0.36, blue: 0.40).opacity(0.65)
    static let mutedText = Color(red: 0.76, green: 0.78, blue: 0.82)
    static let violetAccent = Color(red: 0.62, green: 0.54, blue: 0.96)
    static let cyanAccent = Color(red: 0.39, green: 0.77, blue: 0.92)
    static let roseAccent = Color(red: 0.92, green: 0.46, blue: 0.58)
}
