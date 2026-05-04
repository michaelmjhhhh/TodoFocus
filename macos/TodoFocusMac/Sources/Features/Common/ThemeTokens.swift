import SwiftUI
import Observation

@Observable
final class ThemeTokens: Sendable {
    let theme: ThemeStore.Theme

    init(theme: ThemeStore.Theme = .light) {
        self.theme = theme
    }

    // MARK: - Backgrounds
    var bgBase: Color {
        theme == .light ? Color(hex: "faf9f5") : Color(hex: "181715")
    }
    var bgElevated: Color {
        theme == .light ? Color(hex: "efe9de") : Color(hex: "252320")
    }
    var bgFloating: Color {
        theme == .light ? Color(hex: "f5f0e8") : Color(hex: "1f1e1b")
    }

    // MARK: - Text
    var textPrimary: Color {
        theme == .light ? Color(hex: "141413") : Color(hex: "faf9f5")
    }
    var textSecondary: Color {
        theme == .light ? Color(hex: "3d3d3a") : Color(hex: "a09d96")
    }
    var textTertiary: Color {
        theme == .light ? Color(hex: "6c6a64") : Color(hex: "6c6a64")
    }

    // MARK: - Semantic
    var success: Color {
        theme == .light ? Color(hex: "5db872") : Color(hex: "5db872")
    }
    var warning: Color {
        theme == .light ? Color(hex: "d4a017") : Color(hex: "d4a017")
    }
    var danger: Color {
        theme == .light ? Color(hex: "c64545") : Color(hex: "c64545")
    }

    // MARK: - Accents
    var accentBlue: Color {
        theme == .light ? Color(hex: "5db8a6") : Color(hex: "5db8a6")
    }
    var accentViolet: Color {
        theme == .light ? Color(hex: "8b5cf6") : Color(hex: "9986f5")
    }
    var accentAmber: Color {
        theme == .light ? Color(hex: "e8a55a") : Color(hex: "e8a55a")
    }
    var accentTerracotta: Color {
        theme == .light ? Color(hex: "cc785c") : Color(hex: "cc785c")
    }

    // MARK: - Brand
    var hairline: Color {
        theme == .light ? Color(hex: "e6dfd8") : Color.white.opacity(0.08)
    }
    var hairlineSoft: Color {
        theme == .light ? Color(hex: "ebe6df") : Color.white.opacity(0.05)
    }
    var surfaceCreamStrong: Color {
        theme == .light ? Color(hex: "e8e0d2") : Color(hex: "252320")
    }
    var primaryActive: Color {
        Color(hex: "a9583e")
    }
    var primaryDisabled: Color {
        theme == .light ? Color(hex: "e6dfd8") : Color(hex: "3d3d3a")
    }

    // MARK: - Gradients
    var appBackground: LinearGradient {
        if theme == .light {
            return LinearGradient(
                colors: [Color(hex: "faf9f5"), Color(hex: "f5f0e8")],
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            return LinearGradient(
                colors: [Color(hex: "181715"), Color(hex: "1f1e1b")],
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
    var sectionBorder: Color { hairline }
    var mutedText: Color { textSecondary }
    var violetAccent: Color { accentViolet }
    var cyanAccent: Color { accentBlue }
    var roseAccent: Color { danger }

    // MARK: - Input Surfaces
    var inputSurface: Color {
        theme == .light ? Color(hex: "faf9f5") : bgFloating
    }
    var inputBorder: Color { hairline }
    var inputBorderFocused: Color {
        theme == .light ? accentTerracotta.opacity(0.58) : accentTerracotta.opacity(0.72)
    }
    var inputGlow: Color {
        theme == .light ? accentTerracotta.opacity(0.20) : accentTerracotta.opacity(0.18)
    }
}
