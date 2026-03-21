import Foundation
import GRDB

enum StepRepositoryError: Error, Equatable {
    case invalidTitle
}

struct StepRepository {
    private let dbQueue: DatabaseQueue

    init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }

    func addStep(todoID: String, title: String) throws -> StepRecord {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            throw StepRepositoryError.invalidTitle
        }

        return try dbQueue.write { db in
            let count = try Int.fetchOne(
                db,
                sql: "SELECT COUNT(*) FROM step WHERE todoId = ?",
                arguments: [todoID]
            ) ?? 0

            let step = StepRecord(
                id: UUID().uuidString,
                title: trimmedTitle,
                isCompleted: false,
                sortOrder: count,
                todoId: todoID
            )
            try step.insert(db)
            return step
        }
    }

    func updateStepTitle(id: String, title: String) throws {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            throw StepRepositoryError.invalidTitle
        }

        try dbQueue.write { db in
            try db.execute(
                sql: "UPDATE step SET title = ? WHERE id = ?",
                arguments: [trimmedTitle, id]
            )
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
