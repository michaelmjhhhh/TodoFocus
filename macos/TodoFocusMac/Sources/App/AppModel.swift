import Foundation
import Observation

@Observable
final class AppModel {
    var selection: SidebarSelection = .myDay
    var timeFilter: TimeFilter = .allDates
    var selectedTodoID: String?
    var detailPanelWidth: Double = 360

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
}
