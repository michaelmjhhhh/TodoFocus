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

        let sorted = DailyReview.sortedForReview(todos).map(\.id)
        XCTAssertEqual(sorted, ["today", "tomorrow", "no-date-a", "no-date-z", "completed"])
    }

    func testDueTextCoversNoDateTodayTomorrowOverdue() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = Date(timeIntervalSince1970: 1_765_000_000)

        let todayLabel = DailyReview.dueText(for: now, now: now, calendar: calendar)
        XCTAssertEqual(todayLabel, "Today")

        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        let tomorrowLabel = DailyReview.dueText(for: tomorrow, now: now, calendar: calendar)
        XCTAssertEqual(tomorrowLabel, "Tomorrow")

        let overdue = calendar.date(byAdding: .day, value: -1, to: now)!
        let overdueLabel = DailyReview.dueText(for: overdue, now: now, calendar: calendar)
        XCTAssertEqual(overdueLabel, "Overdue")

        let noDateLabel = DailyReview.dueText(for: nil, now: now, calendar: calendar)
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

        let board = DailyReview.buildBoard(todos, now: now, calendar: calendar)

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

        let board = DailyReview.buildBoard(todos, now: now, calendar: calendar)
        let todayOpen = board.openColumns.first(where: { $0.bucket == .today })?.todos.map(\.id) ?? []

        XCTAssertEqual(Set(todayOpen), Set(["today-a", "today-b"]))
        XCTAssertEqual(todayOpen.count, 2)
    }

    func testWidgetSnapshotCapsRowsPerBucket() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = Date(timeIntervalSince1970: 1_765_000_000)

        let todos: [Todo] = (1...8).map { i in
            Todo(id: "task-\(i)", title: "Task \(i)", isCompleted: false, isImportant: false, isMyDay: false, dueDate: now, notes: "", listId: nil, launchResourcesRaw: "")
        }

        let board = DailyReview.buildBoard(todos, now: now, calendar: calendar)
        let snapshot = DailyReviewWidgetSnapshot.shaped(from: board, maxRowsPerBucket: 3)

        let todayColumn = snapshot.openTasks.first { $0.bucket == .today }
        XCTAssertEqual(todayColumn?.tasks.count, 3)
        XCTAssertTrue(snapshot.isTruncated)
    }

    func testWidgetSnapshotPrioritizesImportantAndMyDay() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = Date(timeIntervalSince1970: 1_765_000_000)

        let todos: [Todo] = [
            Todo(id: "regular", title: "Regular Task", isCompleted: false, isImportant: false, isMyDay: false, dueDate: now, notes: "", listId: nil, launchResourcesRaw: ""),
            Todo(id: "important", title: "Important Task", isCompleted: false, isImportant: true, isMyDay: false, dueDate: now, notes: "", listId: nil, launchResourcesRaw: ""),
            Todo(id: "my-day", title: "My Day Task", isCompleted: false, isImportant: false, isMyDay: true, dueDate: now, notes: "", listId: nil, launchResourcesRaw: ""),
            Todo(id: "both", title: "Both Task", isCompleted: false, isImportant: true, isMyDay: true, dueDate: now, notes: "", listId: nil, launchResourcesRaw: "")
        ]

        let board = DailyReview.buildBoard(todos, now: now, calendar: calendar)
        let snapshot = DailyReviewWidgetSnapshot.shaped(from: board, maxRowsPerBucket: 4)

        let todayColumn = snapshot.openTasks.first { $0.bucket == .today }
        let taskIds = todayColumn?.tasks.map(\.id) ?? []

        XCTAssertEqual(taskIds.first, "both")
        XCTAssertTrue(taskIds.contains("important"))
        XCTAssertTrue(taskIds.contains("my-day"))
    }

    func testWidgetSnapshotGroupsByBucket() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = Date(timeIntervalSince1970: 1_765_000_000)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!

        let todos: [Todo] = [
            Todo(id: "overdue-1", title: "Overdue 1", isCompleted: false, isImportant: false, isMyDay: false, dueDate: yesterday, notes: "", listId: nil, launchResourcesRaw: ""),
            Todo(id: "today-1", title: "Today 1", isCompleted: false, isImportant: false, isMyDay: false, dueDate: now, notes: "", listId: nil, launchResourcesRaw: ""),
            Todo(id: "tomorrow-1", title: "Tomorrow 1", isCompleted: false, isImportant: false, isMyDay: false, dueDate: tomorrow, notes: "", listId: nil, launchResourcesRaw: "")
        ]

        let board = DailyReview.buildBoard(todos, now: now, calendar: calendar)
        let snapshot = DailyReviewWidgetSnapshot.shaped(from: board, maxRowsPerBucket: 5)

        XCTAssertEqual(snapshot.openTasks.first(where: { $0.bucket == .overdue })?.tasks.map(\.id), ["overdue-1"])
        XCTAssertEqual(snapshot.openTasks.first(where: { $0.bucket == .today })?.tasks.map(\.id), ["today-1"])
        XCTAssertEqual(snapshot.openTasks.first(where: { $0.bucket == .tomorrow })?.tasks.map(\.id), ["tomorrow-1"])
        XCTAssertEqual(snapshot.openTasks.first(where: { $0.bucket == .later })?.tasks.map(\.id), [])
        XCTAssertEqual(snapshot.openTasks.first(where: { $0.bucket == .noDate })?.tasks.map(\.id), [])
    }

    func testWidgetSnapshotExcludesCompletedTasks() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = Date(timeIntervalSince1970: 1_765_000_000)

        let todos: [Todo] = [
            Todo(id: "open-1", title: "Open Task", isCompleted: false, isImportant: false, isMyDay: false, dueDate: now, notes: "", listId: nil, launchResourcesRaw: ""),
            Todo(id: "completed-1", title: "Completed Task", isCompleted: true, isImportant: false, isMyDay: false, dueDate: now, notes: "", listId: nil, launchResourcesRaw: "")
        ]

        let board = DailyReview.buildBoard(todos, now: now, calendar: calendar)
        let snapshot = DailyReviewWidgetSnapshot.shaped(from: board, maxRowsPerBucket: 5)

        let todayOpenTasks = snapshot.openTasks.first(where: { $0.bucket == .today })?.tasks.map(\.id) ?? []
        XCTAssertEqual(todayOpenTasks, ["open-1"])

        let todayCompletedTasks = snapshot.completedTasks.first(where: { $0.bucket == .today })?.tasks.map(\.id) ?? []
        XCTAssertEqual(todayCompletedTasks, ["completed-1"])
    }
}

