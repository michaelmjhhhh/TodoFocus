import SwiftUI
import Observation

@Observable
final class ThemeStore {
    enum Theme: String {
        case system
        case light
        case dark
    }

    private static let key = "todofocus-theme"

    var theme: Theme {
        didSet {
            UserDefaults.standard.set(theme.rawValue, forKey: Self.key)
        }
    }

    init() {
        if let raw = UserDefaults.standard.string(forKey: Self.key),
           let saved = Theme(rawValue: raw) {
            self.theme = saved
        } else {
            self.theme = .light
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch theme {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    func cycleTheme() {
        switch theme {
        case .light:
            theme = .dark
        case .dark:
            theme = .system
        case .system:
            theme = .light
        }
    }
}
