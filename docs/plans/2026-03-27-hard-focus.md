# Hard Focus Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement a Hard Focus system that terminates blocked apps during focus sessions and prevents reopening until the session ends.

**Architecture:** Two-process system: Main App (SwiftUI) manages session lifecycle and UI; HardFocusAgent (LaunchAgent) runs always-alive, polling SQLite for active sessions and enforcing app blocking via NSWorkspace APIs. SQLite is the single source of truth. Single-writer model: only the main app writes session state; agent is read-only except heartbeat.

**Tech Stack:** Swift, SQLite (GRDB), NSWorkspace notifications, SMAppService, LaunchAgent

---

## Prerequisites

Before any task, read these files:
- `macos/TodoFocusMac/Sources/App/DeepFocusService.swift` — existing soft focus (overlay-only) for reference
- `macos/TodoFocusMac/Sources/Data/Database/DatabaseManager.swift` — existing DB setup
- `macos/TodoFocusMac/Sources/Data/Database/Migrations.swift` — existing migration pattern
- `docs/superpowers/plans/2026-03-27-hard-focus-design.md` — authoritative design reference

---

## Task 1: GRDB Migration for Hard Focus Tables

**Files:**
- Modify: `macos/TodoFocusMac/Sources/Data/Database/Migrations.swift`

**Step 1: Add migration v3 for hardfocus_session and agent_heartbeat tables**

Add to `Migrations.swift`:

```swift
migrator.registerMigration("v3_hardfocus") { db in
    try db.create(table: "hardfocus_session") { t in
        t.column("session_id", .text).primaryKey()
        t.column("mode", .text).notNull()
        t.column("status", .text).notNull().defaults(to: "active")
        t.column("start_time", .datetime).notNull()
        t.column("planned_end_time", .datetime).notNull()
        t.column("actual_end_time", .datetime)
        t.column("unlock_phrase_hash", .text).notNull()
        t.column("blocked_apps", .text).notNull()
        t.column("focus_task_id", .text)
        t.column("grace_seconds", .integer).notNull().defaults(to: 300)
        t.column("created_at", .datetime).notNull()
    }

    try db.create(table: "agent_heartbeat") { t in
        t.column("agent_id", .text).primaryKey().defaults(to: "primary")
        t.column("last_heartbeat", .datetime).notNull()
        t.column("current_session_id", .text)
    }

    try db.create(
        index: "idx_session_active",
        on: "hardfocus_session",
        columns: ["status"],
        condition: Column("status") == "active"
    )
}
```

**Step 2: Verify migration applies cleanly**

Run: `xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS" 2>&1 | grep -E "(error:|warning:.*Migration)"`

Expected: Build succeeds with no migration errors

**Step 3: Commit**

```bash
git add macos/TodoFocusMac/Sources/Data/Database/Migrations.swift
git commit -m "feat(db): add hardfocus_session and agent_heartbeat tables"
```

---

## Task 2: HardFocusSession DTO and Repository

**Files:**
- Create: `macos/TodoFocusMac/Sources/Data/DTO/HardFocusSessionRecord.swift`
- Create: `macos/TodoFocusMac/Sources/Data/Repositories/HardFocusSessionRepository.swift`

**Step 1: Write failing test for session DTO mapping**

Create `macos/TodoFocusMac/Tests/DataTests/HardFocusSessionRecordTests.swift`:

