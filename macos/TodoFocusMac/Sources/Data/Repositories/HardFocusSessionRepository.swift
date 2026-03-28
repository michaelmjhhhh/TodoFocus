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

    func updateStatus(sessionId: String, status: HardFocusStatus, actualEndTime: Date? = nil) throws {
        try dbQueue.write { db in
            try db.execute(
                sql: """
                    UPDATE hardfocus_session
                    SET status = ?, actual_end_time = ?
                    WHERE session_id = ?
                    """,
                arguments: [status.rawValue, actualEndTime, sessionId]
            )
        }
    }

    func activeSession() throws -> HardFocusSessionRecord? {
        try dbQueue.read { db in
            try HardFocusSessionRecord
                .filter(Column("status") == HardFocusStatus.active)
                .order(Column("created_at").desc)
                .fetchOne(db)
        }
    }

    func writeHeartbeat(sessionId: String?) throws {
        try dbQueue.write { db in
            let record = AgentHeartbeatRecord(
                agentId: "primary",
                lastHeartbeat: Date(),
                currentSessionId: sessionId
            )
            try record.save(db)
        }
    }

    func readHeartbeat() throws -> AgentHeartbeatRecord? {
        try dbQueue.read { db in
            try AgentHeartbeatRecord.fetchOne(db, key: "primary")
        }
    }

    func isAgentAlive() throws -> Bool {
        guard let heartbeat = try readHeartbeat() else { return false }
        let staleThreshold: TimeInterval = 120  // 2 minutes
        return Date().timeIntervalSince(heartbeat.lastHeartbeat) < staleThreshold
    }
}
