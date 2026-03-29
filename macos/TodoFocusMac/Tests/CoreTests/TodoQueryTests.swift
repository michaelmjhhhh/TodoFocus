import Foundation
import XCTest
@testable import TodoFocusMac

final class TodoQueryTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_763_520_000)

    private var utcCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return calendar
    }

    func testQueryAppliesSmartListAndTimeFilterIntersection() {
        let todos = [
            makeTodo(id: "a", isImportant: true, dueDate: now),
            makeTodo(id: "b", isImportant: true, dueDate: now.addingTimeInterval(2 * 86_400)),
            makeTodo(id: "c", isImportant: false, dueDate: now)
        ]

        let query = TodoQuery(smartList: .important, timeFilter: .today)
        let result = query.apply(todos, now: now, calendar: utcCalendar)

        XCTAssertEqual(result.map(\.id), ["a"])
    }

    func testQueryPlannedWithNoDateReturnsEmpty() {
        let todos = [
            makeTodo(id: "dated", dueDate: now),
            makeTodo(id: "nodate", dueDate: nil)
        ]

        let query = TodoQuery(smartList: .planned, timeFilter: .noDate)
        let result = query.apply(todos, now: now, calendar: utcCalendar)

        XCTAssertTrue(result.isEmpty)
    }

    private func makeTodo(
        id: String,
        isMyDay: Bool = false,
        isImportant: Bool = false,
        isCompleted: Bool = false,
        dueDate: Date? = nil,
        listId: String? = nil
    ) -> CoreTodo {
        CoreTodo(
            id: id,
            isMyDay: isMyDay,
            isImportant: isImportant,
            isCompleted: isCompleted,
            dueDate: dueDate,
            listId: listId
        )
    }
}
