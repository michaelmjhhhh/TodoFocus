import SwiftUI

private struct ThemeTokensKey: EnvironmentKey {
    static let defaultValue: ThemeTokens = ThemeTokens()
}

extension EnvironmentValues {
    var themeTokens: ThemeTokens {
        get { self[ThemeTokensKey.self] }
        set { self[ThemeTokensKey.self] = newValue }
    }
}

extension View {
    func themeTokens(_ tokens: ThemeTokens) -> some View {
        environment(\.themeTokens, tokens)
    }
}
