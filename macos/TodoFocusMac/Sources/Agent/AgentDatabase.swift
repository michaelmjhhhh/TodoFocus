import Foundation
import GRDB

final class AgentDatabase {
    private let dbQueue: DatabaseQueue

    init(appGroupIdentifier: String = "group.com.todofocus") throws {
        let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support/todofocus")
        let dbURL = containerURL.appendingPathComponent("todofocus.db")
        var config = Configuration()
        config.foreignKeysEnabled = true
        // Agent writes heartbeat only; session data is read-only
        self.dbQueue = try DatabaseQueue(path: dbURL.path, configuration: config)
        try Migrations.makeMigrator().migrate(dbQueue)
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