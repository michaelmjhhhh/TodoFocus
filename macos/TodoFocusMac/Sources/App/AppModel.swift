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

    func selectSidebar(_ next: SidebarSelection) {
        if selection != next {
            selection = next
            selectedTodoID = nil
        }
    }

    func query() -> TodoQuery {
        TodoQuery(smartList: selection.smartList, timeFilter: timeFilter)
    }

    var activeViewID: String {
        switch selection {
        case .myDay:
            return "myday"
        case .important:
            return "important"
        case .planned:
            return "planned"
        case .all:
            return "all"
        case let .customList(id):
            return id
        }
    }

    func updateDetailPanelWidth(_ value: Double, windowWidth: Double) {
        let clamped = WindowPersistence.clampDetailWidth(value, windowWidth: windowWidth)
        detailPanelWidth = clamped
        WindowPersistence.saveDetailWidth(clamped)
    }
}
