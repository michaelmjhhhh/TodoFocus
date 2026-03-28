import XCTest
@testable import TodoFocusMac

@MainActor
final class HardFocusSessionManagerTests: XCTestCase {
    func testStartSessionRegistersAgentWhenNotRegistered() async throws {
        let dbManager = try DatabaseManager(databasePath: ":memory:")
        let repository = HardFocusSessionRepository(dbQueue: dbManager.dbQueue)
        let agent = MockHardFocusAgentManager(isRegistered: false, isRunning: true)
        let manager = HardFocusSessionManager(
            repository: repository,
            agentManager: agent,
            isAccessibilityTrusted: { true }
        )

        try await manager.startSession(
            blockedApps: ["com.apple.Safari"],
            duration: 60,
            focusTaskId: "task-1",
            passphrase: "unlock"
        )

        XCTAssertEqual(agent.registerCallCount, 1)
        XCTAssertTrue(manager.isEnforcing)
        XCTAssertNotNil(try repository.activeSession())
    }

    func testStartSessionFailsWhenAgentIsNotRunning() async throws {
        let dbManager = try DatabaseManager(databasePath: ":memory:")
        let repository = HardFocusSessionRepository(dbQueue: dbManager.dbQueue)
        let agent = MockHardFocusAgentManager(isRegistered: false, isRunning: false)
        let manager = HardFocusSessionManager(
            repository: repository,
            agentManager: agent,
            isAccessibilityTrusted: { true }
        )

        do {
            try await manager.startSession(
                blockedApps: ["com.apple.Safari"],
                duration: 60,
                focusTaskId: "task-1",
                passphrase: "unlock"
            )
            XCTFail("Expected agentNotAvailable")
        } catch let error as HardFocusError {
            XCTAssertEqual(error, .agentNotAvailable)
        }

        XCTAssertEqual(agent.registerCallCount, 1)
        XCTAssertFalse(manager.isEnforcing)
        XCTAssertNil(try repository.activeSession())
    }
}

private final class MockHardFocusAgentManager: HardFocusAgentControlling {
    var isRegistered: Bool
    var isRunning: Bool
    private(set) var registerCallCount = 0

    init(isRegistered: Bool, isRunning: Bool) {
        self.isRegistered = isRegistered
        self.isRunning = isRunning
    }

    func register() throws {
        registerCallCount += 1
        isRegistered = true
    }
}
