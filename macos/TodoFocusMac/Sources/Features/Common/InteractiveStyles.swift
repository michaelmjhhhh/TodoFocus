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

    func body(content: Content) -> some View {
        content
            .background(
                (isSelected ? Color.white.opacity(0.13) : Color.white.opacity(isHovered ? 0.08 : 0.04)),
                in: RoundedRectangle(cornerRadius: 8)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(VisualTokens.sectionBorder.opacity(isHovered || isSelected ? 1 : 0), lineWidth: 1)
            }
    }
}

extension View {
    func appRowState(isHovered: Bool, isSelected: Bool) -> some View {
        modifier(RowStateModifier(isHovered: isHovered, isSelected: isSelected))
    }
}
