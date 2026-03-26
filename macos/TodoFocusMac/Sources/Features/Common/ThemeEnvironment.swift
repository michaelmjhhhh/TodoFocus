import SwiftUI

// Expose ThemeStore.Theme through environment
private struct ThemeModeKey: EnvironmentKey {
    static let defaultValue: ThemeStore.Theme = .dark
}

extension EnvironmentValues {
    var themeMode: ThemeStore.Theme {
        get { self[ThemeModeKey.self] }
        set { self[ThemeModeKey.self] = newValue }
    }
}

extension View {
    func themeMode(_ theme: ThemeStore.Theme) -> some View {
        environment(\.themeMode, theme)
    }
}