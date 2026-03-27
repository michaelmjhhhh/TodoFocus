import SwiftUI

struct QuickAddView: View {
    @Environment(\.themeTokens) private var tokens
    @State private var text: String = ""
    @FocusState private var isInputFocused: Bool
    let onSubmit: (String) -> Void

    var body: some View {
        HStack(spacing: 10) {
            // Plus icon
            Image(systemName: "plus")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(tokens.textTertiary)

            TextField("Add a task...", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .foregroundStyle(tokens.textPrimary)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(tokens.bgBase.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(tokens.sectionBorder, lineWidth: 1)
                }
                .focused($isInputFocused)
                .onSubmit(submit)

            Button("Add") {
                submit()
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(tokens.accentTerracotta, in: Capsule())
            .buttonStyle(.plain)
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(12)
        .background(tokens.bgElevated, in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(tokens.sectionBorder.opacity(0.8), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.18), radius: 10, y: 4)
        .background {
            Button("") {
                isInputFocused = true
            }
            .keyboardShortcut("n", modifiers: [.command, .shift])
            .opacity(0)
            .allowsHitTesting(false)
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
