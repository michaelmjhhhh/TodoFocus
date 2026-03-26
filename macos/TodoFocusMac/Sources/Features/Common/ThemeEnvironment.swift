import SwiftUI

// Expose ThemeStore.Theme through environment
private struct ThemeModeKey: EnvironmentKey {
    static let defaultValue: ThemeStore.Theme = .dark
}

// Expose ThemeTokens through environment
private struct ThemeTokensKey: EnvironmentKey {
    static let defaultValue: ThemeTokens = ThemeTokens(theme: .dark)
}

extension EnvironmentValues {
    var themeMode: ThemeStore.Theme {
        get { self[ThemeModeKey.self] }
        set { self[ThemeModeKey.self] = newValue }
    }

    var themeTokens: ThemeTokens {
        get { self[ThemeTokensKey.self] }
        set { self[ThemeTokensKey.self] = newValue }
    }
}

extension View {
    func themeMode(_ theme: ThemeStore.Theme) -> some View {
        environment(\.themeMode, theme)
    }

    func themeTokens(_ tokens: ThemeTokens) -> some View {
        environment(\.themeTokens, tokens)
    }
}