import WidgetKit

struct DailyReviewWidgetProvider: TimelineProvider {
    private let store = DailyReviewWidgetStore()

    func placeholder(in context: Context) -> DailyReviewWidgetEntry {
        DailyReviewWidgetEntry(date: .now, snapshot: store.placeholderSnapshot(for: context.family))
    }

    func getSnapshot(in context: Context, completion: @escaping (DailyReviewWidgetEntry) -> Void) {
        let snapshot = context.isPreview
            ? store.placeholderSnapshot(for: context.family)
            : store.snapshot(for: context.family)
        completion(DailyReviewWidgetEntry(date: .now, snapshot: snapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DailyReviewWidgetEntry>) -> Void) {
        let entry = DailyReviewWidgetEntry(date: .now, snapshot: store.snapshot(for: context.family))
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now.addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(refreshDate)))
    }
}
