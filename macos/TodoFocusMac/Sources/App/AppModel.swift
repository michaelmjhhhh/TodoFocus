import Foundation
import Observation

@Observable
final class AppModel {
    var selection: SidebarSelection = .myDay
    var timeFilter: TimeFilter = .allDates
    var selectedTodoIDs: Set<String> = []
    var detailPanelWidth: Double = WindowPersistence.loadDetailWidth()

    func selectSidebar(_ next: SidebarSelection) {
        if selection != next {
            selection = next
            selectedTodoIDs = []
        }
    }

    func selectTodo(todoId: String, exclusive: Bool = true) {
        if exclusive {
            selectedTodoIDs = [todoId]
        } else {
            if selectedTodoIDs.contains(todoId) {
                selectedTodoIDs.remove(todoId)
            } else {
                selectedTodoIDs.insert(todoId)
            }
        }
    }

    func clearSelection() {
        selectedTodoIDs = []
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
