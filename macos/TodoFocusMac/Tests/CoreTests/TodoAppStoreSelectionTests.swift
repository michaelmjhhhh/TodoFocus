import Foundation
import XCTest
@testable import TodoFocusMac

final class TodoAppStoreSelectionTests: XCTestCase {
    func testSelectAndClearSelectionUpdatesSelectedTodo() throws {
        let now = Date(timeIntervalSince1970: 1_763_520_000)
        let path = NSTemporaryDirectory() + UUID().uuidString + ".sqlite"
        let manager = try DatabaseManager(databasePath: path)
        let appModel = AppModel()
        let listRepository = ListRepository(dbQueue: manager.dbQueue)
        let todoRepository = TodoRepository(dbQueue: manager.dbQueue)
        let stepRepository = StepRepository(dbQueue: manager.dbQueue)

        let store = TodoAppStore(
            appModel: appModel,
            listRepository: listRepository,
            todoRepository: todoRepository,
            stepRepository: stepRepository,
            now: { now }
        )

        let created = try store.quickAdd(
            title: "Pick me",
            planned: false,
            isImportant: false,
            isMyDay: false,
            list: nil
        )

        store.selectTodo(todoId: created.id)
        XCTAssertEqual(store.selectedTodo?.id, created.id)

        store.clearSelection()
        XCTAssertNil(store.selectedTodo)
    }
}
