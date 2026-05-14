import SwiftUI

struct DebtBadge: View {
    let timeString: String
    @Environment(\.themeTokens) private var tokens

    var body: some View {
        Text("Overdue \(timeString)")
            .font(TypographyTokens.micro)
            .foregroundStyle(tokens.danger)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(tokens.danger.opacity(0.12))
            .cornerRadius(SpacingTokens.xs)
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
    let onToggleArchive: () -> Void
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
            return tokens.accentAmber
        }
        return listColor ?? tokens.accentTerracotta
    }

    private var showIndicator: Bool {
        todo.isImportant || listColor != nil
    }

    var body: some View {
        HStack(spacing: SpacingTokens.md) {
            Button(action: onToggleComplete) {
                ZStack {
                    Circle()
                        .stroke(tokens.accentTerracotta, lineWidth: 1)
                        .frame(width: 20, height: 20)

                    if todo.isCompleted {
                        Circle()
                            .fill(tokens.accentTerracotta)
                            .frame(width: 20, height: 20)
                            .transition(.scale.combined(with: .opacity))

                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .contentShape(Circle())
                .animation(MotionTokens.checkboxSpring, value: todo.isCompleted)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(todo.isCompleted ? "Mark as not completed" : "Mark as completed")
            .help(todo.isCompleted ? "Mark as not completed" : "Mark as completed")

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: SpacingTokens.xxs) {
                    Text(todo.title)
                        .strikethrough(todo.isCompleted)
                        .font(TypographyTokens.bodyLarge)
                        .fontWeight(todo.isCompleted ? .regular : .medium)
                        .foregroundStyle(todo.isCompleted ? tokens.textTertiary : (isSelected ? tokens.textPrimary : .primary))
                        .opacity(todo.isCompleted ? 0.5 : 1)
                    if let dueDate = todo.dueDate {
                        Label {
                            Text(dueDate, style: .date)
                        } icon: {
                            Image(systemName: "calendar")
                        }
                        .font(TypographyTokens.caption)
                        .foregroundStyle(isSelected ? tokens.textPrimary.opacity(0.82) : tokens.mutedText)
                    }
                    if todo.isOverdue {
                        DebtBadge(timeString: store.formatDebt(todo.debtSeconds ?? 0))
                    }
                }

                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onSelect()
            }

            HStack(spacing: 8) {
                Button(action: onToggleImportant) {
                    Image(systemName: todo.isImportant ? "star.fill" : "star")
                }
                .buttonStyle(AppIconButtonStyle())
                .foregroundStyle(todo.isImportant ? tokens.accentAmber : tokens.mutedText)
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
        .contextMenu {
            if todo.isArchived {
                Button("Unarchive", action: onToggleArchive)
            } else if todo.isCompleted {
                Button("Archive", action: onToggleArchive)
            }

            Button(todo.isImportant ? "Mark as not important" : "Mark as important", action: onToggleImportant)
            Divider()
            Button("Delete task", role: .destructive, action: onDelete)
        }
        .onHover { hovering in
            isHovered = hovering
        }
        .animation(MotionTokens.interactiveSpring, value: todo.isCompleted)
        .animation(MotionTokens.focusEase, value: isSelected)
    }
}
