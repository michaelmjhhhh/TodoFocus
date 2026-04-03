import SwiftUI
import Observation

@Observable
final class ThemeTokens: Sendable {
    let theme: ThemeStore.Theme

    init(theme: ThemeStore.Theme = .dark) {
        self.theme = theme
    }

    // MARK: - Backgrounds
    var bgBase: Color {
        theme == .light ? Color(red: 0.961, green: 0.953, blue: 0.933) : Color(hex: "#1A1A18")
    }
    var bgElevated: Color {
        theme == .light ? Color.white : Color(hex: "#242422")
    }
    var bgFloating: Color {
        theme == .light ? Color(red: 0.980, green: 0.980, blue: 0.980) : Color(hex: "#2A2A27")
    }

    // MARK: - Text
    var textPrimary: Color {
        theme == .light ? Color(red: 0.102, green: 0.102, blue: 0.102) : Color(hex: "#FCF9F3")
    }
    var textSecondary: Color {
        theme == .light ? Color(red: 0.420, green: 0.420, blue: 0.420) : Color(hex: "#CCB89E")
    }
    var textTertiary: Color {
        theme == .light ? Color(red: 0.608, green: 0.608, blue: 0.608) : Color(hex: "#9C8E7B")
    }

    // MARK: - Semantic
    var success: Color {
        theme == .light ? Color(red: 0.063, green: 0.725, blue: 0.506) : Color(red: 0.49, green: 0.78, blue: 0.57)
    }
    var warning: Color {
        theme == .light ? Color(red: 0.961, green: 0.620, blue: 0.043) : Color(hex: "#D97706")
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
        theme == .light ? Color(red: 0.961, green: 0.620, blue: 0.043) : Color(hex: "#D97706")
    }
    var accentTerracotta: Color {
        theme == .light ? Color(red: 0.918, green: 0.345, blue: 0.047) : Color(hex: "#D97706")
    }
    var accentSecondary: Color {
        theme == .light ? Color(red: 0.545, green: 0.361, blue: 0.965) : Color(hex: "#CCB89E")
    }
    var accentMuted: Color {
        theme == .light ? Color(red: 0.608, green: 0.608, blue: 0.608) : Color(hex: "#9C8E7B")
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
                    Color(hex: "#1A1A18"),
                    Color(hex: "#1A1A18"),
                    Color(hex: "#211F1C")
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
        theme == .light ? Color.black.opacity(0.08) : accentMuted.opacity(0.28)
    }
    var mutedText: Color { textSecondary }
    var violetAccent: Color { accentViolet }
    var cyanAccent: Color { accentBlue }
    var roseAccent: Color { danger }
    var sectionSeparator: Color {
        theme == .light ? Color.black.opacity(0.08) : accentMuted.opacity(0.40)
    }

    // MARK: - Input Surfaces
    var inputSurface: Color {
        theme == .light ? Color.white.opacity(0.96) : bgFloating.opacity(0.90)
    }
    var inputBorder: Color {
        theme == .light ? Color.black.opacity(0.10) : accentMuted.opacity(0.34)
    }
    var inputBorderFocused: Color {
        theme == .light ? accentTerracotta.opacity(0.58) : accentAmber.opacity(0.72)
    }
    var inputGlow: Color {
        theme == .light ? accentTerracotta.opacity(0.24) : accentAmber.opacity(0.22)
    }

    // MARK: - Typography
    var headlineFontDesign: Font.Design {
        theme == .dark ? .serif : .default
    }

    func editorialTitle(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: headlineFontDesign)
    }

    func uiLabel(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
}
