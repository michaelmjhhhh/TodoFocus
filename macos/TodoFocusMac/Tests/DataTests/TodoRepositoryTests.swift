import XCTest
@testable import TodoFocusMac

final class TodoRepositoryTests: XCTestCase {
    private func makeRepository() throws -> TodoRepository {
        let path = NSTemporaryDirectory() + UUID().uuidString + ".sqlite"
        let manager = try DatabaseManager(databasePath: path)
        return TodoRepository(dbQueue: manager.dbQueue)
    }

    func testAddTodoWhenPlannedTrueSetsDueDateNonNil() throws {
        let repo = try makeRepository()
        let todo = try repo.addTodo(
            AddTodoInput(title: "Ship", listID: nil, isMyDay: false, isImportant: false, planned: true),
            now: Date(timeIntervalSince1970: 1_000)
        )
        XCTAssertNotNil(todo.dueDate)
    }

    func testUpdateTodoPartialOnlyMutatesProvidedField() throws {
        let repo = try makeRepository()
        let created = try repo.addTodo(
            AddTodoInput(title: "Original", listID: nil, isMyDay: true, isImportant: true, planned: true),
            now: Date(timeIntervalSince1970: 1_000)
        )

        var patch = UpdateTodoInput()
        patch.title = "Renamed"
        try repo.updateTodo(id: created.id, input: patch, now: Date(timeIntervalSince1970: 2_000))

        let updated = try XCTUnwrap(repo.fetchTodo(id: created.id))
        XCTAssertEqual(updated.title, "Renamed")
        XCTAssertEqual(updated.isMyDay, true)
        XCTAssertEqual(updated.isImportant, true)
        XCTAssertNotNil(updated.dueDate)
    }

    func testUpdateTodoRecurrenceNilResetsIntervalAndLastCompletedAt() throws {
        let repo = try makeRepository()
        let created = try repo.addTodo(
            AddTodoInput(title: "Recurring", listID: nil, isMyDay: false, isImportant: false, planned: false),
            now: Date(timeIntervalSince1970: 1_000)
        )

        var firstPatch = UpdateTodoInput()
        firstPatch.recurrence = "daily"
        firstPatch.recurrenceInterval = 3
        firstPatch.lastCompletedAt = Date(timeIntervalSince1970: 1_500)
        try repo.updateTodo(id: created.id, input: firstPatch)

        var resetPatch = UpdateTodoInput()
        resetPatch.recurrence = .some(nil)
        try repo.updateTodo(id: created.id, input: resetPatch)

        let updated = try XCTUnwrap(repo.fetchTodo(id: created.id))
        XCTAssertNil(updated.recurrence)
        XCTAssertEqual(updated.recurrenceInterval, 1)
        XCTAssertNil(updated.lastCompletedAt)
    }

    func testFetchTodosOrderedByCompletedSortOrderThenCreatedAtDesc() throws {
        let repo = try makeRepository()

        let old = try repo.addTodo(
            AddTodoInput(title: "A", listID: nil, isMyDay: false, isImportant: false, planned: false),
            now: Date(timeIntervalSince1970: 1_000)
        )
        let newer = try repo.addTodo(
            AddTodoInput(title: "B", listID: nil, isMyDay: false, isImportant: false, planned: false),
            now: Date(timeIntervalSince1970: 2_000)
        )

        var completePatch = UpdateTodoInput()
        completePatch.isCompleted = true
        try repo.updateTodo(id: old.id, input: completePatch)

        let ordered = try repo.fetchTodosOrdered()
        XCTAssertEqual(ordered.first?.id, newer.id)
        XCTAssertEqual(ordered.last?.id, old.id)
    }

    func testLaunchResourcesNilPersistsEmptyArrayString() throws {
        let repo = try makeRepository()
        let created = try repo.addTodo(
            AddTodoInput(title: "Launch", listID: nil, isMyDay: false, isImportant: false, planned: false)
        )

        var firstPatch = UpdateTodoInput()
        firstPatch.launchResources = "[{\"id\":\"x\",\"type\":\"url\",\"label\":\"site\",\"value\":\"https://example.com\",\"createdAt\":\"1970-01-01T00:00:00.000Z\"}]"
        try repo.updateTodo(id: created.id, input: firstPatch)

        var patch = UpdateTodoInput()
        patch.launchResources = .some(nil)
        try repo.updateTodo(id: created.id, input: patch)

        let updated = try XCTUnwrap(repo.fetchTodo(id: created.id))
        XCTAssertEqual(updated.launchResources, "[]")
    }
}
