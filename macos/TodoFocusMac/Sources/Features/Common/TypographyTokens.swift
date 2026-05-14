import SwiftUI
import AppKit

enum TypographyTokens {
    private static let newsreaderFamily = "Newsreader 16pt"

    static let displayLarge: Font = .custom(newsreaderFamily, size: 28)
    static let displaySmall: Font = .custom(newsreaderFamily, size: 20)

    static let headingLarge: Font = .system(size: 15, weight: .semibold)
    static let headingSmall: Font = .system(size: 13, weight: .medium)

    static let bodyLarge: Font = .system(size: 14)
    static let bodySmall: Font = .system(size: 13)

    static let caption: Font = .system(size: 11)
    static let micro: Font = .system(size: 10, weight: .medium)

    @MainActor static let nsDisplayLarge: NSFont = NSFont(name: newsreaderFamily, size: 28) ?? .systemFont(ofSize: 28)
    @MainActor static let nsDisplaySmall: NSFont = NSFont(name: newsreaderFamily, size: 20) ?? .systemFont(ofSize: 20)
    @MainActor static let nsBodyLarge: NSFont = .systemFont(ofSize: 14)
    @MainActor static let nsBodySmall: NSFont = .systemFont(ofSize: 13)
}
