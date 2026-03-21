import SwiftUI

struct TodoRowView: View {
    let todo: Todo
    let isSelected: Bool
    let onSelect: () -> Void
    let onToggleComplete: () -> Void
    let onToggleImportant: () -> Void
    let onDelete: () -> Void
    @State private var isHovered: Bool = false

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onToggleComplete) {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 17, weight: .semibold))
                    .padding(5)
                    .background(todo.isCompleted ? Color.green.opacity(0.18) : Color.white.opacity(0.06), in: Circle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(todo.isCompleted ? Color.green : VisualTokens.mutedText)

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

                Button(action: onDelete) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.plain)
                .foregroundStyle(VisualTokens.mutedText)
            }
            .opacity(isHovered ? 1 : 0)
            .offset(x: isHovered ? 0 : 6)
            .allowsHitTesting(isHovered)
            .animation(.easeOut(duration: 0.14), value: isHovered)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background((isSelected ? Color.white.opacity(0.12) : Color.white.opacity(isHovered ? 0.08 : 0.04)), in: RoundedRectangle(cornerRadius: 8))
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
        .onTapGesture {
            onSelect()
        }
        .onHover { hovering in
            isHovered = hovering
        }
        .animation(.spring(response: 0.24, dampingFraction: 0.84), value: todo.isCompleted)
    }
}
