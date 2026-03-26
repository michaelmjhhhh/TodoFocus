import Foundation

enum SmartList: Equatable {
    case myDay
    case important
    case planned
    case all
    case custom(listId: String)
}

func filterTodos(_ todos: [CoreTodo], for smartList: SmartList) -> [CoreTodo] {
    switch smartList {
    case .myDay:
        return todos.filter { $0.isMyDay }
    case .important:
        return todos.filter { $0.isImportant }
    case .planned:
        return todos.filter { $0.dueDate != nil }
    case .all:
        return todos
    case let .custom(listId):
        return todos.filter { $0.listId == listId }
    }
}

func applyFilters(
    todos: [CoreTodo],
    smartList: SmartList,
    timeFilter: TimeFilter,
    now: Date = Date(),
    calendar: Calendar = .current
) -> [CoreTodo] {
    let smartListFiltered = filterTodos(todos, for: smartList)
    return smartListFiltered.filter {
        matchesTimeFilter(timeFilter, dueDate: $0.dueDate, isCompleted: $0.isCompleted, now: now, calendar: calendar)
    }
}
