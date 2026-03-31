import SwiftUI

struct DailyReviewView: View {
    @Bindable var appModel: AppModel
    @Bindable var store: TodoAppStore
    @Environment(\.themeTokens) private var tokens
    @State private var touchedTaskIDs: Set<String> = []
    @State private var completedCount: Int = 0
    @State private var rescheduledCount: Int = 0
    @State private var addedToMyDayCount: Int = 0
    @State private var lastActionText: String?

    private var reviewTodos: [Todo] {
        store.todos.sorted { lhs, rhs in
            if lhs.isCompleted != rhs.isCompleted {
                return !lhs.isCompleted && rhs.isCompleted
            }
            switch (lhs.dueDate, rhs.dueDate) {
            case let (l?, r?):
                return l < r
            case (.some, .none):
                return true
            case (.none, .some):
                return false
            case (.none, .none):
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            summaryPanel

            if reviewTodos.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(reviewTodos) { todo in
                            reviewRow(todo)
                        }
                    }
                    .padding(.top, 2)
                }
            }
        }
        .padding(16)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Text("Daily Review")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(tokens.textPrimary)
            Text("Manual")
                .font(.caption.weight(.semibold))
                .foregroundStyle(tokens.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(tokens.bgFloating.opacity(0.78), in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(tokens.sectionBorder.opacity(0.9), lineWidth: 1)
                }
            Spacer()
            Text("All Tasks: \(store.todoCount)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(tokens.textSecondary)
        }
    }

    private var summaryPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                summaryChip("Reviewed", value: touchedTaskIDs.count)
                summaryChip("Done", value: completedCount)
                summaryChip("Rescheduled", value: rescheduledCount)
                summaryChip("My Day", value: addedToMyDayCount)
            }

            if let lastActionText {
                Text(lastActionText)
                    .font(.caption)
                    .foregroundStyle(tokens.textSecondary)
            }
        }
        .padding(10)
        .background(tokens.sectionBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(tokens.sectionBorder, lineWidth: 1)
        }
    }

    private func summaryChip(_ label: String, value: Int) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(tokens.textSecondary)
            Text("\(value)")
                .font(.caption.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(tokens.textPrimary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(tokens.bgFloating.opacity(0.82), in: Capsule())
        .overlay {
            Capsule()
                .stroke(tokens.sectionBorder.opacity(0.9), lineWidth: 1)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(tokens.textTertiary)
            Text("No tasks to review")
                .font(.headline)
                .foregroundStyle(tokens.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func reviewRow(_ todo: Todo) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(todo.title)
                    .font(.body.weight(todo.isCompleted ? .regular : .semibold))
                    .foregroundStyle(todo.isCompleted ? tokens.textTertiary : tokens.textPrimary)
                    .strikethrough(todo.isCompleted)
                    .lineLimit(1)
                Spacer()
                if todo.isCompleted {
                    Text("Completed")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(tokens.textTertiary)
                }
            }

            HStack(spacing: 8) {
                metaChip(label: todo.listId.flatMap(listName(for:)) ?? "Inbox")
                metaChip(label: dueText(for: todo.dueDate))
                if todo.isMyDay {
                    metaChip(label: "My Day")
                }
                Spacer()
            }

            if !todo.isCompleted {
                HStack(spacing: 8) {
                    quickActionButton("Done", systemImage: "checkmark") {
                        runAction(on: todo.id) {
                            try store.markComplete(todoId: todo.id)
                            completedCount += 1
                            lastActionText = "Marked done: \(todo.title)"
                        }
                    }

                    quickActionButton("My Day", systemImage: "sun.max") {
                        runAction(on: todo.id) {
                            if !todo.isMyDay {
                                try store.setMyDay(todoId: todo.id, isMyDay: true)
                                addedToMyDayCount += 1
                                lastActionText = "Added to My Day: \(todo.title)"
                            }
                        }
                    }

                    Menu {
                        Button("Today") {
                            reschedule(todo: todo, to: .today)
                        }
                        Button("Tomorrow") {
                            reschedule(todo: todo, to: .tomorrow)
                        }
                        Button("Next 7 Days") {
                            reschedule(todo: todo, to: .next7)
                        }
                        Button("No Date") {
                            reschedule(todo: todo, to: .none)
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar.badge.clock")
                            Text("Reschedule")
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(tokens.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(tokens.bgFloating.opacity(0.8), in: Capsule())
                        .overlay {
                            Capsule()
                                .stroke(tokens.sectionBorder.opacity(0.9), lineWidth: 1)
                        }
                    }
                    .menuStyle(.borderlessButton)
                }
            }
        }
        .padding(10)
        .background(tokens.sectionBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(tokens.sectionBorder, lineWidth: 1)
        }
    }

    private func quickActionButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                Text(title)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(tokens.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(tokens.bgFloating.opacity(0.8), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(tokens.sectionBorder.opacity(0.9), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private func metaChip(label: String) -> some View {
        Text(label)
            .font(.caption2.weight(.medium))
            .foregroundStyle(tokens.textTertiary)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(tokens.bgFloating.opacity(0.6), in: Capsule())
    }

    private func dueText(for dueDate: Date?) -> String {
        guard let dueDate else { return "No Date" }
        let cal = Calendar.current
        if cal.isDateInToday(dueDate) { return "Today" }
        if cal.isDateInTomorrow(dueDate) { return "Tomorrow" }
        if dueDate < Date() { return "Overdue" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: dueDate)
    }

    private func listName(for listID: String) -> String? {
        store.lists.first(where: { $0.id == listID })?.name
    }

    private func runAction(on todoID: String, _ action: () throws -> Void) {
        do {
            try action()
            touchedTaskIDs.insert(todoID)
        } catch {
            lastActionText = "Action failed. Please retry."
        }
    }

    private enum RescheduleTarget {
        case today
        case tomorrow
        case next7
        case none
    }

    private func reschedule(todo: Todo, to target: RescheduleTarget) {
        runAction(on: todo.id) {
            let calendar = Calendar.current
            let now = Date()
            let date: Date?
            switch target {
            case .today:
                date = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: now) ?? now
            case .tomorrow:
                let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
                date = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: tomorrow) ?? tomorrow
            case .next7:
                let next = calendar.date(byAdding: .day, value: 7, to: now) ?? now
                date = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: next) ?? next
            case .none:
                date = nil
            }
            try store.setDueDate(todoId: todo.id, date: date)
            rescheduledCount += 1
            lastActionText = "Rescheduled: \(todo.title)"
        }
    }
}
