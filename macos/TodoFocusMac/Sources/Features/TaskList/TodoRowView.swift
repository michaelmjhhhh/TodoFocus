import SwiftUI

struct DebtBadge: View {
    let timeString: String

    var body: some View {
        Text("Overdue \(timeString)")
            .font(.caption2.weight(.medium))
            .foregroundStyle(Color.red)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.red.opacity(0.12))
            .cornerRadius(4)
    }
}

struct TodoRowView: View {
    let todo: Todo
    let store: TodoAppStore
    let listColor: Color?
    let isSelected: Bool
    let onSelect: () -> Void
    let onToggleComplete: () -> Void
    let onToggleImportant: () -> Void
    let onDelete: () -> Void
    @Environment(\.themeTokens) private var tokens
    @State private var isHovered: Bool = false

    static func shouldShowSecondaryControls(isHovered: Bool, isSelected: Bool) -> Bool {
        isHovered || isSelected
    }

    private var isSecondaryControlsVisible: Bool {
        Self.shouldShowSecondaryControls(isHovered: isHovered, isSelected: isSelected)
    }

    private var indicatorColor: Color {
        if todo.isImportant {
            return tokens.warning
        }
        return listColor ?? tokens.accentTerracotta
    }

    private var showIndicator: Bool {
        todo.isImportant || listColor != nil
    }

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onToggleComplete) {
                ZStack {
                    // Outer circle
                    Circle()
                        .fill(todo.isCompleted
                            ? tokens.accentTerracotta
                            : tokens.bgFloating)
                        .overlay {
                            Circle()
                                .stroke(
                                    todo.isCompleted
                                        ? tokens.accentTerracotta.opacity(0.5)
                                        : tokens.textTertiary.opacity(0.3),
                                    lineWidth: 1.5
                                )
                        }

                    // Inner glow ring for completed
                    if todo.isCompleted {
                        Circle()
                            .stroke(tokens.accentTerracotta.opacity(0.3), lineWidth: 2)
                            .padding(3)
                    }

                    // Checkmark
                    Image(systemName: todo.isCompleted ? "checkmark" : "circle")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(todo.isCompleted ? .white : tokens.textTertiary)
                }
                .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .foregroundStyle(todo.isCompleted ? tokens.success : tokens.textPrimary)
            .scaleEffect(todo.isCompleted ? 1.0 : 0.95)
            .animation(MotionTokens.hoverEase, value: todo.isCompleted)
            .accessibilityLabel(todo.isCompleted ? "Mark as not completed" : "Mark as completed")

            VStack(alignment: .leading, spacing: 2) {
                Text(todo.title)
                    .strikethrough(todo.isCompleted)
                    .font(.body.weight(todo.isCompleted ? .regular : .medium))
                    .foregroundStyle(isSelected ? tokens.textPrimary : .primary)
                if let dueDate = todo.dueDate {
                    Label {
                        Text(dueDate, style: .date)
                    } icon: {
                        Image(systemName: "calendar")
                    }
                    .font(.caption2)
                    .foregroundStyle(isSelected ? tokens.textPrimary.opacity(0.82) : tokens.mutedText)
                }
                if todo.isOverdue {
                    DebtBadge(timeString: store.formatDebt(todo.debtSeconds ?? 0))
                }
            }

            Spacer()

            HStack(spacing: 8) {
                Button(action: onToggleImportant) {
                    Image(systemName: todo.isImportant ? "star.fill" : "star")
                }
                .buttonStyle(AppIconButtonStyle())
                .foregroundStyle(todo.isImportant ? tokens.warning : tokens.mutedText)

                Button(action: onDelete) {
                    Image(systemName: "trash")
                }
                .buttonStyle(AppIconButtonStyle())
                .foregroundStyle(tokens.mutedText)
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
