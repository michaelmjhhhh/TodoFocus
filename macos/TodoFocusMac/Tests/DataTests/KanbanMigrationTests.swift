import XCTest
import GRDB
@testable import TodoFocusMac

final class KanbanMigrationTests: XCTestCase {
    func testMigrationCreatesKanbanSchemaAndIndexes() throws {
        let manager = try DatabaseManager(databasePath: ":memory:")
        try manager.dbQueue.read { db in
            for table in ["kanban_project", "kanban_card", "kanban_card_label", "kanban_checklist_item"] {
                XCTAssertTrue(try db.tableExists(table))
            }
            let cardColumns = Set(try db.columns(in: "kanban_card").map(\.name))
            XCTAssertTrue(["projectId", "status", "priority", "sortOrder", "isArchived"].allSatisfy(cardColumns.contains))
            XCTAssertNotNil(try db.indexes(on: "kanban_card").first { $0.name == "idx_kanban_card_board_order" })
        }
    }

    func testDeletingProjectCascadesCardsAndChildren() throws {
        let manager = try DatabaseManager(databasePath: ":memory:")
        try manager.dbQueue.write { db in
            try db.execute(sql: "INSERT INTO kanban_project (id,name,color,goal,createdAt,updatedAt) VALUES ('p','P','#C46849','Goal',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)")
            try db.execute(sql: "INSERT INTO kanban_card (id,projectId,title,description,status,priority,sortOrder,isArchived,createdAt,updatedAt) VALUES ('c','p','C','','backlog','medium',0,0,CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)")
            try db.execute(sql: "INSERT INTO kanban_card_label (id,cardId,name,sortOrder) VALUES ('l','c','UI',0)")
            try db.execute(sql: "INSERT INTO kanban_checklist_item (id,cardId,title,isCompleted,sortOrder) VALUES ('i','c','Test',0,0)")
            try db.execute(sql: "DELETE FROM kanban_project WHERE id = 'p'")
            XCTAssertEqual(try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM kanban_card"), 0)
            XCTAssertEqual(try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM kanban_card_label"), 0)
            XCTAssertEqual(try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM kanban_checklist_item"), 0)
        }
    }

    func testInvalidPersistedEnumsMapToSafeFallbacks() {
        let record = KanbanCardRecord(
            id: "c", projectId: "p", title: "Card", description: "", status: "invalid",
            priority: "invalid", dueDate: nil, sortOrder: 0, isArchived: false,
            createdAt: Date(), updatedAt: Date()
        )
        let mapped = record.card(labels: [], checklist: [])
        XCTAssertEqual(mapped.card.status, .backlog)
        XCTAssertEqual(mapped.card.priority, .medium)
        XCTAssertTrue(mapped.usedFallback)
    }
}
