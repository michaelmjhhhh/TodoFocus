import XCTest
@testable import TodoFocusMac

final class StepRepositoryTests: XCTestCase {
    private func makeRepositories() throws -> (TodoRepository, StepRepository) {
        let path = NSTemporaryDirectory() + UUID().uuidString + ".sqlite"
        let manager = try DatabaseManager(databasePath: path)
        return (
            TodoRepository(dbQueue: manager.dbQueue),
            StepRepository(dbQueue: manager.dbQueue)
        )
    }

    func testAddStepWithBlankTitleThrowsInvalidTitle() throws {
        let (todoRepo, stepRepo) = try makeRepositories()
        let todo = try todoRepo.addTodo(
            AddTodoInput(title: "Parent", listID: nil, isMyDay: false, isImportant: false, planned: false)
        )

        XCTAssertThrowsError(try stepRepo.addStep(todoID: todo.id, title: "  \n\t  ")) { error in
            XCTAssertEqual(error as? StepRepositoryError, .invalidTitle)
        }
    }

    func testAddStepTrimsTitleBeforePersisting() throws {
        let (todoRepo, stepRepo) = try makeRepositories()
        let todo = try todoRepo.addTodo(
            AddTodoInput(title: "Parent", listID: nil, isMyDay: false, isImportant: false, planned: false)
        )

        let created = try stepRepo.addStep(todoID: todo.id, title: "  First step  ")
        XCTAssertEqual(created.title, "First step")

        let fetched = try stepRepo.fetchSteps(todoID: todo.id)
        XCTAssertEqual(fetched.first?.title, "First step")
    }

    func testUpdateStepTitleTrimsAndPersists() throws {
        let (todoRepo, stepRepo) = try makeRepositories()
        let todo = try todoRepo.addTodo(
            AddTodoInput(title: "Parent", listID: nil, isMyDay: false, isImportant: false, planned: false)
        )
        let created = try stepRepo.addStep(todoID: todo.id, title: "Old")

        try stepRepo.updateStepTitle(id: created.id, title: "  New title  ")

        let fetched = try stepRepo.fetchSteps(todoID: todo.id)
        XCTAssertEqual(fetched.first?.title, "New title")
    }

    func testDeleteStepKeepsSortOrderGaps() throws {
        let (todoRepo, stepRepo) = try makeRepositories()
        let todo = try todoRepo.addTodo(
            AddTodoInput(title: "Parent", listID: nil, isMyDay: false, isImportant: false, planned: false)
        )

        _ = try stepRepo.addStep(todoID: todo.id, title: "One")
        let second = try stepRepo.addStep(todoID: todo.id, title: "Two")
        _ = try stepRepo.addStep(todoID: todo.id, title: "Three")

        try stepRepo.deleteStep(id: second.id)

        let remaining = try stepRepo.fetchSteps(todoID: todo.id)
        XCTAssertEqual(remaining.map(\.sortOrder), [0, 2])
        XCTAssertEqual(remaining.map(\.title), ["One", "Three"])
    }
}
