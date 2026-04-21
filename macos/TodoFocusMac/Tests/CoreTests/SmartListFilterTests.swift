import XCTest
@testable import TodoFocusMac

final class SmartListFilterTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_763_520_000) // 2025-11-19T16:00:00Z

    private var utcCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return calendar
    }

    func testMyDaySmartListFiltersByIsMyDay() {
        let todos = [
            makeTodo(id: "a", isMyDay: true),
            makeTodo(id: "b", isMyDay: false)
        ]

        XCTAssertEqual(filterTodos(todos, for: .myDay).map(\.id), ["a"])
    }

    func testImportantSmartListFiltersByIsImportant() {
        let todos = [
            makeTodo(id: "a", isImportant: true),
            makeTodo(id: "b", isImportant: false)
        ]

        XCTAssertEqual(filterTodos(todos, for: .important).map(\.id), ["a"])
    }

    func testPlannedSmartListFiltersByDueDatePresence() {
        let todos = [
            makeTodo(id: "a", dueDate: now),
            makeTodo(id: "b", dueDate: nil)
        ]

        XCTAssertEqual(filterTodos(todos, for: .planned).map(\.id), ["a"])
    }

    func testAllSmartListReturnsAllTodos() {
        let todos = [
            makeTodo(id: "a"),
            makeTodo(id: "b")
        ]

        XCTAssertEqual(filterTodos(todos, for: .all).map(\.id), ["a", "b"])
    }

    func testAllSmartListExcludesArchivedTodos() {
        let todos = [
            makeTodo(id: "visible"),
            makeTodo(id: "archived", isArchived: true)
        ]

        XCTAssertEqual(filterTodos(todos, for: .all).map(\.id), ["visible"])
    }

    func testArchiveSmartListReturnsOnlyArchivedTodos() {
        let todos = [
            makeTodo(id: "visible"),
            makeTodo(id: "archived", isArchived: true)
        ]

        XCTAssertEqual(filterTodos(todos, for: .archive).map(\.id), ["archived"])
    }

    func testCustomSmartListMatchesExactListId() {
        let todos = [
            makeTodo(id: "exact", listId: "list-1"),
            makeTodo(id: "prefix-only", listId: "list-10"),
            makeTodo(id: "none", listId: nil)
        ]

        XCTAssertEqual(filterTodos(todos, for: .custom(listId: "list-1")).map(\.id), ["exact"])
    }

    func testApplyFiltersPlannedWithNoDateIsEmpty() {
        let todos = [
            makeTodo(id: "with-date", dueDate: now),
            makeTodo(id: "without-date", dueDate: nil)
        ]

        let result = applyFilters(
            todos: todos,
            smartList: .planned,
            timeFilter: .noDate,
            now: now,
            calendar: utcCalendar
        )

        XCTAssertTrue(result.isEmpty)
    }

    func testApplyFiltersPlannedThenTodayKeepsOnlyDueToday() {
        let tomorrow = now.addingTimeInterval(86_400)
        let todos = [
            makeTodo(id: "today", dueDate: now),
            makeTodo(id: "tomorrow", dueDate: tomorrow),
            makeTodo(id: "no-date", dueDate: nil)
        ]

        let result = applyFilters(
            todos: todos,
            smartList: .planned,
            timeFilter: .today,
            now: now,
            calendar: utcCalendar
        )

        XCTAssertEqual(result.map(\.id), ["today"])
    }

    func testApplyFiltersCustomThenNoDateKeepsOnlyMatchingListWithoutDates() {
        let todos = [
            makeTodo(id: "target-no-date", dueDate: nil, listId: "l1"),
            makeTodo(id: "target-with-date", dueDate: now, listId: "l1"),
            makeTodo(id: "other-no-date", dueDate: nil, listId: "l2")
        ]

        let result = applyFilters(
            todos: todos,
            smartList: .custom(listId: "l1"),
            timeFilter: .noDate,
            now: now,
            calendar: utcCalendar
        )

        XCTAssertEqual(result.map(\.id), ["target-no-date"])
    }

    private func makeTodo(
        id: String,
        isMyDay: Bool = false,
        isImportant: Bool = false,
        isCompleted: Bool = false,
        isArchived: Bool = false,
        dueDate: Date? = nil,
        listId: String? = nil
    ) -> CoreTodo {
        CoreTodo(
            id: id,
            isMyDay: isMyDay,
            isImportant: isImportant,
            isCompleted: isCompleted,
            isArchived: isArchived,
            dueDate: dueDate,
            listId: listId
        )
    }
}
