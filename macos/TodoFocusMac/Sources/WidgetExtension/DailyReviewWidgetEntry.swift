import Foundation
import WidgetKit

struct DailyReviewWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: DailyReviewWidgetSnapshot
}

struct DailyReviewWidgetSnapshot {
    struct Metric: Identifiable, Equatable {
        let label: String
        let value: Int

        var id: String { label }
    }

    struct Item: Identifiable, Equatable {
        let id: String
        let title: String
        let dueLabel: String
        let bucket: DailyReviewTimeBucket
        let isMyDay: Bool
    }

    let title: String
    let subtitle: String
    let metrics: [Metric]
    let items: [Item]
    let emptyMessage: String?

    static func placeholder() -> DailyReviewWidgetSnapshot {
        DailyReviewWidgetSnapshot(
            title: "Daily Review",
            subtitle: "Preview",
            metrics: [
                Metric(label: "Overdue", value: 2),
                Metric(label: "Today", value: 3),
                Metric(label: "Open", value: 5)
            ],
            items: [
                Item(id: "sample-1", title: "Ship widget preview", dueLabel: "Overdue", bucket: .overdue, isMyDay: true),
                Item(id: "sample-2", title: "Review tomorrow plan", dueLabel: "Tomorrow", bucket: .tomorrow, isMyDay: false),
                Item(id: "sample-3", title: "Clear inbox tasks", dueLabel: "No Date", bucket: .noDate, isMyDay: false)
            ],
            emptyMessage: nil
        )
    }

    static func empty() -> DailyReviewWidgetSnapshot {
        DailyReviewWidgetSnapshot(
            title: "Daily Review",
            subtitle: "Preview",
            metrics: [
                Metric(label: "Overdue", value: 0),
                Metric(label: "Today", value: 0),
                Metric(label: "Open", value: 0)
            ],
            items: [],
            emptyMessage: "No tasks to review"
        )
    }
}
