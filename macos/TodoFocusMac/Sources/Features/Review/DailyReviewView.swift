import SwiftUI
import Observation

@Observable
@MainActor
final class DailyReviewBoardViewModel {
    var board: DailyReviewView.ReviewBoard = .empty
    var isCompletedCollapsed: Bool = true

    func recompute(todos: [Todo], now: Date = Date(), calendar: Calendar = .current) {
        board = DailyReviewView.buildBoard(todos, now: now, calendar: calendar)
    }

    func toggleCompletedLane() {
        isCompletedCollapsed.toggle()
    }
}

struct DailyReviewView: View {
    @Bindable var appModel: AppModel
    @Bindable var store: TodoAppStore
    @Environment(\.themeTokens) private var tokens

    @State private var boardViewModel = DailyReviewBoardViewModel()
    @State private var touchedTaskIDs: Set<String> = []
    @State private var completedCount: Int = 0
    @State private var rescheduledCount: Int = 0
    @State private var addedToMyDayCount: Int = 0
    @State private var lastActionText: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            summaryPanel

            if store.todos.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 14) {
                        laneSection(
                            title: "Open",
                            systemImage: "tray",
                            columns: boardViewModel.board.openColumns,
                            collapsed: false,
                            isCompletedLane: false
                        )

                        laneSection(
                            title: "Completed",
                            systemImage: "checkmark.circle",
                            columns: boardViewModel.board.completedColumns,
                            collapsed: boardViewModel.isCompletedCollapsed,
                            isCompletedLane: true
                        )
                    }
                    .padding(.bottom, 12)
                }
                .scrollIndicators(.visible)
            }
        }
        .padding(16)
        .onAppear {
            boardViewModel.recompute(todos: store.todos)
        }
        .onChange(of: store.todos) { _, newTodos in
            boardViewModel.recompute(todos: newTodos)
        }
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
                Text("Kanban review by status and time horizon.")
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

    private func laneSection(
        title: String,
        systemImage: String,
        columns: [ReviewColumn],
        collapsed: Bool,
        isCompletedLane: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                if isCompletedLane {
                    boardViewModel.toggleCompletedLane()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: systemImage)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(isCompletedLane ? tokens.textSecondary : tokens.accentTerracotta)
                    Text(title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(tokens.textPrimary)
                    Text("\(columns.reduce(0) { $0 + $1.todos.count })")
                        .font(.caption.weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(tokens.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(tokens.bgFloating.opacity(0.8), in: Capsule())
                    Spacer(minLength: 8)
                    if isCompletedLane {
                        Image(systemName: collapsed ? "chevron.down" : "chevron.up")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(tokens.textSecondary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(tokens.sectionBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(tokens.sectionBorder, lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
            .disabled(!isCompletedLane)

            if !collapsed {
                ScrollView(.horizontal) {
                    LazyHStack(alignment: .top, spacing: 10) {
                        ForEach(columns) { column in
                            reviewColumnView(column, isCompletedLane: isCompletedLane)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .scrollIndicators(.visible)
            }
        }
    }

    private func reviewColumnView(_ column: ReviewColumn, isCompletedLane: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text(column.bucket.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(tokens.textPrimary)
                Text("\(column.todos.count)")
                    .font(.caption.weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(tokens.textSecondary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(tokens.bgFloating.opacity(0.8), in: Capsule())
            }

            if column.todos.isEmpty {
                Text("No tasks")
                    .font(.caption)
                    .foregroundStyle(tokens.textTertiary)
                    .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 10)
                    .background(tokens.bgFloating.opacity(0.35), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(column.todos) { todo in
                        reviewCard(todo, isCompletedLane: isCompletedLane)
                    }
                }
            }
        }
        .padding(10)
        .frame(width: 300, alignment: .topLeading)
        .background(tokens.sectionBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(tokens.sectionBorder, lineWidth: 1)
        }
    }

    private func reviewCard(_ todo: Todo, isCompletedLane: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(todo.title)
                    .font(.subheadline.weight(todo.isCompleted ? .medium : .semibold))
                    .foregroundStyle(todo.isCompleted ? tokens.textSecondary : tokens.textPrimary)
                    .strikethrough(todo.isCompleted)
                    .lineLimit(2)
                Spacer(minLength: 8)
            }

            HStack(spacing: 8) {
                metaChip(label: todo.listId.flatMap(listName(for:)) ?? "Inbox")
                metaChip(label: dueText(for: todo.dueDate))
                if todo.isMyDay {
                    metaChip(label: "My Day", accent: true)
                }
                Spacer(minLength: 8)
            }

            if !isCompletedLane {
                cardActionsRow(todo)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(tokens.bgFloating.opacity(isCompletedLane ? 0.42 : 0.58), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(isCompletedLane ? tokens.textTertiary.opacity(0.5) : tokens.accentTerracotta.opacity(0.92))
                .frame(width: 3)
                .padding(.vertical, 7)
                .padding(.leading, 5)
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

    private func cardActionsRow(_ todo: Todo) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 6) {
                doneActionButton(todo, compact: false)
                myDayActionButton(todo, compact: false)
                rescheduleMenu(todo, compact: false)
            }

            HStack(spacing: 6) {
                doneActionButton(todo, compact: true)
                myDayActionButton(todo, compact: true)
                rescheduleMenu(todo, compact: true)
            }
        }
    }

    private func doneActionButton(_ todo: Todo, compact: Bool) -> some View {
        quickActionButton(compact ? "Done" : "Done", systemImage: "checkmark", emphasize: true, compact: compact) {
            runAction(on: todo.id) {
                try store.markComplete(todoId: todo.id)
                completedCount += 1
                lastActionText = "Marked done: \(todo.title)"
            }
        }
    }

    private func myDayActionButton(_ todo: Todo, compact: Bool) -> some View {
        quickActionButton(compact ? "My Day" : "My Day", systemImage: "sun.max", emphasize: false, compact: compact) {
            runAction(on: todo.id) {
                if !todo.isMyDay {
                    try store.setMyDay(todoId: todo.id, isMyDay: true)
                    addedToMyDayCount += 1
                    lastActionText = "Added to My Day: \(todo.title)"
                }
            }
        }
    }

    private func rescheduleMenu(_ todo: Todo, compact: Bool) -> some View {
        Menu {
            Button("Today") { reschedule(todo: todo, to: .today) }
            Button("Tomorrow") { reschedule(todo: todo, to: .tomorrow) }
            Button("Next 7 Days") { reschedule(todo: todo, to: .next7) }
            Button("No Date") { reschedule(todo: todo, to: .none) }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: compact ? "calendar" : "calendar.badge.clock")
                Text(compact ? "Date" : "Reschedule")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(tokens.textSecondary)
            .padding(.horizontal, compact ? 9 : 10)
            .padding(.vertical, compact ? 5 : 6)
            .background(tokens.bgFloating.opacity(0.8), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(tokens.sectionBorder.opacity(0.9), lineWidth: 1)
            }
        }
        .menuStyle(.borderlessButton)
    }

    private func quickActionButton(_ title: String, systemImage: String, emphasize: Bool, compact: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: compact ? 4 : 6) {
                Image(systemName: systemImage)
                Text(title)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(emphasize ? Color.white : tokens.textSecondary)
            .padding(.horizontal, compact ? 9 : 11)
            .padding(.vertical, compact ? 5 : 7)
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
    enum ReviewTimeBucket: String, CaseIterable, Identifiable {
        case overdue
        case today
        case tomorrow
        case later
        case noDate

        var id: String { rawValue }

        var title: String {
            switch self {
            case .overdue: return "Overdue"
            case .today: return "Today"
            case .tomorrow: return "Tomorrow"
            case .later: return "Later"
            case .noDate: return "No Date"
            }
        }
    }

    struct ReviewColumn: Identifiable {
        let bucket: ReviewTimeBucket
        let todos: [Todo]

        var id: String { bucket.rawValue }
    }

    struct ReviewBoard {
        let openColumns: [ReviewColumn]
        let completedColumns: [ReviewColumn]

        static let empty = ReviewBoard(
            openColumns: ReviewTimeBucket.allCases.map { ReviewColumn(bucket: $0, todos: []) },
            completedColumns: ReviewTimeBucket.allCases.map { ReviewColumn(bucket: $0, todos: []) }
        )
    }

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

    static func dueBucket(for dueDate: Date?, now: Date = Date(), calendar: Calendar = .current) -> ReviewTimeBucket {
        guard let dueDate else { return .noDate }
        if calendar.isDate(dueDate, inSameDayAs: now) { return .today }
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))
        if let tomorrow, calendar.isDate(dueDate, inSameDayAs: tomorrow) { return .tomorrow }
        if dueDate < now { return .overdue }
        return .later
    }

    static func buildBoard(_ todos: [Todo], now: Date = Date(), calendar: Calendar = .current) -> ReviewBoard {
        var openMap: [ReviewTimeBucket: [Todo]] = [:]
        var completedMap: [ReviewTimeBucket: [Todo]] = [:]
        ReviewTimeBucket.allCases.forEach {
            openMap[$0] = []
            completedMap[$0] = []
        }

        for todo in todos {
            let bucket = dueBucket(for: todo.dueDate, now: now, calendar: calendar)
            if todo.isCompleted {
                completedMap[bucket, default: []].append(todo)
            } else {
                openMap[bucket, default: []].append(todo)
            }
        }

        let openColumns = ReviewTimeBucket.allCases.map { bucket in
            ReviewColumn(bucket: bucket, todos: sortColumnTodos(openMap[bucket] ?? []))
        }
        let completedColumns = ReviewTimeBucket.allCases.map { bucket in
            ReviewColumn(bucket: bucket, todos: sortColumnTodos(completedMap[bucket] ?? []))
        }

        return ReviewBoard(openColumns: openColumns, completedColumns: completedColumns)
    }

    static func sortColumnTodos(_ todos: [Todo]) -> [Todo] {
        todos.sorted { lhs, rhs in
            switch (lhs.dueDate, rhs.dueDate) {
            case let (l?, r?):
                if l != r { return l < r }
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            case (.some, .none):
                return true
            case (.none, .some):
                return false
            case (.none, .none):
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            }
        }
    }
}
