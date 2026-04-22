import Foundation
import Observation

@Observable
@MainActor
final class AppModel {
    var selection: SidebarSelection = .myDay
    var timeFilter: TimeFilter = .allDates
    var selectedTodoID: String?
    var detailPanelWidth: Double = WindowPersistence.loadDetailWidth()
    var deepFocusService: DeepFocusService = DeepFocusService()
    var quickCaptureService: QuickCaptureService = QuickCaptureService()
    var dailyReviewPreviewService: DailyReviewPreviewService = DailyReviewPreviewService()

    func selectSidebar(_ next: SidebarSelection) {
        if selection != next {
            selection = next
            selectedTodoID = nil
            if next == .overdue {
                timeFilter = .overdue
            } else {
                timeFilter = .allDates
            }
        }
    }

    func query() -> TodoQuery {
        TodoQuery(smartList: selection.smartList, timeFilter: timeFilter)
    }

    var activeViewID: String {
        switch selection {
        case .dailyReview:
            return "daily-review"
        case .myDay:
            return "myday"
        case .important:
            return "important"
        case .planned:
            return "planned"
        case .overdue:
            return "overdue"
        case .all:
            return "all"
        case .archive:
            return "archive"
        case let .customList(id):
            return id
        }
    }

    func updateDetailPanelWidth(_ value: Double, windowWidth: Double, persist: Bool = true) {
        let clamped = WindowPersistence.clampDetailWidth(value, windowWidth: windowWidth)
        detailPanelWidth = clamped
        if persist {
            WindowPersistence.saveDetailWidth(clamped)
        }
    }
}
