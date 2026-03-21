import SwiftUI

struct TodoRowView: View {
    let todo: Todo
    let onToggleComplete: () -> Void
    let onToggleImportant: () -> Void
    let onDeletePlaceholder: (() -> Void)?
    @State private var isHovered: Bool = false

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(todo.title)
                    .strikethrough(todo.isCompleted)
                    .font(.body.weight(todo.isCompleted ? .regular : .medium))
                if let dueDate = todo.dueDate {
                    Label {
                        Text(dueDate, style: .date)
                    } icon: {
                        Image(systemName: "calendar")
                    }
                    .font(.caption2)
                    .foregroundStyle(VisualTokens.mutedText)
                }
            }

            Spacer()

            HStack(spacing: 8) {
                Button(action: onToggleImportant) {
                    Image(systemName: todo.isImportant ? "star.fill" : "star")
                }
                .buttonStyle(.plain)
                .foregroundStyle(todo.isImportant ? Color.yellow : VisualTokens.mutedText)

                Button(action: onToggleComplete) {
                    Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                }
                .buttonStyle(.plain)
                .foregroundStyle(todo.isCompleted ? Color.green : VisualTokens.mutedText)

                Button(action: { onDeletePlaceholder?() }) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.plain)
                .foregroundStyle(VisualTokens.mutedText)
                .disabled(onDeletePlaceholder == nil)
            }
            .opacity(isHovered ? 1 : 0)
            .offset(x: isHovered ? 0 : 6)
            .allowsHitTesting(isHovered)
            .animation(.easeOut(duration: 0.14), value: isHovered)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color.white.opacity(isHovered ? 0.08 : 0.04), in: RoundedRectangle(cornerRadius: 8))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 8)
                .fill(VisualTokens.accent)
                .frame(width: todo.isImportant ? 3 : 0)
                .animation(.spring(response: 0.24, dampingFraction: 0.85), value: todo.isImportant)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(VisualTokens.sectionBorder.opacity(isHovered ? 1 : 0), lineWidth: 1)
        }
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
        .animation(.spring(response: 0.24, dampingFraction: 0.84), value: todo.isCompleted)
    }
}
