import SwiftUI

struct TodoRowView: View {
    let todo: Todo
    let onToggleComplete: () -> Void
    let onToggleImportant: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onToggleComplete) {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(todo.title)
                    .strikethrough(todo.isCompleted)
                    .font(.body.weight(.medium))
                if let dueDate = todo.dueDate {
                    Label {
                        Text(dueDate, style: .date)
                    } icon: {
                        Image(systemName: "calendar")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button(action: onToggleImportant) {
                Image(systemName: todo.isImportant ? "star.fill" : "star")
                    .foregroundStyle(todo.isImportant ? .yellow : .secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 10)
                .fill(VisualTokens.accent)
                .frame(width: todo.isImportant ? 3 : 0)
                .animation(.spring(response: 0.24, dampingFraction: 0.85), value: todo.isImportant)
        }
        .contentShape(Rectangle())
        .animation(.spring(response: 0.24, dampingFraction: 0.84), value: todo.isCompleted)
    }
}
