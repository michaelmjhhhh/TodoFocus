import XCTest
import CryptoKit
@testable import TodoFocusMac

@MainActor
final class HardFocusSessionManagerTests: XCTestCase {
    func testInitEndsExpiredTimedSession() throws {
        let dbManager = try DatabaseManager(databasePath: ":memory:")
        let repository = HardFocusSessionRepository(dbQueue: dbManager.dbQueue)
        let session = HardFocusSessionRecord(
            sessionId: "expired-session",
            mode: "hard",
            status: .active,
            startTime: Date().addingTimeInterval(-600),
            plannedEndTime: Date().addingTimeInterval(-60),
            actualEndTime: nil,
            unlockPhraseHash: "hash",
            unlockPhraseSalt: "salt",
            blockedApps: #"["com.apple.Safari"]"#,
            focusTaskId: "task-1",
            graceSeconds: 300,
            createdAt: Date().addingTimeInterval(-600)
        )
        try repository.create(session)

        let manager = HardFocusSessionManager(
            repository: repository,
            agentManager: MockHardFocusAgentManager(isRegistered: true, isRunning: true),
            isAccessibilityTrusted: { true },
            agentStartupTimeout: 0,
            agentPollInterval: 0.01
        )

        XCTAssertFalse(manager.isEnforcing)
        XCTAssertNil(manager.currentSession)
        XCTAssertNil(try repository.activeSession())
    }

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

    func testStartSessionSucceedsWhenAgentIsNotRunning() async throws {
        let dbManager = try DatabaseManager(databasePath: ":memory:")
        let repository = HardFocusSessionRepository(dbQueue: dbManager.dbQueue)
        let agent = MockHardFocusAgentManager(isRegistered: false, isRunning: false)
        let enforcer = MockHardFocusInProcessEnforcer()
        let manager = HardFocusSessionManager(
            repository: repository,
            agentManager: agent,
            inProcessEnforcer: enforcer,
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
        XCTAssertEqual(enforcer.lastStartedBlockedApps, ["com.apple.Safari"])
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

    func testStartSessionPersistsNonEmptySalt() async throws {
        let dbManager = try DatabaseManager(databasePath: ":memory:")
        let repository = HardFocusSessionRepository(dbQueue: dbManager.dbQueue)
        let manager = HardFocusSessionManager(
            repository: repository,
            agentManager: MockHardFocusAgentManager(isRegistered: true, isRunning: true),
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

        let active = try repository.activeSession()
        XCTAssertNotNil(active)
        XCTAssertFalse(active?.unlockPhraseSalt.isEmpty ?? true)
    }

    func testEndSessionSupportsLegacyUnsaltedHashes() async throws {
        let dbManager = try DatabaseManager(databasePath: ":memory:")
        let repository = HardFocusSessionRepository(dbQueue: dbManager.dbQueue)
        let passphrase = "unlock"
        let legacyHash = SHA256.hash(data: Data(passphrase.utf8)).compactMap { String(format: "%02x", $0) }.joined()
        let session = HardFocusSessionRecord(
            sessionId: "legacy-session",
            mode: "hard",
            status: .active,
            startTime: Date().addingTimeInterval(-60),
            plannedEndTime: Date().addingTimeInterval(600),
            actualEndTime: nil,
            unlockPhraseHash: legacyHash,
            unlockPhraseSalt: "",
            blockedApps: #"["com.apple.Safari"]"#,
            focusTaskId: "task-1",
            graceSeconds: 300,
            createdAt: Date().addingTimeInterval(-60)
        )
        try repository.create(session)

        let manager = HardFocusSessionManager(
            repository: repository,
            agentManager: MockHardFocusAgentManager(isRegistered: true, isRunning: true),
            isAccessibilityTrusted: { true },
            agentStartupTimeout: 0,
            agentPollInterval: 0.01
        )

        try await manager.endSession(passphrase: passphrase)

        XCTAssertFalse(manager.isEnforcing)
        XCTAssertNil(manager.currentSession)
        XCTAssertNil(try repository.activeSession())
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

@MainActor
private final class MockHardFocusInProcessEnforcer: HardFocusInProcessEnforcing {
    private(set) var startCallCount = 0
    private(set) var stopCallCount = 0
    private(set) var lastStartedBlockedApps: [String] = []

    func start(blockedApps: [String]) {
        startCallCount += 1
        lastStartedBlockedApps = blockedApps
    }

    func stop() {
        stopCallCount += 1
    }
}
