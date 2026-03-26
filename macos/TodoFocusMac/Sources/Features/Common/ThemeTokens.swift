import SwiftUI
import Observation

@Observable
final class ThemeTokens {
    let theme: ThemeStore.Theme

    init(theme: ThemeStore.Theme = .dark) {
        self.theme = theme
    }

    // MARK: - Backgrounds
    var bgBase: Color {
        theme == .light ? Color(red: 0.961, green: 0.953, blue: 0.933) : Color(red: 0.039, green: 0.039, blue: 0.039)
    }
    var bgElevated: Color {
        theme == .light ? Color.white : Color(red: 0.11, green: 0.11, blue: 0.11)
    }
    var bgFloating: Color {
        theme == .light ? Color(red: 0.980, green: 0.980, blue: 0.980) : Color(red: 0.15, green: 0.15, blue: 0.15)
    }

    // MARK: - Text
    var textPrimary: Color {
        theme == .light ? Color(red: 0.102, green: 0.102, blue: 0.102) : Color(red: 0.98, green: 0.98, blue: 0.98)
    }
    var textSecondary: Color {
        theme == .light ? Color(red: 0.420, green: 0.420, blue: 0.420) : Color(red: 0.55, green: 0.55, blue: 0.55)
    }
    var textTertiary: Color {
        theme == .light ? Color(red: 0.608, green: 0.608, blue: 0.608) : Color(red: 0.40, green: 0.40, blue: 0.40)
    }

    // MARK: - Semantic
    var success: Color {
        theme == .light ? Color(red: 0.063, green: 0.725, blue: 0.506) : Color(red: 0.37, green: 0.81, blue: 0.61)
    }
    var warning: Color {
        theme == .light ? Color(red: 0.961, green: 0.620, blue: 0.043) : Color(red: 0.97, green: 0.73, blue: 0.31)
    }
    var danger: Color {
        theme == .light ? Color(red: 0.937, green: 0.267, blue: 0.267) : Color(red: 0.94, green: 0.41, blue: 0.47)
    }

    // MARK: - Accents
    var accentBlue: Color {
        theme == .light ? Color(red: 0.231, green: 0.510, blue: 0.965) : Color(red: 0.40, green: 0.71, blue: 0.96)
    }
    var accentViolet: Color {
        theme == .light ? Color(red: 0.545, green: 0.361, blue: 0.965) : Color(red: 0.60, green: 0.53, blue: 0.95)
    }
    var accentAmber: Color {
        theme == .light ? Color(red: 0.961, green: 0.620, blue: 0.043) : Color(red: 0.95, green: 0.64, blue: 0.29)
    }
    var accentTerracotta: Color {
        theme == .light ? Color(red: 0.918, green: 0.345, blue: 0.047) : Color(red: 0.769, green: 0.408, blue: 0.286)
    }

    // MARK: - Gradients
    var appBackground: LinearGradient {
        if theme == .light {
            return LinearGradient(
                colors: [
                    Color(red: 0.961, green: 0.953, blue: 0.933),
                    Color(red: 0.961, green: 0.953, blue: 0.933),
                    Color(red: 0.95, green: 0.94, blue: 0.93)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            return LinearGradient(
                colors: [
                    Color(red: 0.039, green: 0.039, blue: 0.039),
                    Color(red: 0.039, green: 0.039, blue: 0.039),
                    Color(red: 0.05, green: 0.05, blue: 0.05)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
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
    var sectionBorder: Color {
        theme == .light ? Color.black.opacity(0.08) : Color.white.opacity(0.06)
    }
    var mutedText: Color { textSecondary }
    var violetAccent: Color { accentViolet }
    var cyanAccent: Color { accentBlue }
    var roseAccent: Color { danger }
}
