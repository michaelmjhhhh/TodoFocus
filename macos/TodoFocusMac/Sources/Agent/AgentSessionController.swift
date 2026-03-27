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
