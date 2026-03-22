import SwiftUI

struct ShortcutHintBar: View {
    var body: some View {
        HStack(spacing: 16) {
            Spacer()

            HStack(spacing: 12) {
                shortcutPill("⌘⇧T", "Quick Capture")
                shortcutPill("⌘⇧F", "Focus")
                shortcutPill("⌘K", "Search")
                shortcutPill("⌘⇧N", "Add")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(VisualTokens.bgFloating.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(VisualTokens.sectionBorder, lineWidth: 1)
                )
        )
    }

    private func shortcutPill(_ key: String, _ action: String) -> some View {
        HStack(spacing: 4) {
            Text(key)
                .font(.caption2.weight(.semibold).monospaced())
                .foregroundStyle(VisualTokens.textPrimary)
            Text(action)
                .font(.caption2)
                .foregroundStyle(VisualTokens.textTertiary)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(VisualTokens.sectionBackground, in: Capsule())
    }
}

struct ShortcutHintBarModifier: ViewModifier {
    func body(content: Content) -> some View {
        VStack(spacing: 8) {
            content
            ShortcutHintBar()
        }
    }
}

extension View {
    func shortcutHintBar() -> some View {
        modifier(ShortcutHintBarModifier())
    }
}
