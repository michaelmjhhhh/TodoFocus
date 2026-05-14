import SwiftUI
import Observation

@Observable
@MainActor
final class DailyReviewBoardViewModel {
    var board: DailyReviewBoard = .empty
    var isCompletedCollapsed: Bool = true
    private var collapsedColumns: Set<DailyReviewColumnCollapseKey> = []

    func recompute(todos: [Todo], now: Date = Date(), calendar: Calendar = .current) {
        board = DailyReview.buildBoard(todos, now: now, calendar: calendar)
    }

    func toggleCompletedLane() {
        isCompletedCollapsed.toggle()
    }

    func isColumnCollapsed(bucket: DailyReviewTimeBucket, lane: DailyReviewLane) -> Bool {
        collapsedColumns.contains(.init(lane: lane, bucket: bucket))
    }

    func toggleColumn(bucket: DailyReviewTimeBucket, lane: DailyReviewLane) {
        let key = DailyReviewColumnCollapseKey(lane: lane, bucket: bucket)
        if collapsedColumns.contains(key) {
            collapsedColumns.remove(key)
        } else {
            collapsedColumns.insert(key)
        }
    }
}

struct DailyReviewView: View {
    @Bindable var appModel: AppModel
    @Bindable var store: TodoAppStore
    @Environment(\.themeTokens) private var tokens

    @State private var boardViewModel = DailyReviewBoardViewModel()
    @State private var actionErrorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            if let errorMessage = actionErrorMessage ?? store.mutationErrorMessage {
                errorBanner(errorMessage)
            }

