import XCTest
import GRDB
@testable import TodoFocusMac

final class AgentHeartbeatRecordTests: XCTestCase {
    func testWriteHeartbeatAndReadHeartbeatRoundtrip() throws {
        let manager = try DatabaseManager(databasePath: ":memory:")
        let repository = HardFocusSessionRepository(dbQueue: manager.dbQueue)

        try repository.writeHeartbeat(sessionId: "session-123")

        let heartbeat = try repository.readHeartbeat()
        XCTAssertNotNil(heartbeat)
        XCTAssertEqual(heartbeat?.agentId, "primary")
        XCTAssertEqual(heartbeat?.currentSessionId, "session-123")
    }

    func testIsAgentAliveReturnsTrueAfterHeartbeatWritten() throws {
        let manager = try DatabaseManager(databasePath: ":memory:")
        let repository = HardFocusSessionRepository(dbQueue: manager.dbQueue)

        try repository.writeHeartbeat(sessionId: nil)

        XCTAssertTrue(try repository.isAgentAlive())
    }

    func testIsAgentAliveReturnsFalseWhenNoHeartbeat() throws {
        let manager = try DatabaseManager(databasePath: ":memory:")
        let repository = HardFocusSessionRepository(dbQueue: manager.dbQueue)

        XCTAssertFalse(try repository.isAgentAlive())
    }

    func testIsAgentAliveReturnsFalseWhenHeartbeatStale() throws {
        let manager = try DatabaseManager(databasePath: ":memory:")
        let repository = HardFocusSessionRepository(dbQueue: manager.dbQueue)

        // Manually insert a stale heartbeat (older than 120s threshold)
        let staleDate = Date().addingTimeInterval(-200)
        try manager.dbQueue.write { db in
            try db.execute(
                sql: """
                    INSERT OR REPLACE INTO agent_heartbeat (agent_id, last_heartbeat, current_session_id)
                    VALUES (?, ?, NULL)
                    """,
                arguments: ["primary", staleDate]
            )
        }

        XCTAssertFalse(try repository.isAgentAlive())
    }

    func testWriteHeartbeatUpdatesExistingHeartbeat() throws {
        let manager = try DatabaseManager(databasePath: ":memory:")
        let repository = HardFocusSessionRepository(dbQueue: manager.dbQueue)

        try repository.writeHeartbeat(sessionId: "session-1")
        try repository.writeHeartbeat(sessionId: "session-2")

        let heartbeat = try repository.readHeartbeat()
        XCTAssertEqual(heartbeat?.currentSessionId, "session-2")
    }
}