struct DailyReviewWidgetSnapshot {
    let openTasks: [WidgetTaskColumn]
    let completedTasks: [WidgetTaskColumn]
    let isTruncated: Bool

    struct WidgetTaskColumn {
        let bucket: DailyReviewTimeBucket
        let tasks: [WidgetTaskItem]
    }

    struct WidgetTaskItem {
        let id: String
        let title: String
    }

    static func shaped(from board: DailyReviewBoard, maxRowsPerBucket: Int) -> DailyReviewWidgetSnapshot {
        var truncated = false
        let openCols = board.openColumns.map { col -> WidgetTaskColumn in
            let prioritized = col.todos.sorted { lhs, rhs in
                if lhs.isMyDay != rhs.isMyDay { return lhs.isMyDay }
                if lhs.isImportant != rhs.isImportant { return lhs.isImportant }
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            }
            let capped = Array(prioritized.prefix(maxRowsPerBucket))
            if prioritized.count > maxRowsPerBucket { truncated = true }
            return WidgetTaskColumn(
                bucket: col.bucket,
                tasks: capped.map { WidgetTaskItem(id: $0.id, title: $0.title) }
            )
        }
        let completedCols = board.completedColumns.map { col -> WidgetTaskColumn in
            let capped = Array(col.todos.prefix(maxRowsPerBucket))
            return WidgetTaskColumn(
                bucket: col.bucket,
                tasks: capped.map { WidgetTaskItem(id: $0.id, title: $0.title) }
            )
        }
        return DailyReviewWidgetSnapshot(openTasks: openCols, completedTasks: completedCols, isTruncated: truncated)
    }
}