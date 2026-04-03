import SwiftUI

struct DebtBadge: View {
    let timeString: String
    @Environment(\.themeTokens) private var tokens

    var body: some View {
        Text("Overdue \(timeString)")
            .font(tokens.uiLabel(11, weight: .medium))
            .foregroundStyle(tokens.warning)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(tokens.warning.opacity(0.16), in: Capsule())
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
            return .yellow
        }
        return listColor ?? tokens.accentTerracotta
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
                    .background(todo.isCompleted ? tokens.success.opacity(0.22) : tokens.bgFloating.opacity(0.95), in: Circle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(todo.isCompleted ? tokens.success : tokens.textPrimary)
            .overlay {
                Circle()
                    .stroke(tokens.sectionBorder.opacity(todo.isCompleted ? 0.55 : 0.95), lineWidth: 1)
                    .padding(2)
            }
            .accessibilityLabel(todo.isCompleted ? "Mark as not completed" : "Mark as completed")
            .help(todo.isCompleted ? "Mark as not completed" : "Mark as completed")

            VStack(alignment: .leading, spacing: 2) {
                Text(todo.title)
                    .strikethrough(todo.isCompleted)
                    .font(tokens.uiLabel(14, weight: todo.isCompleted ? .regular : .medium))
                    .foregroundStyle(isSelected ? tokens.textPrimary : tokens.textPrimary)
                if let dueDate = todo.dueDate {
                    Label {
                        Text(dueDate, style: .date)
                    } icon: {
                        Image(systemName: "calendar")
                    }
                    .font(.caption2)
                    .foregroundStyle(isSelected ? tokens.textSecondary : tokens.mutedText)
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
                .foregroundStyle(todo.isImportant ? Color.yellow : tokens.mutedText)
                .accessibilityLabel(todo.isImportant ? "Mark as not important" : "Mark as important")
                .help(todo.isImportant ? "Mark as not important" : "Mark as important")

                Button(action: onDelete) {
                    Image(systemName: "trash")
                }
                .buttonStyle(AppIconButtonStyle())
                .foregroundStyle(tokens.mutedText)
                .accessibilityLabel("Delete task")
                .help("Delete task")
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
