import Foundation
import AppKit
import CryptoKit

enum HardFocusError: Error {
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
