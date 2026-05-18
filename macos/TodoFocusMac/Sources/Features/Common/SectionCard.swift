import SwiftUI

struct SectionCardStyle: ViewModifier {
    @Environment(\.themeTokens) private var tokens

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, SpacingTokens.lg)
            .padding(.vertical, SpacingTokens.lg)
            .background(
                tokens.bgSubtle,
                in: RoundedRectangle(cornerRadius: RadiusTokens.lg, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: RadiusTokens.lg, style: .continuous)
                    .stroke(tokens.sectionBorder, lineWidth: 1)
            }
            .shadowMedium()
    }
}

extension View {
    func sectionCard() -> some View { modifier(SectionCardStyle()) }
}
