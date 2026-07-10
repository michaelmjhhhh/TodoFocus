import XCTest
@testable import TodoFocusMac

final class KanbanOrderingTests: XCTestCase {
    func testMoveWithinColumnProducesDenseOrder() {
        let result = KanbanOrdering.move(cardID: "c", from: ["a", "b", "c"], to: ["a", "b", "c"], destinationIndex: 0)
        XCTAssertEqual(result.source, ["c", "a", "b"])
        XCTAssertEqual(result.destination, ["c", "a", "b"])
    }

    func testMoveAcrossColumnsProducesDenseOrder() {
        let result = KanbanOrdering.move(cardID: "b", from: ["a", "b", "c"], to: ["x", "y"], destinationIndex: 1)
        XCTAssertEqual(result.source, ["a", "c"])
        XCTAssertEqual(result.destination, ["x", "b", "y"])
    }
}
