import SwiftUI

struct AppIconButtonStyle: ButtonStyle {
    var isEmphasized: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(6)
            .background((isEmphasized ? Color.white.opacity(0.15) : Color.white.opacity(0.08)), in: RoundedRectangle(cornerRadius: 8))
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.88 : 1.0)
            .animation(MotionTokens.quickDuration == 0 ? .none : MotionTokens.hoverEase, value: configuration.isPressed)
    }
}

struct RowStateModifier: ViewModifier {
    let isHovered: Bool
    let isSelected: Bool
    @Environment(\.themeTokens) private var tokens

    func body(content: Content) -> some View {
        let isActive = isHovered || isSelected
        content
            .background(
                (isSelected ? tokens.textPrimary.opacity(0.20) : tokens.textPrimary.opacity(isHovered ? 0.10 : 0.04)),
                in: RoundedRectangle(cornerRadius: 8)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isSelected
                            ? tokens.textPrimary.opacity(0.22)
                            : tokens.sectionBorder.opacity(isActive ? 0.95 : 0),
                        lineWidth: isSelected ? 1.2 : 1
                    )
            }
            .shadow(
                color: isSelected ? Color.black.opacity(0.22) : .clear,
                radius: isSelected ? 6 : 0,
                y: isSelected ? 2 : 0
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
