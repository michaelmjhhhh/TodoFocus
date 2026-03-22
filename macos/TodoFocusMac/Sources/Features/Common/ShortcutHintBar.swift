import SwiftUI

struct ShortcutHintBar: View {
    var needsAccessibilityPermission: Bool = false
    var onRequestPermission: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 16) {
            if needsAccessibilityPermission {
                permissionWarning
            }
            
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
    
    private var permissionWarning: some View {
        Button {
            onRequestPermission?()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                Text("Enable Accessibility for ⌘⇧T")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.orange)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(.orange.opacity(0.15))
            )
        }
        .buttonStyle(.plain)
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
    func shortcutHintBar(needsAccessibilityPermission: Bool = false, onRequestPermission: (() -> Void)? = nil) -> some View {
        modifier(ShortcutHintBarModifier(
            needsAccessibilityPermission: needsAccessibilityPermission,
            onRequestPermission: onRequestPermission
        ))
    }
}
