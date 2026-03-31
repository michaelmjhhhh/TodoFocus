import Foundation
import GRDB

enum ListRepositoryError: Error {
    case notFound
}

struct ListRepository {
    private let dbQueue: DatabaseQueue

    init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }

    func createList(name: String, color: String = "#6366F1", now: Date = Date()) throws -> ListRecord {
        try dbQueue.write { db in
            let count = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM list") ?? 0
            let record = ListRecord(
                id: UUID().uuidString,
                name: name,
                color: color,
                sortOrder: count,
                createdAt: now,
                updatedAt: now
            )
            try record.insert(db)
            return record
        }
    }

    func renameList(id: String, name: String, color: String? = nil, now: Date = Date()) throws {
        try dbQueue.write { db in
            guard var record = try ListRecord.fetchOne(db, key: id) else {
                throw ListRepositoryError.notFound
            }
            record.name = name
            if let color {
                record.color = color
            }
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
