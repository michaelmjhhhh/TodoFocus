import SwiftUI

struct QuickAddView: View {
    @State private var text: String = ""
    let onSubmit: (String) -> Void

    var body: some View {
        HStack(spacing: 8) {
            TextField("Add a task", text: $text)
                .textFieldStyle(.roundedBorder)
                .onSubmit(submit)

            Button("Add") {
                submit()
            }
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private func submit() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return
        }
        onSubmit(trimmed)
        text = ""
    }
}
