import SwiftUI

struct AppIconButtonStyle: ButtonStyle {
    var isEmphasized: Bool = false
    @Environment(\.themeTokens) private var tokens

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(SpacingTokens.sm)
            .background(
                (isEmphasized ? tokens.textPrimary.opacity(0.12) : tokens.textPrimary.opacity(0.06)),
                in: RoundedRectangle(cornerRadius: RadiusTokens.sm)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.88 : 1.0)
            .animation(MotionTokens.hoverEase, value: configuration.isPressed)
    }
}

struct RowStateModifier: ViewModifier {
    let isHovered: Bool
    let isSelected: Bool
    @Environment(\.themeTokens) private var tokens

    private var bgColor: Color {
        if isSelected { return tokens.accentTerracotta.opacity(0.08) }
        if isHovered { return tokens.bgSubtle }
        return tokens.bgFloating.opacity(0.22)
    }

    private var borderOpacity: Double {
        if isSelected { return 0.18 }
        if isHovered { return 0.12 }
        return 0.06
    }

    func body(content: Content) -> some View {
        content
            .background(bgColor, in: RoundedRectangle(cornerRadius: RadiusTokens.sm))
            .overlay {
                RoundedRectangle(cornerRadius: RadiusTokens.sm)
                    .stroke(tokens.sectionBorder.opacity(borderOpacity), lineWidth: 0.5)
            }
            .shadow(
                color: isHovered && !isSelected ? .black.opacity(0.12) : .clear,
                radius: isHovered && !isSelected ? 3 : 0,
                y: isHovered && !isSelected ? 1 : 0
            )
            .animation(MotionTokens.focusEase, value: isHovered)
            .animation(MotionTokens.focusEase, value: isSelected)
    }
}

extension View {
    func appRowState(isHovered: Bool, isSelected: Bool) -> some View {
        modifier(RowStateModifier(isHovered: isHovered, isSelected: isSelected))
    }
}
