import Foundation
import AppKit

enum AgentState: Sendable {
    case idle
    case active(session: HardFocusSessionRecord)
}

final class AgentSessionController: @unchecked Sendable {
    private let db: AgentDatabase
    private let enforcer: AppEnforcer
    private var state: AgentState = .idle
    private nonisolated(unsafe) var idleTimer: Timer?
    private nonisolated(unsafe) var activeTimer: Timer?
    private nonisolated(unsafe) var heartbeatTimer: Timer?
    private let lock = NSLock()

    init() {
        do {
            self.db = try AgentDatabase()
        } catch {
            print("AgentDatabase failed: \(error). Exiting.")
            exit(1)
        }
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
        lock.lock()
        defer { lock.unlock() }
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
        lock.lock()
        state = .active(session: session)
        idleTimer?.invalidate()
        idleTimer = nil
        lock.unlock()

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
        lock.lock()
        let currentState = state
        lock.unlock()

        guard case .active(let session) = currentState else { return }

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
                // Beyond grace — main app timer should have fired; log only
                print("Session past grace period, waiting for main app to end")
            }
        }
    }

    private func deactivateSession() {
        enforcer.stopObserving()
        activeTimer?.invalidate()
        activeTimer = nil
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil

        lock.lock()
        state = .idle
        lock.unlock()

        startIdleLoop()
    }

    private func writeHeartbeat() {
        let sessionId: String?
        lock.lock()
        if case .active(let session) = state {
            sessionId = session.sessionId
        } else {
            sessionId = nil
        }
        lock.unlock()

        do {
            try db.writeHeartbeat(sessionId: sessionId)
        } catch {
            print("Heartbeat failed: \(error)")
        }
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
        // DistributedNotificationCenter delivers on a system thread; dispatch to main for thread safety
        DispatchQueue.main.async { [weak self] in
            self?.checkForActiveSession()
        }
    }

    deinit {
        // Timer.invalidate() and removeObserver are thread-safe
        idleTimer?.invalidate()
        activeTimer?.invalidate()
        heartbeatTimer?.invalidate()
        DistributedNotificationCenter.default().removeObserver(self)
    }
}
