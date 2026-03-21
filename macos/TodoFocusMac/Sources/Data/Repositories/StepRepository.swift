import Foundation
import GRDB

struct StepRepository {
    private let dbQueue: DatabaseQueue

    init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }

    func addStep(todoID: String, title: String) throws -> StepRecord {
        try dbQueue.write { db in
            let count = try Int.fetchOne(
                db,
                sql: "SELECT COUNT(*) FROM step WHERE todoId = ?",
                arguments: [todoID]
            ) ?? 0

            var step = StepRecord(
                id: UUID().uuidString,
                title: title,
                isCompleted: false,
                sortOrder: count,
                todoId: todoID
            )
            try step.insert(db)
            return step
        }
    }

    func toggleStep(id: String, isCompleted: Bool) throws {
        try dbQueue.write { db in
            try db.execute(
                sql: "UPDATE step SET isCompleted = ? WHERE id = ?",
                arguments: [isCompleted, id]
            )
        }
    }

    func deleteStep(id: String) throws {
        try dbQueue.write { db in
            _ = try StepRecord.deleteOne(db, key: id)
        }
    }

    func fetchSteps(todoID: String) throws -> [StepRecord] {
        try dbQueue.read { db in
            try StepRecord
                .filter(Column("todoId") == todoID)
                .order(Column("sortOrder").asc)
                .fetchAll(db)
        }
    }
}
