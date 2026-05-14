import SwiftUI

struct ShortcutHintItem: Identifiable, Equatable {
    let key: String
    let action: String

    var id: String { key }
    var shortAction: String {
        switch action {
        case "Global Quick Capture":
            return "Capture"
        case "Daily Review Preview":
            return "Review"
        case "Start Deep Focus":
            return "Focus"
        case "Search Tasks":
            return "Search"
        case "New Task":
            return "New"
        default:
            return action
        }
    }
}

struct ShortcutHintBar: View {
    static let availableShortcuts: [ShortcutHintItem] = [
        ShortcutHintItem(key: "⌘⇧T", action: "Global Quick Capture"),
        ShortcutHintItem(key: "⌘⇧U", action: "Daily Review Preview"),
        ShortcutHintItem(key: "⌘⇧F", action: "Start Deep Focus"),
        ShortcutHintItem(key: "⌘K", action: "Search Tasks"),
        ShortcutHintItem(key: "⌘⇧N", action: "New Task")
    ]

    private static let visibleShortcutKeys = ["⌘⇧T", "⌘⇧U", "⌘K", "⌘⇧F", "⌘⇧N"]
    private static var visibleShortcuts: [ShortcutHintItem] {
        visibleShortcutKeys.compactMap { key in
            availableShortcuts.first { $0.key == key }
        }
    }

    var needsAccessibilityPermission: Bool = false
    var onRequestPermission: (() -> Void)?
    @Environment(\.themeTokens) private var tokens

    var body: some View {
        HStack(spacing: 8) {
            if needsAccessibilityPermission {
                permissionWarning
                dotSeparator
            }

            HStack(spacing: 7) {
                ForEach(Array(Self.visibleShortcuts.enumerated()), id: \.element.id) { index, shortcut in
                    shortcutHint(shortcut)
                    if index < Self.visibleShortcuts.count - 1 {
                        dotSeparator
                    }
                }
            }
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(tokens.bgFloating.opacity(0.30))
                .overlay(
                    Capsule()
                        .stroke(tokens.sectionBorder.opacity(0.18), lineWidth: 1)
                )
        )
        .fixedSize(horizontal: true, vertical: false)
    }

    private var dotSeparator: some View {
        Text("·")
            .font(TypographyTokens.micro)
            .foregroundStyle(tokens.textTertiary.opacity(0.28))
    }
    
    private var permissionWarning: some View {
        Button {
            onRequestPermission?()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "lock.open.fill")
                    .font(TypographyTokens.micro)
                Text("Quick Capture access")
                    .font(TypographyTokens.micro)
            }
            .foregroundStyle(tokens.accentTerracotta.opacity(0.66))
        }
        .buttonStyle(.plain)
        .help("Enable Accessibility permission for Global Quick Capture")
    }

    private func shortcutHint(_ shortcut: ShortcutHintItem) -> some View {
        HStack(spacing: 5) {
            Text(shortcut.shortAction)
                .font(TypographyTokens.micro)
                .foregroundStyle(tokens.textSecondary.opacity(0.86))
            Text(shortcut.key)
                .font(TypographyTokens.micro)
                .foregroundStyle(tokens.textTertiary.opacity(0.72))
        }
        .help(shortcut.action)
    }
}

struct ShortcutHintBarModifier: ViewModifier {
    var needsAccessibilityPermission: Bool = false
    var onRequestPermission: (() -> Void)?
    
    func body(content: Content) -> some View {
        VStack(spacing: 8) {
            content
            ShortcutHintBar(
                needsAccessibilityPermission: needsAccessibilityPermission,
                onRequestPermission: onRequestPermission
            )
        }
    }
}

extension View {
    func shortcutHintBar(
        needsAccessibilityPermission: Bool = false,
        onRequestPermission: (() -> Void)? = nil
    ) -> some View {
        modifier(ShortcutHintBarModifier(
            needsAccessibilityPermission: needsAccessibilityPermission,
            onRequestPermission: onRequestPermission
        ))
    }
}
