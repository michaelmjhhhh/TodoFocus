import SwiftUI

struct AppIconButtonStyle: ButtonStyle {
    var isEmphasized: Bool = false
    @Environment(\.themeTokens) private var tokens

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(6)
            .background((isEmphasized ? tokens.hairline : tokens.hairlineSoft), in: RoundedRectangle(cornerRadius: 8))
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
        content
            .background(
                (isSelected ? tokens.surfaceCreamStrong : (isHovered ? tokens.bgFloating : tokens.bgBase)),
                in: RoundedRectangle(cornerRadius: 8)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isSelected ? tokens.hairline : (isHovered ? tokens.hairline : tokens.hairlineSoft),
                        lineWidth: 1
                    )
            }
            .shadow(
                color: isSelected ? Color.black.opacity(0.06) : Color.black.opacity(0.03),
                radius: isSelected ? 3 : 1,
                y: isSelected ? 1 : 0.5
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
