import SwiftUI

struct QuickAddView: View {
    @Environment(\.themeTokens) private var tokens
    @State private var text: String = ""
    @FocusState private var isInputFocused: Bool
    let onSubmit: (String) -> Void

    private var canSubmit: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var focusBinding: Binding<Bool> {
        Binding(
            get: { isInputFocused },
            set: { isInputFocused = $0 }
        )
    }

    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(TypographyTokens.headingSmall)
                    .foregroundStyle(isInputFocused ? tokens.accentTerracotta : tokens.textTertiary)
                    .accessibilityHidden(true)

                QuickAddHighlightingTextField(
                    text: $text,
                    isFocused: focusBinding,
                    placeholder: "Add a task (⌘⇧N)",
                    highlightColor: NSColor(tokens.accentTerracotta)
                ) {
                    submit()
                }
                .frame(height: 20)
                    .accessibilityLabel("Task title")
            }
            .padding(.horizontal, SpacingTokens.md)
            .padding(.vertical, SpacingTokens.sm)
            .background(tokens.inputSurface, in: RoundedRectangle(cornerRadius: RadiusTokens.md, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: RadiusTokens.md, style: .continuous)
                    .stroke(isInputFocused ? tokens.inputBorderFocused : Color.clear, lineWidth: isInputFocused ? 1.2 : 0)
            }
            .overlay {
                RoundedRectangle(cornerRadius: RadiusTokens.md, style: .continuous)
                    .stroke(tokens.inputGlow.opacity(isInputFocused ? 0.55 : 0), lineWidth: 4)
                    .blur(radius: 0.7)
            }
            .animation(MotionTokens.focusEase, value: isInputFocused)

            Button {
                submit()
            } label: {
                Text("Add")
                    .font(TypographyTokens.headingSmall)
                    .frame(minWidth: 54)
                    .padding(.horizontal, SpacingTokens.md)
                    .padding(.vertical, SpacingTokens.sm + 1)
            }
            .buttonStyle(.plain)
            .foregroundStyle(canSubmit ? tokens.textPrimary : tokens.textTertiary)
            .background(canSubmit ? tokens.accentTerracotta.opacity(0.90) : tokens.bgFloating, in: RoundedRectangle(cornerRadius: RadiusTokens.md, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: RadiusTokens.md, style: .continuous)
                    .stroke(canSubmit ? tokens.accentTerracotta.opacity(0.55) : Color.clear, lineWidth: 1)
            }
            .opacity(canSubmit ? 1 : 0.72)
            .disabled(!canSubmit)
            .accessibilityLabel("Add task")
            .animation(MotionTokens.focusEase, value: canSubmit)
        }
        .background {
            Button("") {
                isInputFocused = true
            }
            .keyboardShortcut("n", modifiers: [.command, .shift])
            .opacity(0)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
        .onReceive(NotificationCenter.default.publisher(for: .todoFocusQuickAddFocusRequested)) { _ in
            isInputFocused = false
            DispatchQueue.main.async {
                isInputFocused = true
            }
        }
    }

    private func submit() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return
        }
        onSubmit(trimmed)
        text = ""
        isInputFocused = true
    }
}
