import SwiftUI
import WidgetKit

struct DailyReviewWidget: Widget {
    let kind: String = "DailyReviewWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DailyReviewWidgetProvider()) { entry in
            DailyReviewWidgetView(entry: entry)
        }
        .configurationDisplayName("Daily Review")
        .description("Preview the tasks that need attention next.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
