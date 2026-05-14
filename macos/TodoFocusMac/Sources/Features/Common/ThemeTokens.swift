import SwiftUI
import Observation

@Observable
final class ThemeTokens: Sendable {
    // MARK: - Backgrounds
    var bgBase: Color { Color(red: 0.067, green: 0.067, blue: 0.063) }
    var bgElevated: Color { Color(red: 0.102, green: 0.098, blue: 0.090) }
    var bgFloating: Color { Color(red: 0.141, green: 0.137, blue: 0.125) }
    var bgSubtle: Color { Color(red: 0.118, green: 0.114, blue: 0.106) }

    // MARK: - Text
    var textPrimary: Color { Color(red: 0.941, green: 0.929, blue: 0.902) }
    var textSecondary: Color { Color(red: 0.608, green: 0.584, blue: 0.565) }
    var textTertiary: Color { Color(red: 0.420, green: 0.396, blue: 0.376) }

    // MARK: - Semantic
    var success: Color { Color(red: 0.37, green: 0.81, blue: 0.61) }
    var warning: Color { Color(red: 0.97, green: 0.73, blue: 0.31) }
    var danger: Color { Color(red: 0.90, green: 0.42, blue: 0.42) }

    // MARK: - Accents
    var accentBlue: Color { Color(red: 0.478, green: 0.671, blue: 0.859) }
    var accentViolet: Color { Color(red: 0.608, green: 0.561, blue: 0.831) }
    var accentAmber: Color { Color(red: 0.95, green: 0.64, blue: 0.29) }
    var accentTerracotta: Color { Color(red: 0.831, green: 0.443, blue: 0.306) }

    // MARK: - Gradients
    var appBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.067, green: 0.067, blue: 0.063),
                Color(red: 0.067, green: 0.067, blue: 0.063),
                Color(red: 0.075, green: 0.075, blue: 0.071)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    var accent: LinearGradient {
        LinearGradient(
            colors: [accentAmber, accentViolet],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    // MARK: - Aliases
    var panelBackground: Color { bgElevated }
    var sectionBackground: Color { bgElevated }
    var sectionBorder: Color { Color(red: 0.941, green: 0.929, blue: 0.902).opacity(0.05) }
    var mutedText: Color { textSecondary }
    var violetAccent: Color { accentViolet }
    var cyanAccent: Color { accentBlue }
    var roseAccent: Color { danger }

    // MARK: - Input Surfaces
    var inputSurface: Color { bgFloating.opacity(0.78) }
    var inputBorder: Color { sectionBorder.opacity(0.95) }
    var inputBorderFocused: Color { accentTerracotta.opacity(0.72) }
    var inputGlow: Color { accentTerracotta.opacity(0.22) }
}
