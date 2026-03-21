import SwiftUI

struct QuickAddView: View {
    @State private var text: String = ""
    @FocusState private var isInputFocused: Bool
    let onSubmit: (String) -> Void

    var body: some View {
        HStack(spacing: 8) {
            TextField("Add a task", text: $text)
                .textFieldStyle(.roundedBorder)
                .focused($isInputFocused)
                .onSubmit(submit)

            Button("Add") {
                submit()
            }
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .onAppear {
            isInputFocused = true
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
