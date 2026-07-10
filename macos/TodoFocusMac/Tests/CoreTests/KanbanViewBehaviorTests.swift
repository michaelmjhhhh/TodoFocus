import XCTest
@testable import TodoFocusMac

final class KanbanViewBehaviorTests: XCTestCase {
    func testKanbanRowsNeverEnterTodoRepository() throws {
        let manager = try DatabaseManager(databasePath: ":memory:")
        let kanban = KanbanRepository(dbQueue: manager.dbQueue)
        let todos = TodoRepository(dbQueue: manager.dbQueue)
        let project = try kanban.createProject(.init(name: "App", color: "#C46849", goal: "Ship"), now: Date())
        _ = try kanban.createCard(.init(projectID: project.id, title: "Build board", status: .backlog), now: Date())
        XCTAssertTrue(try todos.fetchTodosOrdered().isEmpty)
    }

    func testCardAccessibilitySummaryIncludesWorkflowContext() {
        let cardID = "card-1"
        let card = KanbanCard(
            id: cardID,
            projectID: "project-1",
            title: "Build board",
            description: "",
            status: .backlog,
            priority: .medium,
            dueDate: nil,
            sortOrder: 0,
            isArchived: false,
            labels: [],
            checklist: [
                .init(id: "item-1", cardID: cardID, title: "First", isCompleted: true, sortOrder: 0),
                .init(id: "item-2", cardID: cardID, title: "Second", isCompleted: false, sortOrder: 1),
            ],
            createdAt: Date(),
            updatedAt: Date()
        )

        let summary = KanbanCardView.accessibilitySummary(card)
        XCTAssertTrue(summary.contains("Backlog"))
        XCTAssertTrue(summary.contains("Medium"))
        XCTAssertTrue(summary.contains("1 of 2 checklist items complete"))
    }
}
