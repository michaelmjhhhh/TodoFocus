import SwiftUI

enum ShadowTokens {
    struct Subtle: ViewModifier {
        func body(content: Content) -> some View {
            content.shadow(color: .black.opacity(0.12), radius: 3, y: 1)
        }
    }

    struct Medium: ViewModifier {
        func body(content: Content) -> some View {
            content.shadow(color: .black.opacity(0.18), radius: 12, y: 4)
        }
    }

    struct Float: ViewModifier {
        func body(content: Content) -> some View {
            content.shadow(color: .black.opacity(0.25), radius: 24, y: 8)
        }
    }

    static let subtle = Subtle()
    static let medium = Medium()
    static let float = Float()
}

extension View {
    func shadowSubtle() -> some View { modifier(ShadowTokens.subtle) }
    func shadowMedium() -> some View { modifier(ShadowTokens.medium) }
    func shadowFloat() -> some View { modifier(ShadowTokens.float) }
}
