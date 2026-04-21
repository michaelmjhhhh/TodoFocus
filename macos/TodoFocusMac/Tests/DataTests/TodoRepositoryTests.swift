import XCTest
@testable import TodoFocusMac

final class TodoRepositoryTests: XCTestCase {
    private func makeDatabaseManager() throws -> DatabaseManager {
        let path = NSTemporaryDirectory() + UUID().uuidString + ".sqlite"
        return try DatabaseManager(databasePath: path)
    }

    private func makeRepository() throws -> TodoRepository {
        let manager = try makeDatabaseManager()
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

    func testAddTodoWithInvalidTitleThrowsInvalidTitle() throws {
        let repo = try makeRepository()

        XCTAssertThrowsError(
            try repo.addTodo(
                AddTodoInput(title: "   \n\t", listID: nil, isMyDay: false, isImportant: false, planned: false)
            )
        ) { error in
            XCTAssertEqual(error as? TodoRepositoryError, .invalidTitle)
        }
    }

    func testUpdateTodoRecurrenceIntervalClampsToAtLeastOne() throws {
        let repo = try makeRepository()
        let created = try repo.addTodo(
            AddTodoInput(title: "Clamp", listID: nil, isMyDay: false, isImportant: false, planned: false)
        )

        var patch = UpdateTodoInput()
        patch.recurrenceInterval = 0
        try repo.updateTodo(id: created.id, input: patch)

        let updated = try XCTUnwrap(repo.fetchTodo(id: created.id))
        XCTAssertEqual(updated.recurrenceInterval, 1)
    }

    func testUpdateTodoWithMissingIDThrowsNotFound() throws {
        let repo = try makeRepository()

        XCTAssertThrowsError(try repo.updateTodo(id: "missing", input: UpdateTodoInput())) { error in
            XCTAssertEqual(error as? TodoRepositoryError, .notFound)
        }
    }

    func testUpdateTodoWithInvalidLaunchResourcesStringThrowsInvalidLaunchResources() throws {
        let repo = try makeRepository()
        let created = try repo.addTodo(
            AddTodoInput(title: "Launch JSON", listID: nil, isMyDay: false, isImportant: false, planned: false)
        )

        var patch = UpdateTodoInput()
        patch.launchResources = "{not json}"

        XCTAssertThrowsError(try repo.updateTodo(id: created.id, input: patch)) { error in
            XCTAssertEqual(error as? TodoRepositoryError, .invalidLaunchResources)
        }
    }

    func testUpdateTodoWithOversizedLaunchResourcesThrowsTooLarge() throws {
        let repo = try makeRepository()
        let created = try repo.addTodo(
            AddTodoInput(title: "Launch size", listID: nil, isMyDay: false, isImportant: false, planned: false)
        )

        var patch = UpdateTodoInput()
        patch.launchResources = String(repeating: "x", count: 16_001)

        XCTAssertThrowsError(try repo.updateTodo(id: created.id, input: patch)) { error in
            XCTAssertEqual(error as? TodoRepositoryError, .launchResourcesTooLarge)
        }
    }

    func testUpdateTodoWithEmptyListIDConvertsToNil() throws {
        let repo = try makeRepository()
        let created = try repo.addTodo(
            AddTodoInput(title: "List", listID: nil, isMyDay: false, isImportant: false, planned: false)
        )

        var patch = UpdateTodoInput()
        patch.listID = ""
        try repo.updateTodo(id: created.id, input: patch)

        let updated = try XCTUnwrap(repo.fetchTodo(id: created.id))
        XCTAssertNil(updated.listId)
    }

    func testUpdateTodoTitleTrimsWhitespace() throws {
        let repo = try makeRepository()
        let created = try repo.addTodo(
            AddTodoInput(title: "Original", listID: nil, isMyDay: false, isImportant: false, planned: false)
        )

        var patch = UpdateTodoInput()
        patch.title = "  Renamed  "
        try repo.updateTodo(id: created.id, input: patch)

        let updated = try XCTUnwrap(repo.fetchTodo(id: created.id))
        XCTAssertEqual(updated.title, "Renamed")
    }

    func testUpdateTodoRejectsBlankTitleAfterTrim() throws {
        let repo = try makeRepository()
        let created = try repo.addTodo(
            AddTodoInput(title: "Original", listID: nil, isMyDay: false, isImportant: false, planned: false)
        )

        var patch = UpdateTodoInput()
        patch.title = "   "

        XCTAssertThrowsError(try repo.updateTodo(id: created.id, input: patch)) { error in
            XCTAssertEqual(error as? TodoRepositoryError, .invalidTitle)
        }
    }

    func testUpdateTodoClampsNegativeFocusTimeToZero() throws {
        let repo = try makeRepository()
        let created = try repo.addTodo(
            AddTodoInput(title: "Focus", listID: nil, isMyDay: false, isImportant: false, planned: false)
        )

        var patch = UpdateTodoInput()
        patch.focusTimeSeconds = -120
        try repo.updateTodo(id: created.id, input: patch)

        let updated = try XCTUnwrap(repo.fetchTodo(id: created.id))
        XCTAssertEqual(updated.focusTimeSeconds, 0)
    }

    func testDeleteTodoRemovesRecord() throws {
        let repo = try makeRepository()
        let created = try repo.addTodo(
            AddTodoInput(title: "Delete me", listID: nil, isMyDay: false, isImportant: false, planned: false)
        )

        try repo.deleteTodo(id: created.id)

        XCTAssertNil(try repo.fetchTodo(id: created.id))
    }

    func testDeleteTodoWithMissingIDThrowsNotFound() throws {
        let repo = try makeRepository()

        XCTAssertThrowsError(try repo.deleteTodo(id: "missing")) { error in
            XCTAssertEqual(error as? TodoRepositoryError, .notFound)
        }
    }

    func testClearCompletedTodosDeletesOnlyCompletedRows() throws {
        let repo = try makeRepository()
        let active = try repo.addTodo(
            AddTodoInput(title: "Keep me", listID: nil, isMyDay: false, isImportant: false, planned: false)
        )
        let completed = try repo.addTodo(
            AddTodoInput(title: "Done", listID: nil, isMyDay: false, isImportant: false, planned: false)
        )

        var patch = UpdateTodoInput()
        patch.isCompleted = true
        try repo.updateTodo(id: completed.id, input: patch)

        let deletedCount = try repo.clearCompletedTodos()

        XCTAssertEqual(deletedCount, 1)
        XCTAssertNotNil(try repo.fetchTodo(id: active.id))
        XCTAssertNil(try repo.fetchTodo(id: completed.id))
    }

    func testClearCompletedTodosPreservesArchivedCompletedRows() throws {
        let manager = try makeDatabaseManager()
        let repo = TodoRepository(dbQueue: manager.dbQueue)
        let archivedCompleted = try repo.addTodo(
            AddTodoInput(title: "Archived done", listID: nil, isMyDay: false, isImportant: false, planned: false)
        )
        let plainCompleted = try repo.addTodo(
            AddTodoInput(title: "Plain done", listID: nil, isMyDay: false, isImportant: false, planned: false)
        )

        var completedPatch = UpdateTodoInput()
        completedPatch.isCompleted = true
        try repo.updateTodo(id: archivedCompleted.id, input: completedPatch)
        try repo.updateTodo(id: plainCompleted.id, input: completedPatch)

        try manager.dbQueue.write { db in
            try db.execute(sql: "UPDATE todo SET isArchived = 1 WHERE id = ?", arguments: [archivedCompleted.id])
        }

        let deletedCount = try repo.clearCompletedTodos()

        XCTAssertEqual(deletedCount, 1)
        XCTAssertNotNil(try repo.fetchTodo(id: archivedCompleted.id))
        XCTAssertNil(try repo.fetchTodo(id: plainCompleted.id))
    }

    func testClearArchivedTodosDeletesOnlyArchivedRows() throws {
        let manager = try makeDatabaseManager()
        let repo = TodoRepository(dbQueue: manager.dbQueue)
        let archived = try repo.addTodo(
            AddTodoInput(title: "Archived", listID: nil, isMyDay: false, isImportant: false, planned: false)
        )
        let visible = try repo.addTodo(
            AddTodoInput(title: "Visible", listID: nil, isMyDay: false, isImportant: false, planned: false)
        )

        var archivePatch = UpdateTodoInput()
        archivePatch.isCompleted = true
        archivePatch.isArchived = true
        try repo.updateTodo(id: archived.id, input: archivePatch)

        let deletedCount = try repo.clearArchivedTodos()

        XCTAssertEqual(deletedCount, 1)
        XCTAssertNil(try repo.fetchTodo(id: archived.id))
        XCTAssertNotNil(try repo.fetchTodo(id: visible.id))
    }
}
