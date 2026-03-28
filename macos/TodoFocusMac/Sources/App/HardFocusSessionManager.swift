import Foundation
import AppKit
import CryptoKit

enum HardFocusError: Error, Equatable {
    case accessibilityPermissionDenied
    case agentNotAvailable
    case noActiveSession
    case invalidPassphrase
    case encodingFailed
}

@MainActor
final class HardFocusSessionManager: ObservableObject {
    @Published private(set) var currentSession: HardFocusSessionRecord?
    @Published private(set) var isEnforcing = false

    private let repository: HardFocusSessionRepository
    private let agentManager: HardFocusAgentControlling
    private let isAccessibilityTrusted: () -> Bool
    private let agentStartupTimeout: TimeInterval
    private let agentPollInterval: TimeInterval
    private var timer: Timer?

    init(
        repository: HardFocusSessionRepository,
        agentManager: HardFocusAgentControlling = HardFocusAgentManager(),
        isAccessibilityTrusted: @escaping () -> Bool = { AXIsProcessTrusted() },
        agentStartupTimeout: TimeInterval = 2.0,
        agentPollInterval: TimeInterval = 0.1
    ) {
        self.repository = repository
        self.agentManager = agentManager
        self.isAccessibilityTrusted = isAccessibilityTrusted
        self.agentStartupTimeout = agentStartupTimeout
        self.agentPollInterval = agentPollInterval
        // Restore active session from persisted state after app relaunch/crash
        if let active = try? repository.activeSession() {
            // Reschedule timer from the persisted plannedEndTime (original duration may have partially elapsed)
            let remaining = active.plannedEndTime.timeIntervalSinceNow
            if active.plannedEndTime == .distantFuture || remaining > 0 {
                self.currentSession = active
                self.isEnforcing = true
                if remaining > 0 {
                    startTimer(duration: remaining)
                }
            } else {
                // Timed session already expired while app was not running.
                // Close it immediately so startup doesn't get stuck in a stale lock state.
                try? repository.updateStatus(
                    sessionId: active.sessionId,
                    status: .completed,
                    actualEndTime: Date()
                )
                self.currentSession = nil
                self.isEnforcing = false
            }
        }
    }

    // MARK: - Public API

    func canStartSession() -> Bool {
        return isAccessibilityTrusted()
    }

    func startSession(
        blockedApps: [String],
        duration: TimeInterval?,
        focusTaskId: String?,
        passphrase: String
    ) async throws {
        guard isAccessibilityTrusted() else {
            throw HardFocusError.accessibilityPermissionDenied
        }

        try await ensureAgentIsRunning()

        // Prevent creating a second active session if one is already running
        if (try? repository.activeSession()) != nil {
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
        guard let blockedAppsString = String(data: blockedAppsJson, encoding: .utf8) else {
            throw HardFocusError.encodingFailed
        }

        let session = HardFocusSessionRecord(
            sessionId: UUID().uuidString,
            mode: "hard",
            status: .active,
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

        // Notify agent to start enforcing immediately (agent polls as fallback)
        DistributedNotificationCenter.default().postNotificationName(
            NSNotification.Name("com.todofocus.hardfocus.session.changed"),
            object: nil,
            userInfo: nil,
            deliverImmediately: true
        )

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

        try await endSessionInternal(status: .completed)
    }

    func emergencyEndSession() async throws {
        guard let session = currentSession else {
            throw HardFocusError.noActiveSession
        }

        try repository.updateStatus(
            sessionId: session.sessionId,
            status: .interrupted,
            actualEndTime: Date()
        )

        currentSession = nil
        isEnforcing = false
        timer?.invalidate()
    }

    // MARK: - Private

    private func ensureAgentIsRunning() async throws {
        if !agentManager.isRegistered {
            try agentManager.register()
        }

        if agentManager.isRunning {
            return
        }

        let deadline = Date().addingTimeInterval(agentStartupTimeout)
        while Date() < deadline {
            try await Task.sleep(nanoseconds: UInt64(agentPollInterval * 1_000_000_000))
            if agentManager.isRunning {
                return
            }
        }

        throw HardFocusError.agentNotAvailable
    }

    private func endSessionInternal(status: HardFocusStatus) async throws {
        guard let session = currentSession else {
            throw HardFocusError.noActiveSession
        }

        try repository.updateStatus(
            sessionId: session.sessionId,
            status: status,
            actualEndTime: Date()
        )

        currentSession = nil
        isEnforcing = false
        timer?.invalidate()
    }

    private func startTimer(duration: TimeInterval) {
        timer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            Task { @MainActor in
                // Timer expiry = end without passphrase requirement
                try? await self?.endSessionInternal(status: .completed)
            }
        }
    }

    private func hashPassphrase(_ phrase: String) -> String {
        // SHA256 as a placeholder - full Argon2 requires third-party library
        let data = Data(phrase.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    private func verifyPassphrase(_ phrase: String, hash: String) -> Bool {
        return hashPassphrase(phrase) == hash
    }
}
