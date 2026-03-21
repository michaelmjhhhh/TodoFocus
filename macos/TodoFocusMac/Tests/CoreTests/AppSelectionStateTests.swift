import XCTest
@testable import TodoFocusMac

final class AppSelectionStateTests: XCTestCase {
    func testSidebarSelectionChangeClearsSelectedTodo() {
        let model = AppModel()
        model.selectedTodoID = "todo-1"

        model.selectSidebar(.important)

        XCTAssertEqual(model.selection, .important)
        XCTAssertNil(model.selectedTodoID)
    }

    func testSidebarSelectionSameValueKeepsSelectedTodo() {
        let model = AppModel()
        model.selectedTodoID = "todo-1"

        model.selectSidebar(.myDay)

        XCTAssertEqual(model.selection, .myDay)
        XCTAssertEqual(model.selectedTodoID, "todo-1")
    }

    func testQueryUsesSelectionAndTimeFilter() {
        let model = AppModel()
        model.selectSidebar(.customList("list-7"))
        model.timeFilter = .today

        let query = model.query()

        XCTAssertEqual(query.smartList, .custom(listId: "list-7"))
        XCTAssertEqual(query.timeFilter, .today)
    }

    func testActiveViewIDMatchesLegacyNames() {
        let model = AppModel()

        XCTAssertEqual(model.activeViewID, "myday")

        model.selectSidebar(.important)
        XCTAssertEqual(model.activeViewID, "important")

        model.selectSidebar(.planned)
        XCTAssertEqual(model.activeViewID, "planned")

        model.selectSidebar(.all)
        XCTAssertEqual(model.activeViewID, "all")

        model.selectSidebar(.customList("list-1"))
        XCTAssertEqual(model.activeViewID, "list-1")
    }
}
