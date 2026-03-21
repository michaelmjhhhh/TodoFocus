import XCTest
import GRDB
@testable import TodoFocusMac

final class MigrationTests: XCTestCase {
    func testBootstrapCreatesRequiredTablesAndColumns() throws {
        let path = NSTemporaryDirectory() + UUID().uuidString + ".sqlite"
        let manager = try DatabaseManager(databasePath: path)

        try manager.dbQueue.read { db in
            XCTAssertTrue(try db.tableExists("list"))
            XCTAssertTrue(try db.tableExists("todo"))
            XCTAssertTrue(try db.tableExists("step"))

            let todoColumns = try db.columns(in: "todo").map(\ .name)
            XCTAssertTrue(todoColumns.contains("launchResources"))
            XCTAssertTrue(todoColumns.contains("dueDate"))
            XCTAssertTrue(todoColumns.contains("recurrence"))
        }
    }
}
