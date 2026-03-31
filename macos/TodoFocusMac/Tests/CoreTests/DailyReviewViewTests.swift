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

    func testBuildBoardGroupsByLaneAndTimeBucket() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = Date(timeIntervalSince1970: 1_765_000_000)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        let nextWeek = calendar.date(byAdding: .day, value: 7, to: now)!

        let todos: [Todo] = [
            Todo(id: "open-overdue", title: "Open Overdue", isCompleted: false, isImportant: false, isMyDay: false, dueDate: yesterday, notes: "", listId: nil, launchResourcesRaw: ""),
            Todo(id: "open-today", title: "Open Today", isCompleted: false, isImportant: false, isMyDay: false, dueDate: now, notes: "", listId: nil, launchResourcesRaw: ""),
            Todo(id: "open-tomorrow", title: "Open Tomorrow", isCompleted: false, isImportant: false, isMyDay: false, dueDate: tomorrow, notes: "", listId: nil, launchResourcesRaw: ""),
            Todo(id: "open-later", title: "Open Later", isCompleted: false, isImportant: false, isMyDay: false, dueDate: nextWeek, notes: "", listId: nil, launchResourcesRaw: ""),
            Todo(id: "open-no-date", title: "Open No Date", isCompleted: false, isImportant: false, isMyDay: false, dueDate: nil, notes: "", listId: nil, launchResourcesRaw: ""),
            Todo(id: "completed-overdue", title: "Completed Overdue", isCompleted: true, isImportant: false, isMyDay: false, dueDate: yesterday, notes: "", listId: nil, launchResourcesRaw: ""),
            Todo(id: "completed-later", title: "Completed Later", isCompleted: true, isImportant: false, isMyDay: false, dueDate: nextWeek, notes: "", listId: nil, launchResourcesRaw: ""),
            Todo(id: "completed-no-date", title: "Completed No Date", isCompleted: true, isImportant: false, isMyDay: false, dueDate: nil, notes: "", listId: nil, launchResourcesRaw: "")
        ]

        let board = DailyReviewView.buildBoard(todos, now: now, calendar: calendar)

        XCTAssertEqual(board.openColumns.first(where: { $0.bucket == .overdue })?.todos.map(\.id), ["open-overdue"])
        XCTAssertEqual(board.openColumns.first(where: { $0.bucket == .today })?.todos.map(\.id), ["open-today"])
        XCTAssertEqual(board.openColumns.first(where: { $0.bucket == .tomorrow })?.todos.map(\.id), ["open-tomorrow"])
        XCTAssertEqual(board.openColumns.first(where: { $0.bucket == .later })?.todos.map(\.id), ["open-later"])
        XCTAssertEqual(board.openColumns.first(where: { $0.bucket == .noDate })?.todos.map(\.id), ["open-no-date"])

        XCTAssertEqual(board.completedColumns.first(where: { $0.bucket == .overdue })?.todos.map(\.id), ["completed-overdue"])
        XCTAssertEqual(board.completedColumns.first(where: { $0.bucket == .later })?.todos.map(\.id), ["completed-later"])
        XCTAssertEqual(board.completedColumns.first(where: { $0.bucket == .noDate })?.todos.map(\.id), ["completed-no-date"])
    }

    func testViewModelSupportsLaneAndPerColumnCollapseIndependently() {
        let viewModel = DailyReviewBoardViewModel()

        XCTAssertTrue(viewModel.isCompletedCollapsed)
        XCTAssertFalse(viewModel.isColumnCollapsed(bucket: .today, lane: .open))
        XCTAssertFalse(viewModel.isColumnCollapsed(bucket: .today, lane: .completed))

        viewModel.toggleCompletedLane()
        XCTAssertFalse(viewModel.isCompletedCollapsed)

        viewModel.toggleColumn(bucket: .today, lane: .open)
        XCTAssertTrue(viewModel.isColumnCollapsed(bucket: .today, lane: .open))
        XCTAssertFalse(viewModel.isColumnCollapsed(bucket: .today, lane: .completed))

        viewModel.toggleColumn(bucket: .today, lane: .completed)
        XCTAssertTrue(viewModel.isColumnCollapsed(bucket: .today, lane: .completed))

        viewModel.toggleColumn(bucket: .today, lane: .open)
        viewModel.toggleColumn(bucket: .today, lane: .completed)
        XCTAssertFalse(viewModel.isColumnCollapsed(bucket: .today, lane: .open))
        XCTAssertFalse(viewModel.isColumnCollapsed(bucket: .today, lane: .completed))
    }

    func testColumnCollapseScopeIsolationForOverdue() {
        let viewModel = DailyReviewBoardViewModel()

        viewModel.toggleColumn(bucket: .overdue, lane: .open)

        XCTAssertTrue(viewModel.isColumnCollapsed(bucket: .overdue, lane: .open))
        XCTAssertFalse(viewModel.isColumnCollapsed(bucket: .today, lane: .open))
        XCTAssertFalse(viewModel.isColumnCollapsed(bucket: .overdue, lane: .completed))
    }

    func testBuildBoardKeepsAllTodosInSameBucket() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = Date(timeIntervalSince1970: 1_765_000_000)

        let todos: [Todo] = [
            Todo(id: "today-a", title: "A", isCompleted: false, isImportant: false, isMyDay: false, dueDate: now, notes: "", listId: nil, launchResourcesRaw: ""),
            Todo(id: "today-b", title: "B", isCompleted: false, isImportant: false, isMyDay: false, dueDate: now.addingTimeInterval(120), notes: "", listId: nil, launchResourcesRaw: "")
        ]

        let board = DailyReviewView.buildBoard(todos, now: now, calendar: calendar)
        let todayOpen = board.openColumns.first(where: { $0.bucket == .today })?.todos.map(\.id) ?? []

        XCTAssertEqual(Set(todayOpen), Set(["today-a", "today-b"]))
        XCTAssertEqual(todayOpen.count, 2)
    }
}
