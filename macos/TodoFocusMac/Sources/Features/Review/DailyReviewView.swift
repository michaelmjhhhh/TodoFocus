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
        Self.sortedForReview(store.todos)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            summaryPanel

            if reviewTodos.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(reviewTodos) { todo in
                            reviewRow(todo)
                        }
                    }
                    .padding(.bottom, 10)
                }
                .scrollIndicators(.visible)
            }
        }
        .padding(16)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("Daily Review")
                        .font(.system(size: 23, weight: .bold, design: .rounded))
                        .foregroundStyle(tokens.textPrimary)
                    Text("Manual")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(tokens.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(tokens.bgFloating.opacity(0.82), in: Capsule())
                        .overlay {
                            Capsule()
                                .stroke(tokens.sectionBorder.opacity(0.9), lineWidth: 1)
                        }
                }
                Text("Review, clean up, and plan your next sprint of tasks.")
                    .font(.caption)
                    .foregroundStyle(tokens.textTertiary)
            }
            Spacer(minLength: 8)
            metricPill(title: "All Tasks", value: store.todoCount)
        }
    }

    private var summaryPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                summaryChip("Reviewed", value: touchedTaskIDs.count, systemImage: "eye")
                summaryChip("Done", value: completedCount, systemImage: "checkmark")
                summaryChip("Rescheduled", value: rescheduledCount, systemImage: "calendar.badge.clock")
                summaryChip("My Day", value: addedToMyDayCount, systemImage: "sun.max")
            }

            if let lastActionText {
                HStack(spacing: 6) {
                    Circle()
                        .fill(tokens.accentTerracotta.opacity(0.85))
                        .frame(width: 6, height: 6)
                    Text(lastActionText)
                        .font(.caption)
                        .foregroundStyle(tokens.textSecondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(tokens.sectionBackground)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(tokens.sectionBorder, lineWidth: 1)
        }
    }

    private func summaryChip(_ label: String, value: Int, systemImage: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(tokens.textTertiary)
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(tokens.textSecondary)
            Text("\(value)")
                .font(.caption.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(tokens.textPrimary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(tokens.bgFloating.opacity(0.95), in: Capsule())
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(tokens.bgFloating.opacity(0.72), in: Capsule())
        .overlay {
            Capsule()
                .stroke(tokens.sectionBorder.opacity(0.85), lineWidth: 1)
        }
    }

    private func metricPill(title: String, value: Int) -> some View {
        HStack(spacing: 7) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(tokens.textSecondary)
            Text("\(value)")
                .font(.caption.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(tokens.textPrimary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(tokens.bgFloating.opacity(0.9), in: Capsule())
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(tokens.sectionBackground, in: Capsule())
        .overlay {
            Capsule()
                .stroke(tokens.sectionBorder, lineWidth: 1)
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
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(todo.title)
                    .font(.body.weight(todo.isCompleted ? .medium : .semibold))
                    .foregroundStyle(todo.isCompleted ? tokens.textSecondary : tokens.textPrimary)
                    .strikethrough(todo.isCompleted)
                    .lineLimit(2)

                Spacer(minLength: 8)

                Text(todo.isCompleted ? "Completed" : "Open")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(todo.isCompleted ? tokens.textTertiary : tokens.accentTerracotta)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(tokens.bgFloating.opacity(todo.isCompleted ? 0.55 : 0.9), in: Capsule())
            }

            HStack(spacing: 8) {
                metaChip(label: todo.listId.flatMap(listName(for:)) ?? "Inbox")
                metaChip(label: dueText(for: todo.dueDate))
                if todo.isMyDay {
                    metaChip(label: "My Day", accent: true)
                }
                Spacer(minLength: 8)
            }

            if !todo.isCompleted {
                HStack(spacing: 8) {
                    quickActionButton("Done", systemImage: "checkmark", emphasize: true) {
                        runAction(on: todo.id) {
                            try store.markComplete(todoId: todo.id)
                            completedCount += 1
                            lastActionText = "Marked done: \(todo.title)"
                        }
                    }

                    quickActionButton("My Day", systemImage: "sun.max", emphasize: false) {
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
                        .padding(.horizontal, 11)
                        .padding(.vertical, 7)
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
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(tokens.sectionBackground)
        )
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(todo.isCompleted ? tokens.textTertiary.opacity(0.45) : tokens.accentTerracotta.opacity(0.92))
                .frame(width: 3)
                .padding(.vertical, 9)
                .padding(.leading, 5)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(tokens.sectionBorder, lineWidth: 1)
        }
        .opacity(todo.isCompleted ? 0.72 : 1.0)
    }

    private func quickActionButton(_ title: String, systemImage: String, emphasize: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                Text(title)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(emphasize ? Color.white : tokens.textSecondary)
            .padding(.horizontal, 11)
            .padding(.vertical, 7)
            .background((emphasize ? tokens.accentTerracotta.opacity(0.95) : tokens.bgFloating.opacity(0.8)), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(tokens.sectionBorder.opacity(emphasize ? 0.0 : 0.9), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private func metaChip(label: String, accent: Bool = false) -> some View {
        Text(label)
            .font(.caption2.weight(.medium))
            .foregroundStyle(accent ? tokens.accentTerracotta : tokens.textTertiary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(tokens.bgFloating.opacity(accent ? 0.82 : 0.62), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(tokens.sectionBorder.opacity(accent ? 0.35 : 0.0), lineWidth: 1)
            }
    }

    private func dueText(for dueDate: Date?) -> String {
        Self.dueText(for: dueDate)
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

extension DailyReviewView {
    static func sortedForReview(_ todos: [Todo]) -> [Todo] {
        todos.sorted { lhs, rhs in
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

    static func dueText(for dueDate: Date?, now: Date = Date(), calendar: Calendar = .current) -> String {
        guard let dueDate else { return "No Date" }
        if calendar.isDate(dueDate, inSameDayAs: now) { return "Today" }
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))
        if let tomorrow, calendar.isDate(dueDate, inSameDayAs: tomorrow) { return "Tomorrow" }
        if dueDate < now { return "Overdue" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: dueDate)
    }
}
