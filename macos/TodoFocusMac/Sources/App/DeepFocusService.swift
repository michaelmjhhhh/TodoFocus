import Foundation
import Observation

@Observable
final class DeepFocusService {
    var isActive: Bool = false
    var currentSessionId: String?
    var blockedApps: Set<String> = []
    var distractionAttempts: [String: Int] = [:]

    private var sessionStartTime: Date?

    func startSession(blockedApps: [String]) {
        self.blockedApps = Set(blockedApps)
        self.currentSessionId = UUID().uuidString
        self.sessionStartTime = Date()
        self.isActive = true
        startMonitoring()
    }

    func endSession() -> DeepFocusReport? {
        guard isActive, let sessionId = currentSessionId, let startTime = sessionStartTime else {
            return nil
        }

        let report = DeepFocusReport(
            sessionId: sessionId,
            blockedApps: Array(blockedApps),
            distractionAttempts: distractionAttempts,
            startTime: startTime...Date(),
            completed: true
        )

        reset()
        return report
    }

    func recordDistraction(appBundleId: String) {
        guard isActive else { return }
        distractionAttempts[appBundleId, default: 0] += 1
    }

    private func startMonitoring() {
    }

    private func stopMonitoring() {
    }

    private func reset() {
        isActive = false
        currentSessionId = nil
        blockedApps = []
        distractionAttempts = [:]
        sessionStartTime = nil
    }
}

struct DeepFocusReport {
    let sessionId: String
    let blockedApps: [String]
    let distractionAttempts: [String: Int]
    let startTime: ClosedRange<Date>
    let completed: Bool

    var totalDistractionAttempts: Int {
        distractionAttempts.values.reduce(0, +)
    }
}
