import XCTest
@testable import TodoFocusMac

@MainActor
final class DailyReviewViewTests: XCTestCase {
    func testSortedForReviewPrioritizesActiveThenDueDateThenTitle() {
        let now = Date(timeIntervalSince1970: 1_765_000_000)
        let todos: [Todo] = [
            Todo(id: "completed", title: "Completed", isCompleted: true, isImportant: false, isMyDay: false, dueDate: now, notes: "", listId: nil, launchResourcesRaw: ""),
            Todo(id: "no-date-z", title: "Zulu", isCompleted: false, isImportant: false, isMyDay: false, dueDate: nil, notes: "", listId: nil, launchResourcesRaw: ""),
            Todo(id: "tomorrow", title: "Tomorrow", isCompleted: false, isImportant: false, isMyDay: false, dueDate: now.addingTimeInterval(86_400), notes: "", listId: nil, launchResourcesRaw: ""),
            Todo(id: "no-date-a", title: "Alpha", isCompleted: false, isImportant: false, isMyDay: false, dueDate: nil, notes: "", listId: nil, launchResourcesRaw: ""),
            Todo(id: "today", title: "Today", isCompleted: false, isImportant: false, isMyDay: false, dueDate: now, notes: "", listId: nil, launchResourcesRaw: "")
        ]

        let sorted = DailyReviewView.sortedForReview(todos).map(\.id)
        XCTAssertEqual(sorted, ["today", "tomorrow", "no-date-a", "no-date-z", "completed"])
    }

    func testDueTextCoversNoDateTodayTomorrowOverdue() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = Date(timeIntervalSince1970: 1_765_000_000)

        let todayLabel = DailyReviewView.dueText(for: now, now: now, calendar: calendar)
        XCTAssertEqual(todayLabel, "Today")

        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        let tomorrowLabel = DailyReviewView.dueText(for: tomorrow, now: now, calendar: calendar)
        XCTAssertEqual(tomorrowLabel, "Tomorrow")

        let overdue = calendar.date(byAdding: .day, value: -1, to: now)!
        let overdueLabel = DailyReviewView.dueText(for: overdue, now: now, calendar: calendar)
        XCTAssertEqual(overdueLabel, "Overdue")

        let noDateLabel = DailyReviewView.dueText(for: nil, now: now, calendar: calendar)
        XCTAssertEqual(noDateLabel, "No Date")
    }
}