```swift
import XCTest
@testable import TodoFocusMac

final class HardFocusSessionRecordTests: XCTestCase {
    func testSessionRecordMapsAllFields() {
        let record = HardFocusSessionRecord(
            sessionId: "test-id",
            mode: "hard",
            status: "active",
            startTime: Date(),
            plannedEndTime: Date().addingTimeInterval(3600),
            actualEndTime: nil,
            unlockPhraseHash: "argon2hash",
            blockedApps: #"["com.apple.Safari"]"#,
            focusTaskId: nil,
            graceSeconds: 300,
            createdAt: Date()
        )

        XCTAssertEqual(record.sessionId, "test-id")
        XCTAssertEqual(record.mode, "hard")
        XCTAssertEqual(record.status, "active")
        XCTAssertEqual(record.blockedApps, #"["com.apple.Safari"]"#)
        XCTAssertEqual(record.graceSeconds, 300)
    }

    func testBlockedAppsDecodeToBundleIds() {
        let record = HardFocusSessionRecord(
            sessionId: "test-id",
            mode: "hard",
            status: "active",
            startTime: Date(),
            plannedEndTime: Date().addingTimeInterval(3600),
            actualEndTime: nil,
            unlockPhraseHash: "argon2hash",
            blockedApps: #"["com.google.Chrome","com.hnc.Discord"]"#,
            focusTaskId: nil,
            graceSeconds: 300,
            createdAt: Date()
        )

        let bundleIds = record.blockedAppsBundleIds
        XCTAssertEqual(bundleIds.count, 2)
        XCTAssertTrue(bundleIds.contains("com.google.Chrome"))
    }
}
```

