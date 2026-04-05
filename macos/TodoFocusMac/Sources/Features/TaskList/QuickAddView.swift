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
                    .font(.system(size: 13, weight: .semibold))
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
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(tokens.inputSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isInputFocused ? tokens.inputBorderFocused : tokens.inputBorder, lineWidth: isInputFocused ? 1.2 : 1)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(tokens.inputGlow.opacity(isInputFocused ? 0.55 : 0), lineWidth: 4)
                    .blur(radius: 0.7)
            }
            .animation(MotionTokens.focusEase, value: isInputFocused)

            Button {
                submit()
            } label: {
                Text("Add")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .frame(minWidth: 54)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
            }
            .buttonStyle(.plain)
            .foregroundStyle(canSubmit ? tokens.textPrimary : tokens.textTertiary)
            .background(canSubmit ? tokens.accentTerracotta.opacity(0.90) : tokens.bgFloating, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(canSubmit ? tokens.accentTerracotta.opacity(0.55) : tokens.inputBorder, lineWidth: 1)
            }
            .opacity(canSubmit ? 1 : 0.72)
            .disabled(!canSubmit)
            .accessibilityLabel("Add task")
            .help("Add task")
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
