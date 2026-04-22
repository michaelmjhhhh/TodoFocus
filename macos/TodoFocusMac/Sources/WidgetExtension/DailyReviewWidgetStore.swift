import Foundation
import GRDB
import WidgetKit

struct DailyReviewWidgetStore {
    func snapshot(for family: WidgetFamily, now: Date = Date()) -> DailyReviewWidgetSnapshot {
        do {
            let config = Configuration()
            let dbQueue = try DatabaseQueue(path: AppGroupDatabasePath.defaultDatabasePath(), configuration: config)
            let records = try dbQueue.read { db in
                try TodoRecord
                    .order(
                        Column("isCompleted").asc,
                        Column("sortOrder").asc,
                        Column("createdAt").desc
                    )
                    .fetchAll(db)
            }

            let todos = records.map(\.todo).filter { !$0.isArchived }
            return buildSnapshot(from: todos, family: family, now: now)
        } catch {
            return .placeholder()
        }
    }

    func placeholderSnapshot(for family: WidgetFamily) -> DailyReviewWidgetSnapshot {
        let base = DailyReviewWidgetSnapshot.placeholder()
        return DailyReviewWidgetSnapshot(
            title: base.title,
            subtitle: base.subtitle,
            metrics: base.metrics,
            items: Array(base.items.prefix(maxItems(for: family))),
            emptyMessage: base.emptyMessage
        )
    }

    private func buildSnapshot(from todos: [Todo], family: WidgetFamily, now: Date) -> DailyReviewWidgetSnapshot {
        let board = DailyReview.buildBoard(todos, now: now)
        let openColumns = board.openColumns
        let openItems = openColumns.flatMap(\.todos)

        guard !openItems.isEmpty else {
            return .empty()
        }

        let previewItems = openColumns.flatMap { column in
            column.todos.map {
                DailyReviewWidgetSnapshot.Item(
                    id: $0.id,
                    title: $0.title,
                    dueLabel: DailyReview.dueText(for: $0.dueDate, now: now),
                    bucket: column.bucket,
                    isMyDay: $0.isMyDay
                )
            }
        }

        let overdueCount = openColumns.first(where: { $0.bucket == .overdue })?.todos.count ?? 0
        let todayCount = openColumns.first(where: { $0.bucket == .today })?.todos.count ?? 0

        return DailyReviewWidgetSnapshot(
            title: "Daily Review",
            subtitle: "Preview",
            metrics: [
                .init(label: "Overdue", value: overdueCount),
                .init(label: "Today", value: todayCount),
                .init(label: "Open", value: openItems.count)
            ],
            items: Array(previewItems.prefix(maxItems(for: family))),
            emptyMessage: nil
        )
    }

    private func maxItems(for family: WidgetFamily) -> Int {
        switch family {
        case .systemSmall:
            return 2
        case .systemMedium:
            return 4
        default:
            return 2
        }
    }
}

private extension TodoRecord {
    var todo: Todo {
        Todo(
            id: id,
            title: title,
            isCompleted: isCompleted,
            isArchived: isArchived,
            isImportant: isImportant,
            isMyDay: isMyDay,
            dueDate: dueDate,
            notes: notes,
            listId: listId,
            launchResourcesRaw: launchResources,
            focusTimeSeconds: focusTimeSeconds
        )
    }
}
