import Foundation

struct TodoQuery {
    var smartList: SmartList
    var timeFilter: TimeFilter

    func apply(_ todos: [CoreTodo], now: Date = Date(), calendar: Calendar = .current) -> [CoreTodo] {
        applyFilters(todos: todos, smartList: smartList, timeFilter: timeFilter, now: now, calendar: calendar)
    }
}
