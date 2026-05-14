import SwiftUI
import Observation

@Observable
final class ThemeStore {
    enum Theme: String {
        case dark
    }

    let theme: Theme = .dark

    var preferredColorScheme: ColorScheme? { .dark }
}