            if store.reviewTodos.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 14) {
                        laneSection(
                            title: "Open",
                            systemImage: "tray",
                            columns: boardViewModel.board.openColumns,
                            lane: .open,
                            collapsed: false,
                            isCompletedLane: false
                        )

                        laneSection(
                            title: "Completed",
                            systemImage: "checkmark.circle",
                            columns: boardViewModel.board.completedColumns,
                            lane: .completed,
                            collapsed: boardViewModel.isCompletedCollapsed,
                            isCompletedLane: true
                        )
                    }
                    .padding(.bottom, 12)
                }
                .scrollIndicators(.visible)
            }
        }
        .padding(SpacingTokens.xl)
        .onAppear {
            boardViewModel.recompute(todos: store.reviewTodos)
        }
        .onChange(of: store.todos) { _, _ in
            boardViewModel.recompute(todos: store.reviewTodos)
        }
    }

    private var listNameByID: [String: String] {
        Dictionary(uniqueKeysWithValues: store.lists.map { ($0.id, $0.name) })
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("Daily Review")
                        .font(TypographyTokens.displayLarge)
                        .foregroundStyle(tokens.textPrimary)
                    Text("Manual")
                        .font(TypographyTokens.micro)
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
                    .font(TypographyTokens.caption)
                    .foregroundStyle(tokens.textTertiary)
            }
            Spacer(minLength: 8)
        }
    }

    private func laneSection(
        title: String,
        systemImage: String,
        columns: [DailyReviewColumn],
        lane: DailyReviewLane,
        collapsed: Bool,
        isCompletedLane: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: SpacingTokens.md) {
            Button {
                if isCompletedLane {
                    boardViewModel.toggleCompletedLane()
                }
            } label: {
                HStack(spacing: SpacingTokens.sm) {
                    Image(systemName: systemImage)
                        .font(TypographyTokens.caption)
                        .foregroundStyle(tokens.textTertiary)
                    Text(title)
                        .font(TypographyTokens.micro)
                        .textCase(.uppercase)
                        .tracking(1.5)
                        .foregroundStyle(tokens.textTertiary)

                    Rectangle()
                        .fill(tokens.sectionBorder.opacity(0.3))
                        .frame(height: 0.5)

                    if isCompletedLane {
                        Image(systemName: collapsed ? "chevron.right" : "chevron.down")
                            .font(TypographyTokens.caption)
                            .foregroundStyle(tokens.textTertiary)
                    }
                }
                .padding(.vertical, SpacingTokens.xs)
            }
            .buttonStyle(.plain)
            .disabled(!isCompletedLane)

            if !collapsed {
                ScrollView(.horizontal) {
                    HStack(alignment: .top, spacing: SpacingTokens.md) {
                        ForEach(columns) { column in
                            reviewColumnView(column, lane: lane, isCompletedLane: isCompletedLane)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .scrollIndicators(.visible)
            }
        }
    }

    private func reviewColumnView(_ column: DailyReviewColumn, lane: DailyReviewLane, isCompletedLane: Bool) -> some View {
        let isColumnCollapsed = boardViewModel.isColumnCollapsed(bucket: column.bucket, lane: lane)
        let columnAccent: Color = {
            switch column.bucket {
            case .overdue: return tokens.danger
            case .today: return tokens.accentTerracotta
            case .tomorrow: return tokens.accentBlue
            case .later, .noDate: return tokens.textTertiary
            }
        }()

        return VStack(alignment: .leading, spacing: SpacingTokens.md) {
            HStack(spacing: SpacingTokens.sm) {
                RoundedRectangle(cornerRadius: 1)
                    .fill(columnAccent)
                    .frame(width: 3, height: 14)

                Text(column.bucket.title)
                    .font(TypographyTokens.headingSmall)
                    .foregroundStyle(tokens.textPrimary)

                if !column.todos.isEmpty {
                    Text("\(column.todos.count)")
                        .font(TypographyTokens.micro)
                        .foregroundStyle(tokens.textTertiary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(tokens.bgFloating.opacity(0.5), in: Capsule())
                }

                Spacer(minLength: 6)
                Button {
                    boardViewModel.toggleColumn(bucket: column.bucket, lane: lane)
                } label: {
                    Image(systemName: isColumnCollapsed ? "chevron.right" : "chevron.down")
                        .font(TypographyTokens.caption)
                        .foregroundStyle(tokens.textTertiary)
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(column.bucket.title) \(isColumnCollapsed ? "Expand" : "Collapse")")
            }

            if !isColumnCollapsed {
                if column.todos.isEmpty {
                    VStack(spacing: SpacingTokens.sm) {
                        Text("No tasks")
                            .font(TypographyTokens.caption)
                            .foregroundStyle(tokens.textTertiary.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity, minHeight: 48, alignment: .center)
                } else {
                    LazyVStack(spacing: 6) {
                        ForEach(column.todos) { todo in
                            reviewCard(todo, isCompletedLane: isCompletedLane)
                        }
                    }
                }
            }
        }
        .padding(SpacingTokens.lg)
        .frame(width: 300, alignment: .topLeading)
        .background(tokens.bgSubtle.opacity(0.6), in: RoundedRectangle(cornerRadius: RadiusTokens.md, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: RadiusTokens.md, style: .continuous)
                .stroke(tokens.sectionBorder.opacity(0.08), lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
    }

    private func reviewCard(_ todo: Todo, isCompletedLane: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(todo.title)
                    .font(todo.isCompleted ? TypographyTokens.bodySmall : TypographyTokens.bodyLarge)
                    .foregroundStyle(todo.isCompleted ? tokens.textTertiary : tokens.textPrimary)
                    .strikethrough(todo.isCompleted)
                    .opacity(todo.isCompleted ? 0.5 : 1)
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
        .padding(.horizontal, SpacingTokens.lg)
        .padding(.vertical, SpacingTokens.md)
        .background(tokens.bgFloating.opacity(isCompletedLane ? 0.3 : 0.45), in: RoundedRectangle(cornerRadius: RadiusTokens.sm, style: .continuous))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(isCompletedLane ? tokens.textTertiary.opacity(0.35) : tokens.accentTerracotta.opacity(0.85))
                .frame(width: 3)
                .padding(.vertical, SpacingTokens.sm)
                .padding(.leading, SpacingTokens.xs)
        }
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(TypographyTokens.caption)
                .foregroundStyle(tokens.danger)
            Text(message)
                .font(TypographyTokens.caption)
                .foregroundStyle(tokens.textSecondary)
                .lineLimit(2)
            Spacer(minLength: 6)
            Button("Dismiss") {
                actionErrorMessage = nil
                store.clearMutationError()
            }
            .buttonStyle(.plain)
            .font(TypographyTokens.caption)
            .foregroundStyle(tokens.accentTerracotta)
        }
        .padding(.horizontal, SpacingTokens.md)
        .padding(.vertical, SpacingTokens.sm)
        .background(tokens.bgSubtle, in: RoundedRectangle(cornerRadius: RadiusTokens.md, style: .continuous))
        .shadowSubtle()
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 28))
                .foregroundStyle(tokens.textTertiary)
            Text("No tasks to review")
                .font(TypographyTokens.displaySmall)
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

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    doneActionButton(todo, compact: true)
                    myDayActionButton(todo, compact: true)
                    Spacer(minLength: 0)
                }
                HStack(spacing: 6) {
                    rescheduleMenu(todo, compact: true)
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private func doneActionButton(_ todo: Todo, compact: Bool) -> some View {
        quickActionButton(compact ? "Done" : "Done", systemImage: "checkmark", emphasize: true, compact: compact) {
            runAction(on: todo.id) {
                try store.markComplete(todoId: todo.id)
            }
        }
    }

    private func myDayActionButton(_ todo: Todo, compact: Bool) -> some View {
        quickActionButton(compact ? "My Day" : "My Day", systemImage: "sun.max", emphasize: false, compact: compact) {
            runAction(on: todo.id) {
                if !todo.isMyDay {
                    try store.setMyDay(todoId: todo.id, isMyDay: true)
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
            .font(TypographyTokens.caption)
            .foregroundStyle(tokens.textSecondary)
            .padding(.horizontal, compact ? 9 : 10)
            .padding(.vertical, compact ? 5 : 6)
            .background(tokens.bgSubtle, in: Capsule())
        }
        .menuStyle(.borderlessButton)
    }

    private func quickActionButton(_ title: String, systemImage: String, emphasize: Bool, compact: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: compact ? 4 : 6) {
                Image(systemName: systemImage)
                Text(title)
            }
            .font(TypographyTokens.caption)
            .foregroundStyle(emphasize ? Color.white : tokens.textSecondary)
            .padding(.horizontal, compact ? 9 : 11)
            .padding(.vertical, compact ? 5 : 7)
            .background((emphasize ? tokens.accentTerracotta.opacity(0.95) : tokens.bgSubtle), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func metaChip(label: String, accent: Bool = false) -> some View {
        Text(label)
            .font(TypographyTokens.micro)
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
        DailyReview.dueText(for: dueDate)
    }

    private func listName(for listID: String) -> String? {
        listNameByID[listID]
    }

    private func runAction(on todoID: String, _ action: () throws -> Void) {
        do {
            try action()
            actionErrorMessage = nil
            store.clearMutationError()
        } catch {
            _ = todoID
            if let localized = error as? LocalizedError, let description = localized.errorDescription, !description.isEmpty {
                actionErrorMessage = description
            } else {
                actionErrorMessage = error.localizedDescription
            }
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
        }
    }
}

extension DailyReviewView {
    typealias ReviewLane = DailyReviewLane
    typealias ReviewColumnCollapseKey = DailyReviewColumnCollapseKey
    typealias ReviewTimeBucket = DailyReviewTimeBucket
    typealias ReviewColumn = DailyReviewColumn
    typealias ReviewBoard = DailyReviewBoard

    static func sortedForReview(_ todos: [Todo]) -> [Todo] {
        DailyReview.sortedForReview(todos)
    }

    static func dueText(for dueDate: Date?, now: Date = Date(), calendar: Calendar = .current) -> String {
        DailyReview.dueText(for: dueDate, now: now, calendar: calendar)
    }

    static func dueBucket(for dueDate: Date?, now: Date = Date(), calendar: Calendar = .current) -> ReviewTimeBucket {
        DailyReview.dueBucket(for: dueDate, now: now, calendar: calendar)
    }

    static func buildBoard(_ todos: [Todo], now: Date = Date(), calendar: Calendar = .current) -> ReviewBoard {
        DailyReview.buildBoard(todos, now: now, calendar: calendar)
    }

    static func sortColumnTodos(_ todos: [Todo]) -> [Todo] {
        DailyReview.sortColumnTodos(todos)
    }
}
