import Foundation
import GRDB

final class AgentDatabase {
    private let dbQueue: DatabaseQueue

    init(appGroupIdentifier: String = "group.com.todofocus") throws {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
            throw AgentError.appGroupNotFound
        }
        let dbURL = containerURL.appendingPathComponent("todofocus.db")
        var config = Configuration()
        // Agent writes heartbeat only; session data is read-only
        self.dbQueue = try DatabaseQueue(path: dbURL.path, configuration: config)
    }

    func readActiveSession() throws -> HardFocusSessionRecord? {
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
}

enum AgentError: Error {
    case appGroupNotFound
}