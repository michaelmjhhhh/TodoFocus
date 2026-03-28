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
            isAccessibilityTrusted: { true },
            agentStartupTimeout: 0,
            agentPollInterval: 0.01
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
            isAccessibilityTrusted: { true },
            agentStartupTimeout: 0,
            agentPollInterval: 0.01
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

    func testStartSessionWaitsForAgentToBecomeRunningAfterRegister() async throws {
        let dbManager = try DatabaseManager(databasePath: ":memory:")
        let repository = HardFocusSessionRepository(dbQueue: dbManager.dbQueue)
        let agent = MockHardFocusAgentManager(
            isRegistered: false,
            isRunning: false,
            runningAfterRegisterDelay: 0.05
        )
        let manager = HardFocusSessionManager(
            repository: repository,
            agentManager: agent,
            isAccessibilityTrusted: { true },
            agentStartupTimeout: 0.3,
            agentPollInterval: 0.01
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
}

private final class MockHardFocusAgentManager: HardFocusAgentControlling {
    var isRegistered: Bool
    private let initialIsRunning: Bool
    private let runningAfterRegisterDelay: TimeInterval?
    private var registerTime: Date?
    private(set) var registerCallCount = 0

    var isRunning: Bool {
        if let runningAfterRegisterDelay,
           let registerTime {
            return Date().timeIntervalSince(registerTime) >= runningAfterRegisterDelay
        }
        return initialIsRunning
    }

    init(isRegistered: Bool, isRunning: Bool, runningAfterRegisterDelay: TimeInterval? = nil) {
        self.isRegistered = isRegistered
        self.initialIsRunning = isRunning
        self.runningAfterRegisterDelay = runningAfterRegisterDelay
    }

    func register() throws {
        registerCallCount += 1
        isRegistered = true
        registerTime = Date()
    }
}
