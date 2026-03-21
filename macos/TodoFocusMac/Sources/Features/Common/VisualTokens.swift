import SwiftUI

enum VisualTokens {
    static let appBackground = LinearGradient(
        colors: [
            Color(red: 0.07, green: 0.09, blue: 0.13),
            Color(red: 0.10, green: 0.12, blue: 0.18),
            Color(red: 0.08, green: 0.11, blue: 0.16)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let accent = LinearGradient(
        colors: [Color(red: 0.26, green: 0.64, blue: 1.0), Color(red: 0.32, green: 0.42, blue: 0.98)],
        startPoint: .leading,
        endPoint: .trailing
    )
}
