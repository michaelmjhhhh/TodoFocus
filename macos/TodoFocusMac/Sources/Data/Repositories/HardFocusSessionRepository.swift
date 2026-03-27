import Foundation
import GRDB

final class HardFocusSessionRepository {
    private let dbQueue: DatabaseQueue

    init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }

    func create(_ session: HardFocusSessionRecord) throws {
        try dbQueue.write { db in
            try session.insert(db)
        }
    }

    func updateStatus(sessionId: String, status: String, actualEndTime: Date? = nil) throws {
        try dbQueue.write { db in
            try db.execute(
                sql: """
                    UPDATE hardfocus_session
                    SET status = ?, actual_end_time = ?
                    WHERE session_id = ?
                    """,
                arguments: [status, actualEndTime, sessionId]
            )
        }
    }

    func activeSession() throws -> HardFocusSessionRecord? {
        try dbQueue.read { db in
            try HardFocusSessionRecord
                .filter(Column("status") == "active")
                .order(Column("created_at").desc)
                .fetchOne(db)
        }
    }
}
