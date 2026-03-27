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
            status: .completed,
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
            status: .interrupted,
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
                // Timer expiry = end without passphrase requirement
                guard let session = self?.currentSession else { return }
                try? self?.repository.updateStatus(
                    sessionId: session.sessionId,
                    status: .completed,
                    actualEndTime: Date()
                )
                self?.currentSession = nil
                self?.isEnforcing = false
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
