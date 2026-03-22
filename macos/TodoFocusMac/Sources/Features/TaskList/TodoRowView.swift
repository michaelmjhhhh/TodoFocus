import SwiftUI

struct TodoRowView: View {
    let todo: Todo
    let listColor: Color?
    let isSelected: Bool
    let onSelect: () -> Void
    let onToggleComplete: () -> Void
    let onToggleImportant: () -> Void
    let onDelete: () -> Void
    @State private var isHovered: Bool = false

    static func shouldShowSecondaryControls(isHovered: Bool, isSelected: Bool) -> Bool {
        isHovered || isSelected
    }

    private var isSecondaryControlsVisible: Bool {
        Self.shouldShowSecondaryControls(isHovered: isHovered, isSelected: isSelected)
    }

    private var indicatorColor: Color {
        if todo.isImportant {
            return .yellow
        }
        return listColor ?? VisualTokens.accentTerracotta
    }

    private var showIndicator: Bool {
        todo.isImportant || listColor != nil
    }

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onToggleComplete) {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 17, weight: .semibold))
                    .padding(5)
                    .background(todo.isCompleted ? Color.green.opacity(0.22) : Color.white.opacity(0.12), in: Circle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(todo.isCompleted ? Color.green : Color.white.opacity(0.94))
            .overlay {
                Circle()
                    .stroke(Color.white.opacity(todo.isCompleted ? 0.10 : 0.20), lineWidth: 1)
                    .padding(2)
            }
            .accessibilityLabel(todo.isCompleted ? "Mark as not completed" : "Mark as completed")

            VStack(alignment: .leading, spacing: 2) {
                Text(todo.title)
                    .strikethrough(todo.isCompleted)
                    .font(.body.weight(todo.isCompleted ? .regular : .medium))
                    .foregroundStyle(isSelected ? Color.white : .primary)
                if let dueDate = todo.dueDate {
                    Label {
                        Text(dueDate, style: .date)
                    } icon: {
                        Image(systemName: "calendar")
                    }
                    .font(.caption2)
                    .foregroundStyle(isSelected ? Color.white.opacity(0.82) : VisualTokens.mutedText)
                }
            }

            Spacer()

            HStack(spacing: 8) {
                Button(action: onToggleImportant) {
                    Image(systemName: todo.isImportant ? "star.fill" : "star")
                }
                .buttonStyle(AppIconButtonStyle())
                .foregroundStyle(todo.isImportant ? Color.yellow : VisualTokens.mutedText)

                Button(action: onDelete) {
                    Image(systemName: "trash")
                }
                .buttonStyle(AppIconButtonStyle())
                .foregroundStyle(VisualTokens.mutedText)
            }
            .frame(width: 62, alignment: .trailing)
            .opacity(isSecondaryControlsVisible ? 1 : 0.001)
            .offset(x: isSecondaryControlsVisible ? 0 : 4)
            .allowsHitTesting(isSecondaryControlsVisible)
            .animation(MotionTokens.hoverEase, value: isSecondaryControlsVisible)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .appRowState(isHovered: isHovered, isSelected: isSelected)
        .overlay(alignment: .leading) {
            if showIndicator {
                RoundedRectangle(cornerRadius: 8)
                    .fill(indicatorColor)
                    .frame(width: 3)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .onHover { hovering in
            isHovered = hovering
        }
        .animation(MotionTokens.interactiveSpring, value: todo.isCompleted)
        .animation(MotionTokens.focusEase, value: isSelected)
    }
}
