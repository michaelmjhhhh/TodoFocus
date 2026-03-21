import Foundation
import XCTest
@testable import TodoFocusMac

final class TodoAppStoreTests: XCTestCase {
    private func makeStore(now: Date = Date(timeIntervalSince1970: 1_763_520_000)) throws -> (TodoAppStore, AppModel, ListRepository, TodoRepository) {
        let path = NSTemporaryDirectory() + UUID().uuidString + ".sqlite"
        let manager = try DatabaseManager(databasePath: path)
        let listRepository = ListRepository(dbQueue: manager.dbQueue)
        let todoRepository = TodoRepository(dbQueue: manager.dbQueue)
        let appModel = AppModel()
        let store = TodoAppStore(
            appModel: appModel,
            listRepository: listRepository,
            todoRepository: todoRepository,
            now: { now }
        )
        return (store, appModel, listRepository, todoRepository)
    }

    func testVisibleTodosUsesAppModelSelectionAndTimeFilter() throws {
        let now = Date(timeIntervalSince1970: 1_763_520_000)
        let tomorrow = now.addingTimeInterval(86_400)
        let (store, appModel, _, todoRepository) = try makeStore(now: now)

        _ = try todoRepository.addTodo(
            AddTodoInput(title: "Today important", listID: nil, isMyDay: false, isImportant: true, planned: true),
            now: now
        )
        _ = try todoRepository.addTodo(
            AddTodoInput(title: "Tomorrow important", listID: nil, isMyDay: false, isImportant: true, planned: false),
            now: now
        )
        _ = try todoRepository.addTodo(
            AddTodoInput(title: "Today normal", listID: nil, isMyDay: false, isImportant: false, planned: true),
            now: now
        )

        let all = try todoRepository.fetchTodosOrdered()
        let tomorrowId = try XCTUnwrap(all.first(where: { $0.title == "Tomorrow important" })?.id)
        var patch = UpdateTodoInput()
        patch.dueDate = tomorrow
        try todoRepository.updateTodo(id: tomorrowId, input: patch, now: now)

        try store.reload()
        appModel.selection = .important
        appModel.timeFilter = .today

        XCTAssertEqual(store.visibleTodos.map(\.title), ["Today important"])
    }

    func testQuickAddMapsFlagsAndListToRepositoryRecord() throws {
        let now = Date(timeIntervalSince1970: 1_763_520_000)
        let (store, _, listRepository, todoRepository) = try makeStore(now: now)
        let listRecord = try listRepository.createList(name: "Work", now: now)
        let list = TodoList(id: listRecord.id, name: listRecord.name, color: listRecord.color, sortOrder: listRecord.sortOrder)

        let created = try store.quickAdd(
            title: "  Ship desktop build  ",
            planned: true,
            isImportant: true,
            isMyDay: true,
            list: list
        )

        let persisted = try XCTUnwrap(todoRepository.fetchTodo(id: created.id))
        XCTAssertEqual(persisted.title, "Ship desktop build")
        XCTAssertTrue(persisted.isImportant)
        XCTAssertTrue(persisted.isMyDay)
        XCTAssertEqual(persisted.listId, list.id)
        XCTAssertEqual(persisted.dueDate, now)
    }
}
