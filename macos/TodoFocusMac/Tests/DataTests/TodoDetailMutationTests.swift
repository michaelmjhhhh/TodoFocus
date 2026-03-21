import XCTest
@testable import TodoFocusMac

final class TodoDetailMutationTests: XCTestCase {
    private func makeRepository() throws -> TodoRepository {
        let path = NSTemporaryDirectory() + UUID().uuidString + ".sqlite"
        let manager = try DatabaseManager(databasePath: path)
        return TodoRepository(dbQueue: manager.dbQueue)
    }

    func testUpdateNotesPersists() throws {
        let repo = try makeRepository()
        let created = try repo.addTodo(
            AddTodoInput(title: "Notes", listID: nil, isMyDay: false, isImportant: false, planned: false)
        )

        let now = Date(timeIntervalSince1970: 2_000)
        try repo.updateNotes(id: created.id, notes: "Line one\nLine two", now: now)

        let updated = try XCTUnwrap(repo.fetchTodo(id: created.id))
        XCTAssertEqual(updated.notes, "Line one\nLine two")
        XCTAssertEqual(updated.updatedAt, now)
    }

    func testSetDueDatePersistsAndClearPersists() throws {
        let repo = try makeRepository()
        let created = try repo.addTodo(
            AddTodoInput(title: "Due", listID: nil, isMyDay: false, isImportant: false, planned: false)
        )

        let due = Date(timeIntervalSince1970: 3_000)
        try repo.setDueDate(id: created.id, dueDate: due, now: Date(timeIntervalSince1970: 3_100))

        var updated = try XCTUnwrap(repo.fetchTodo(id: created.id))
        XCTAssertEqual(updated.dueDate, due)

        try repo.setDueDate(id: created.id, dueDate: nil, now: Date(timeIntervalSince1970: 3_200))

        updated = try XCTUnwrap(repo.fetchTodo(id: created.id))
        XCTAssertNil(updated.dueDate)
    }

    func testUpdateTitlePersistsTrimmedValue() throws {
        let repo = try makeRepository()
        let created = try repo.addTodo(
            AddTodoInput(title: "Original", listID: nil, isMyDay: false, isImportant: false, planned: false)
        )

        let now = Date(timeIntervalSince1970: 4_000)
        try repo.updateTitle(id: created.id, title: "  Renamed task  ", now: now)

        let updated = try XCTUnwrap(repo.fetchTodo(id: created.id))
        XCTAssertEqual(updated.title, "Renamed task")
        XCTAssertEqual(updated.updatedAt, now)
    }

    func testDetailHelpersWithMissingIDThrowNotFound() throws {
        let repo = try makeRepository()

        XCTAssertThrowsError(try repo.updateNotes(id: "missing", notes: "n", now: Date())) { error in
            XCTAssertEqual(error as? TodoRepositoryError, .notFound)
        }

        XCTAssertThrowsError(try repo.setDueDate(id: "missing", dueDate: Date(), now: Date())) { error in
            XCTAssertEqual(error as? TodoRepositoryError, .notFound)
        }

        XCTAssertThrowsError(try repo.updateTitle(id: "missing", title: "x", now: Date())) { error in
            XCTAssertEqual(error as? TodoRepositoryError, .notFound)
        }
    }

    func testUpdateTitleWithWhitespaceOnlyThrowsInvalidTitle() throws {
        let repo = try makeRepository()
        let created = try repo.addTodo(
            AddTodoInput(title: "Original", listID: nil, isMyDay: false, isImportant: false, planned: false)
        )

        XCTAssertThrowsError(try repo.updateTitle(id: created.id, title: "  \n\t  ", now: Date())) { error in
            XCTAssertEqual(error as? TodoRepositoryError, .invalidTitle)
        }
    }
}
