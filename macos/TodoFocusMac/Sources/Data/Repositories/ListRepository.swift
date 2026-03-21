import Foundation
import GRDB

enum ListRepositoryError: Error {
    case notFound
}

struct ListRepository {
    private let dbQueue: DatabaseQueue
    private let colors = ["#6366F1", "#8B5CF6", "#EC4899", "#F59E0B", "#10B981", "#3B82F6", "#EF4444"]

    init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }

    func createList(name: String, now: Date = Date()) throws -> ListRecord {
        try dbQueue.write { db in
            let count = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM list") ?? 0
            var record = ListRecord(
                id: UUID().uuidString,
                name: name,
                color: colors[count % colors.count],
                sortOrder: count,
                createdAt: now,
                updatedAt: now
            )
            try record.insert(db)
            return record
        }
    }

    func renameList(id: String, name: String, now: Date = Date()) throws {
        try dbQueue.write { db in
            guard var record = try ListRecord.fetchOne(db, key: id) else {
                throw ListRepositoryError.notFound
            }
            record.name = name
            record.updatedAt = now
            try record.update(db)
        }
    }

    func deleteList(id: String) throws {
        try dbQueue.write { db in
            _ = try ListRecord.deleteOne(db, key: id)
        }
    }

    func fetchListsOrdered() throws -> [ListRecord] {
        try dbQueue.read { db in
            try ListRecord
                .order(Column("sortOrder").asc)
                .fetchAll(db)
        }
    }
}