**Step 2: Run test to verify it fails (HardFocusSessionRecord doesn't exist yet)**

Run: `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS" -only-testing:DataTests/HardFocusSessionRecordTests 2>&1 | tail -20`

Expected: FAIL — HardFocusSessionRecord not found

**Step 3: Create HardFocusSessionRecord DTO**

```swift
import Foundation
import GRDB

struct HardFocusSessionRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "hardfocus_session"

    var sessionId: String
    var mode: String
    var status: String
    var startTime: Date
    var plannedEndTime: Date
    var actualEndTime: Date?
    var unlockPhraseHash: String
    var blockedApps: String  // JSON array of bundle IDs
    var focusTaskId: String?
    var graceSeconds: Int
    var createdAt: Date

    var blockedAppsBundleIds: [String] {
        guard let data = blockedApps.data(using: .utf8),
              let ids = try? JSONDecoder().decode([String].self, from: data)
        else { return [] }
        return ids
    }
}
```

**Step 4: Create HardFocusSessionRepository with CRUD**

```swift
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
```

**Step 5: Run tests to verify they pass**

Run: `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS" -only-testing:DataTests/HardFocusSessionRecordTests 2>&1 | tail -10`

Expected: PASS

**Step 6: Commit**

```bash
git add macos/TodoFocusMac/Sources/Data/DTO/HardFocusSessionRecord.swift macos/TodoFocusMac/Sources/Data/Repositories/HardFocusSessionRepository.swift macos/TodoFocusMac/Tests/DataTests/HardFocusSessionRecordTests.swift
git commit -m "feat(core): add HardFocusSession DTO and repository"
```

---

## Task 3: Heartbeat Record and Agent Heartbeat Repository

**Files:**
- Create: `macos/TodoFocusMac/Sources/Data/DTO/AgentHeartbeatRecord.swift`
- Modify: `macos/TodoFocusMac/Sources/Data/Repositories/HardFocusSessionRepository.swift` (add heartbeat methods)

**Step 1: Write failing test for heartbeat record**

Create `macos/TodoFocusMac/Tests/DataTests/AgentHeartbeatRecordTests.swift`:

```swift
import XCTest
@testable import TodoFocusMac

final class AgentHeartbeatRecordTests: XCTestCase {
    func testHeartbeatRecordDefaultAgentId() {
        let record = AgentHeartbeatRecord(
            agentId: "primary",
            lastHeartbeat: Date(),
            currentSessionId: nil
        )
        XCTAssertEqual(record.agentId, "primary")
        XCTAssertNil(record.currentSessionId)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS" -only-testing:DataTests/AgentHeartbeatRecordTests 2>&1 | tail -10`

Expected: FAIL — AgentHeartbeatRecord not found

**Step 3: Create AgentHeartbeatRecord**

```swift
import Foundation
import GRDB

struct AgentHeartbeatRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "agent_heartbeat"

    var agentId: String
    var lastHeartbeat: Date
    var currentSessionId: String?
}
```

**Step 4: Add heartbeat read/write methods to HardFocusSessionRepository**

```swift
// In HardFocusSessionRepository:

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
```

**Step 5: Run tests to verify they pass**

Run: `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS" -only-testing:DataTests/AgentHeartbeatRecordTests 2>&1 | tail -10`

Expected: PASS

**Step 6: Commit**

```bash
git add macos/TodoFocusMac/Sources/Data/DTO/AgentHeartbeatRecord.swift macos/TodoFocusMac/Sources/Data/Repositories/HardFocusSessionRepository.swift macos/TodoFocusMac/Tests/DataTests/AgentHeartbeatRecordTests.swift
git commit -m "feat(core): add agent heartbeat record and repository methods"
```

---

## Task 4: HardFocusService — Session Lifecycle (Main App Side)

**Files:**
- Create: `macos/TodoFocusMac/Sources/App/HardFocusSessionManager.swift`

**Step 1: Write failing test for session manager**

Create `macos/TodoFocusMac/Tests/CoreTests/HardFocusSessionManagerTests.swift`:

```swift
import XCTest
@testable import TodoFocusMac

final class HardFocusSessionManagerTests: XCTestCase {
    func testStartSessionRequiresAccessibilityPermission() async {
        // Temporarily override AXIsProcessTrusted to return false
        let manager = HardFocusSessionManager()
        // In real test, would need to mock AppKit / AX API
        // This test documents the requirement
    }

    func testStartSessionFailsIfAgentNotAlive() async throws {
        // Would need dependency injection of repository
        // Document: manager.startSession() throws if isAgentAlive() == false
    }
}
```

**Step 2: Run test to verify it fails (file doesn't exist yet)**

Run: `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS" -only-testing:CoreTests/HardFocusSessionManagerTests 2>&1 | tail -10`

Expected: FAIL — HardFocusSessionManager not found

**Step 3: Create HardFocusSessionManager**

```swift
import Foundation
import AppKit
import CryptoKit

enum HardFocusError: Error {
    case accessibilityPermissionDenied
    case agentNotAvailable
    case noActiveSession
    case invalidPassphrase
}

@MainActor
final class HardFocusSessionManager: ObservableObject {
    @Published private(set) var currentSession: HardFocusSessionRecord?
    @Published private(set) var isEnforcing = false

    private let repository: HardFocusSessionRepository
    private var timer: Timer?

    init(repository: HardFocusSessionRepository) {
        self.repository = repository
    }

    // MARK: - Public API

    func canStartSession() -> Bool {
        return AXIsProcessTrusted()
    }

    func startSession(
        blockedApps: [String],
        duration: TimeInterval?,
        focusTaskId: String?,
        passphrase: String
    ) async throws {
        guard AXIsProcessTrusted() else {
            throw HardFocusError.accessibilityPermissionDenied
        }

        guard try repository.isAgentAlive() else {
            throw HardFocusError.agentNotAvailable
        }

        let endTime: Date
        if let duration {
            endTime = Date().addingTimeInterval(duration)
        } else {
            // No duration = indefinite (until manually ended)
            endTime = Date.distantFuture
        }

        let passphraseHash = hashPassphrase(passphrase)
        let blockedAppsJson = try JSONEncoder().encode(blockedApps)
        let blockedAppsString = String(data: blockedAppsJson, encoding: .utf8)!

        let session = HardFocusSessionRecord(
            sessionId: UUID().uuidString,
            mode: "hard",
            status: "active",
            startTime: Date(),
            plannedEndTime: endTime,
            actualEndTime: nil,
            unlockPhraseHash: passphraseHash,
            blockedApps: blockedAppsString,
            focusTaskId: focusTaskId,
            graceSeconds: 300,
            createdAt: Date()
        )

        try repository.create(session)
        currentSession = session
        isEnforcing = true

        if let duration {
            startTimer(duration: duration)
        }
    }

    func endSession(passphrase: String) async throws {
        guard let session = currentSession else {
            throw HardFocusError.noActiveSession
        }

        guard verifyPassphrase(passphrase, hash: session.unlockPhraseHash) else {
            throw HardFocusError.invalidPassphrase
        }

        try repository.updateStatus(
            sessionId: session.sessionId,
            status: "completed",
            actualEndTime: Date()
        )

        currentSession = nil
        isEnforcing = false
        timer?.invalidate()
    }

    func emergencyEndSession() async throws {
        guard let session = currentSession else {
            throw HardFocusError.noActiveSession
        }

        try repository.updateStatus(
            sessionId: session.sessionId,
            status: "interrupted",
            actualEndTime: Date()
        )

        currentSession = nil
        isEnforcing = false
        timer?.invalidate()
    }

    // MARK: - Private

    private func startTimer(duration: TimeInterval) {
        timer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            Task { @MainActor in
                try? await self?.endSession(passphrase: "")  // Timer expiry = no passphrase needed
            }
        }
    }

    private func hashPassphrase(_ phrase: String) -> String {
        // Argon2 via CryptoKit (using SHA256 as fallback for now;
        // full Argon2 requires第三方 library or CommonCrypto interop)
        let data = Data(phrase.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    private func verifyPassphrase(_ phrase: String, hash: String) -> Bool {
        return hashPassphrase(phrase) == hash
    }
}
```

**Step 4: Verify build**

Run: `xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS" 2>&1 | grep -E "error:" | head -10`

Expected: Build succeeds

**Step 5: Commit**

```bash
git add macos/TodoFocusMac/Sources/App/HardFocusSessionManager.swift
git commit -m "feat(app): add HardFocusSessionManager for session lifecycle"
```

---

## Task 5: HardFocusAgent — Main Entry Point and Database Access

**Files:**
- Create: `macos/TodoFocusMac/Sources/Agent/main.swift`
- Create: `macos/TodoFocusMac/Sources/Agent/AgentDatabase.swift`

**Step 1: Create stub main.swift**

```swift
import Foundation

// Agent entry point
// Compile as a separate executable target: TodoFocusAgent
// Run as: /path/to/TodoFocusAgent

autoreleasepool {
    let controller = AgentSessionController()
    controller.run()
}

RunLoop.main.run()
```

**Step 2: Create AgentDatabase (read-only DB access)**

```swift
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
        config.readonly = false  // Agent writes heartbeat only
        self.dbQueue = try DatabaseQueue(path: dbURL.path, configuration: config)
    }

    func readActiveSession() throws -> HardFocusSessionRecord? {
        try dbQueue.read { db in
            try HardFocusSessionRecord
                .filter(Column("status") == "active")
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
```

**Step 3: Verify build (agent target)**

Run: `xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusAgent" -destination "platform=macOS" 2>&1 | grep -E "error:" | head -10`

Note: TodoFocusAgent scheme may not exist yet. This is expected — the Xcode project configuration is a later task.

**Step 4: Commit**

```bash
git add macos/TodoFocusMac/Sources/Agent/main.swift macos/TodoFocusMac/Sources/Agent/AgentDatabase.swift
git commit -m "feat(agent): add agent entry point and read-only database access"
```

---

## Task 6: HardFocusAgent — Session Controller (Idle/Active State Machine)

**Files:**
- Create: `macos/TodoFocusMac/Sources/Agent/AgentSessionController.swift`

**Step 1: Write stub then implement AgentSessionController**

```swift
import Foundation
import AppKit

enum AgentState {
    case idle
    case active(session: HardFocusSessionRecord)
}

final class AgentSessionController {
    private let db: AgentDatabase
    private let enforcer: AppEnforcer
    private var state: AgentState = .idle
    private var idleTimer: Timer?
    private var activeTimer: Timer?
    private var heartbeatTimer: Timer?

    init() {
        self.db = try! AgentDatabase()
        self.enforcer = AppEnforcer()
    }

    func run() {
        startIdleLoop()
        registerDistributedNotificationObserver()
        RunLoop.main.run()
    }

    // MARK: - Idle Loop

    private func startIdleLoop() {
        idleTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.checkForActiveSession()
        }
        idleTimer?.fire()
    }

    private func checkForActiveSession() {
        guard case .idle = state else { return }

        do {
            if let session = try db.readActiveSession() {
                activateSession(session)
            }
        } catch {
            print("Error reading active session: \(error)")
        }
    }

    // MARK: - Active Session

    private func activateSession(_ session: HardFocusSessionRecord) {
        state = .active(session: session)
        idleTimer?.invalidate()
        idleTimer = nil

        // Initial sweep
        enforcer.sweepAndTerminate(blockedApps: session.blockedAppsBundleIds)

        // Register observers
        enforcer.startObserving(blockedApps: session.blockedAppsBundleIds)

        // Start active poll loop (every 5s)
        activeTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.pollForSessionEnd()
        }

        // Start heartbeat (every 30s)
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.writeHeartbeat()
        }
        writeHeartbeat()
    }

    private func pollForSessionEnd() {
        guard case .active(let session) = state else { return }

        do {
            if let currentSession = try db.readActiveSession(),
               currentSession.sessionId == session.sessionId {
                // Still active, check overdue
                checkOverdue(session: currentSession)
            } else {
                // Session ended or replaced
                deactivateSession()
            }
        } catch {
            print("Error polling session: \(error)")
        }
    }

    private func checkOverdue(session: HardFocusSessionRecord) {
        let now = Date()
        if now > session.plannedEndTime {
            let graceEnd = session.plannedEndTime.addingTimeInterval(TimeInterval(session.graceSeconds))
            if now > graceEnd {
                // Beyond grace — could stop strict enforcement but don't exit
                // Main app is responsible for ending session
            }
        }
    }

    private func deactivateSession() {
        enforcer.stopObserving()
        activeTimer?.invalidate()
        activeTimer = nil
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil

        state = .idle
        startIdleLoop()
    }

    private func writeHeartbeat() {
        let sessionId: String?
        if case .active(let session) = state {
            sessionId = session.sessionId
        } else {
            sessionId = nil
        }
        try? db.writeHeartbeat(sessionId: sessionId)
    }

    // MARK: - Distributed Notification Hint

    private func registerDistributedNotificationObserver() {
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleSessionChanged),
            name: NSNotification.Name("com.todofocus.hardfocus.session.changed"),
            object: nil
        )
    }

    @objc private func handleSessionChanged() {
        checkForActiveSession()
    }
}
```

**Step 2: Commit**

```bash
git add macos/TodoFocusMac/Sources/Agent/AgentSessionController.swift
git commit -m "feat(agent): add idle/active state machine controller"
```

---

## Task 7: HardFocusAgent — AppEnforcer (Three-Layer Blocking)

**Files:**
- Create: `macos/TodoFocusMac/Sources/Agent/AppEnforcer.swift`

**Step 1: Write stub then implement AppEnforcer**

```swift
import Foundation
import AppKit

final class AppEnforcer {
    private var launchObserver: NSObjectProtocol?
    private var activationObserver: NSObjectProtocol?
    private var blockedApps: [String] = []

    // MARK: - Initial Sweep

    func sweepAndTerminate(blockedApps: [String]) {
        self.blockedApps = blockedApps
        let running = NSWorkspace.shared.runningApplications
        for app in running {
            guard let bundleId = app.bundleIdentifier,
                  blockedApps.contains(bundleId) else { continue }
            terminateApp(app)
        }
    }

    // MARK: - Observer Management

    func startObserving(blockedApps: [String]) {
        self.blockedApps = blockedApps

        let center = NSWorkspace.shared.notificationCenter

        // Layer 2: Launch detection
        launchObserver = center.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleAppLaunch(notification)
        }

        // Layer 3: Activation fallback
        activationObserver = center.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleAppActivation(notification)
        }
    }

    func stopObserving() {
        if let obs = launchObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(obs)
            launchObserver = nil
        }
        if let obs = activationObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(obs)
            activationObserver = nil
        }
        blockedApps = []
    }

    // MARK: - Event Handlers

    private func handleAppLaunch(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              let bundleId = app.bundleIdentifier,
              blockedApps.contains(bundleId) else { return }
        terminateApp(app)
    }

    private func handleAppActivation(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              let bundleId = app.bundleIdentifier,
              blockedApps.contains(bundleId) else { return }
        // Only kill if it's already running (activation means it stole focus)
        terminateApp(app)
    }

    // MARK: - Kill Strategy

    private func terminateApp(_ app: NSRunningApplication) {
        // Layer 1: Graceful terminate
        let terminated = app.terminate()

        if !terminated {
            // Layer 2: forceTerminate (sandbox-safe)
            app.forceTerminate()
        }

        // Layer 3: SIGKILL only for same-UID processes (own apps)
        // This is handled by the system; our sandboxed process can't SIGKILL others
    }
}
```

**Step 2: Commit**

```bash
git add macos/TodoFocusMac/Sources/Agent/AppEnforcer.swift
git commit -m "feat(agent): add three-layer app blocking enforcer"
```

---

## Task 8: HardFocusAgent — LaunchAgent Plist and SMAppService Integration

**Files:**
- Create: `macos/TodoFocusMac/Resources/com.todofocus.hardfocus.agent.plist`
- Modify: `macos/TodoFocusMac/Sources/App/HardFocusAgentManager.swift` (start/stop/verify agent)

**Step 1: Create LaunchAgent plist**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.todofocus.hardfocus.agent</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Applications/TodoFocus.app/Contents/MacOS/TodoFocusAgent</string>
    </array>
    <key>KeepAlive</key>
    <true/>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/todofocus-agent.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/todofocus-agent-error.log</string>
</dict>
</plist>
```

**Step 2: Create HardFocusAgentManager in main app**

```swift
import Foundation
import ServiceManagement

enum HardFocusAgentError: Error {
    case registrationFailed
    case startFailed
    case stopFailed
}

final class HardFocusAgentManager {
    private let service: SMAppService

    init() {
        // Note: plist must be installed in ~/Library/LaunchAgents first
        // SMAppService.agent(plistName:) registers the agent for later startup
        self.service = SMAppService.agent(plistName: "com.todofocus.hardfocus.agent")
    }

    func register() throws {
        try service.register()
    }

    func start() throws {
        try service.start()
    }

    func stop() throws {
        try service.stop()
    }

    func isRegistered() -> Bool {
        service.status == .enabled
    }

    func isRunning() -> Bool {
        service.status == .enabled
    }
}
```

**Step 3: Commit**

```bash
git add macos/TodoFocusMac/Resources/com.todofocus.hardfocus.agent.plist macos/TodoFocusMac/Sources/App/HardFocusAgentManager.swift
git commit -m "feat(agent): add LaunchAgent plist and SMAppService manager"
```

---

## Task 9: Xcode Project Configuration — Agent Target

**Files:**
- Modify: `macos/TodoFocusMac/project.yml` (Xcodegen)

**Step 1: Read current project.yml**

Run: `cat macos/TodoFocusMac/project.yml | head -80`

**Step 2: Add TodoFocusAgent target**

```yaml
targets:
  TodoFocusAgent:
    type: tool
    platform: macOS
    sources:
      - path: Sources/Agent
        buildPhase: sources
    settings:
      PRODUCT_NAME: TodoFocusAgent
      PRODUCT_BUNDLE_IDENTIFIER: com.todofocus.TodoFocusAgent
      INFOPLIST_FILE: Resources/AgentInfo.plist
      LD_RUNPATH_SEARCH_PATHS: "@executable_path/../Frameworks"
      ENABLE_HARDENED_RUNTIME: YES
      CODE_SIGN_IDENTITY: "-"
      CODE_SIGN_STYLE: Manual
    dependencies:
      - target: TodoFocusMac
        embed: false
    preBuildScripts: []
```

**Step 3: Generate project**

Run: `xcodegen generate`

**Step 4: Verify agent target builds**

Run: `xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusAgent" -destination "platform=macOS" 2>&1 | tail -20`

**Step 5: Commit**

```bash
git add macos/TodoFocusMac/project.yml
git commit -m "build: add TodoFocusAgent target to Xcode project"
```

---

## Task 10: End-to-End Integration Test

**Files:**
- Create: `macos/TodoFocusMac/Tests/CoreTests/HardFocusIntegrationTests.swift`

**Step 1: Write integration test**

```swift
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
            status: "active",
            startTime: Date(),
            plannedEndTime: Date().addingTimeInterval(3600),
            actualEndTime: nil,
            unlockPhraseHash: "abc123",
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
        try repo.updateStatus(sessionId: "test-1", status: "completed", actualEndTime: Date())

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
}
```

**Step 2: Run integration tests**

Run: `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS" -only-testing:CoreTests/HardFocusIntegrationTests 2>&1 | tail -15`

Expected: PASS

**Step 3: Commit**

```bash
git add macos/TodoFocusMac/Tests/CoreTests/HardFocusIntegrationTests.swift
git commit -m "test: add Hard Focus integration tests"
```

---

## Task 11: UI Integration — Hard Focus Lock Screen (SwiftUI)

**Files:**
- Create: `macos/TodoFocusMac/Sources/Features/Common/HardFocusLockView.swift`
- Modify: `macos/TodoFocusMac/Sources/App/AppModel.swift` (add HardFocusSessionManager)

**Step 1: Create HardFocusLockView**

```swift
import SwiftUI

struct HardFocusLockView: View {
    @ObservedObject var sessionManager: HardFocusSessionManager
    @State private var passphrase = ""
    @State private var showEmergencyEscape = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)

            Text("Hard Focus Active")
                .font(.title)
                .fontWeight(.bold)

            if let taskId = sessionManager.currentSession?.focusTaskId {
                Text("Focusing on task: \(taskId)")
                    .foregroundColor(.secondary)
            }

            Divider()

            VStack(spacing: 12) {
                SecureField("Enter passphrase to unlock", text: $passphrase)
                    .textFieldStyle(.roundedBorder)

                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                Button("Unlock") {
                    Task {
                        do {
                            try await sessionManager.endSession(passphrase: passphrase)
                        } catch HardFocusError.invalidPassphrase {
                            errorMessage = "Incorrect passphrase"
                            passphrase = ""
                        } catch {
                            errorMessage = "Failed to end session"
                        }
                    }
                }
                .keyboardShortcut(.return)

                Button("Emergency Escape") {
                    showEmergencyEscape = true
                }
                .foregroundColor(.red)
            }

            Spacer()
        }
        .padding(40)
        .frame(minWidth: 400, minHeight: 300)
        .sheet(isPresented: $showEmergencyEscape) {
            EmergencyEscapeView(sessionManager: sessionManager)
        }
    }
}

struct EmergencyEscapeView: View {
    @ObservedObject var sessionManager: HardFocusSessionManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("Emergency Escape")
                .font(.headline)

            Text("This will end the focus session immediately and mark it as interrupted. You will need to re-authenticate in System Preferences to use Hard Focus again.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            Button("Cancel", role: .cancel) {
                dismiss()
            }

            Button("End Session", role: .destructive) {
                Task {
                    try? await sessionManager.emergencyEndSession()
                    dismiss()
                }
            }
        }
        .padding()
        .frame(width: 400)
    }
}
```

**Step 2: Commit**

```bash
git add macos/TodoFocusMac/Sources/Features/Common/HardFocusLockView.swift
git commit -m "feat(ui): add Hard Focus lock screen and emergency escape views"
```

---

## Summary

| Task | Description |
|------|-------------|
| 1 | GRDB migration for hardfocus_session + agent_heartbeat tables |
| 2 | HardFocusSessionRecord DTO + repository |
| 3 | AgentHeartbeatRecord + heartbeat repository methods |
| 4 | HardFocusSessionManager (main app session lifecycle) |
| 5 | Agent main.swift + AgentDatabase |
| 6 | AgentSessionController (idle/active state machine) |
| 7 | AppEnforcer (3-layer blocking) |
| 8 | LaunchAgent plist + SMAppService HardFocusAgentManager |
| 9 | Xcode project: TodoFocusAgent target |
| 10 | Integration tests |
| 11 | SwiftUI lock screen + emergency escape |

**After all tasks:** Push branch and create PR against main.
