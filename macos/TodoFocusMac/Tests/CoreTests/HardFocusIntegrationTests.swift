import XCTest
@testable import TodoFocusMac

final class HardFocusIntegrationTests: XCTestCase {
    func testSessionRoundTrip() throws {
        // 1. Create in-memory DB
        let dbManager = try DatabaseManager(databasePath: ":memory:")
        let repo = HardFocusSessionRepository(dbQueue: dbManager.dbQueue)

        // 2. Create session
        let session = HardFocusSessionRecord(
            sessionId: "test-1",
            mode: "hard",
            status: .active,
            startTime: Date(),
            plannedEndTime: Date().addingTimeInterval(3600),
            actualEndTime: nil,
            unlockPhraseHash: "abc123",
            unlockPhraseSalt: "salt-1",
            blockedApps: #"["com.apple.Safari"]"#,
            focusTaskId: nil,
            graceSeconds: 300,
            createdAt: Date()
        )
        try repo.create(session)

        // 3. Read back
        let active = try repo.activeSession()
        XCTAssertNotNil(active)
        XCTAssertEqual(active?.sessionId, "test-1")
        XCTAssertEqual(active?.blockedAppsBundleIds, ["com.apple.Safari"])

        // 4. Complete session
        try repo.updateStatus(sessionId: "test-1", status: .completed, actualEndTime: Date())

        // 5. Verify no active session
        let after = try repo.activeSession()
        XCTAssertNil(after)
    }

    func testHeartbeatWriteAndRead() throws {
        let dbManager = try DatabaseManager(databasePath: ":memory:")
        let repo = HardFocusSessionRepository(dbQueue: dbManager.dbQueue)

        try repo.writeHeartbeat(sessionId: "session-1")

        let heartbeat = try repo.readHeartbeat()
        XCTAssertNotNil(heartbeat)
        XCTAssertEqual(heartbeat?.currentSessionId, "session-1")
    }

    func testIsAgentAlive() throws {
        let dbManager = try DatabaseManager(databasePath: ":memory:")
        let repo = HardFocusSessionRepository(dbQueue: dbManager.dbQueue)

        // No heartbeat yet
        XCTAssertFalse(try repo.isAgentAlive())

        // Write fresh heartbeat
        try repo.writeHeartbeat(sessionId: nil)

        // Should be alive (within 120s)
        XCTAssertTrue(try repo.isAgentAlive())
    }

    func testSessionBlocksDistractingApps() throws {
        let dbManager = try DatabaseManager(databasePath: ":memory:")
        let repo = HardFocusSessionRepository(dbQueue: dbManager.dbQueue)

        let session = HardFocusSessionRecord(
            sessionId: "test-focus",
            mode: "hard",
            status: .active,
            startTime: Date(),
            plannedEndTime: Date().addingTimeInterval(1800),
            actualEndTime: nil,
            unlockPhraseHash: "xyz789",
            unlockPhraseSalt: "salt-2",
            blockedApps: #"["com.google.Chrome","com.hnc.Discord","com.slack.Slack"]"#,
            focusTaskId: "task-123",
            graceSeconds: 300,
            createdAt: Date()
        )
        try repo.create(session)

        let active = try repo.activeSession()
        XCTAssertNotNil(active)
        XCTAssertEqual(active?.blockedAppsBundleIds, ["com.google.Chrome", "com.hnc.Discord", "com.slack.Slack"])
        XCTAssertEqual(active?.focusTaskId, "task-123")
        XCTAssertEqual(active?.mode, "hard")
    }
}
