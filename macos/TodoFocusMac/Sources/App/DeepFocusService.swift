import Foundation
import AppKit
import Observation
import Combine

struct DeepFocusStats: Codable {
    var totalFocusTime: TimeInterval = 0
    var sessionCount: Int = 0
    var distractionCount: Int = 0

    static let key = "deepFocusStats"

    static func load() -> DeepFocusStats {
        guard let data = UserDefaults.standard.data(forKey: key),
              let stats = try? JSONDecoder().decode(DeepFocusStats.self, from: data)
        else { return DeepFocusStats() }
        return stats
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: DeepFocusStats.key)
        }
    }
}

@Observable
@MainActor
final class DeepFocusService {
    private var stats: DeepFocusStats = DeepFocusStats()
    var isActive: Bool = false
    var lastReport: DeepFocusReport?
    var currentSessionId: String?
    var currentFocusTaskId: String?
    var blockedApps: Set<String> = []
    var distractionAttempts: [String: Int] = [:]
    var distractionAppNames: [String: String] = [:]
    var onEndFocusSession: ((DeepFocusReport?) -> Void)?

    private var sessionStartTime: Date?
    private var overlayWindow: NSWindow?
    private var appMonitor: NSObjectProtocol?
    private var timerCancellable: AnyCancellable?
    @ObservationIgnored private var timerNotifier = DeepFocusTimerNotifier()
    private var onTimerComplete: (() -> Void)?

    func startSession(blockedApps: [String], duration: TimeInterval?, focusTaskId: String, onTimerComplete: (() -> Void)? = nil) {
        // End any existing session first
        if isActive {
            _ = endSession()
        }

        self.blockedApps = Set(blockedApps)
        self.currentFocusTaskId = focusTaskId
        self.currentSessionId = UUID().uuidString
        self.sessionStartTime = Date()
        self.isActive = true
        self.onTimerComplete = onTimerComplete

        // Request notification permission if we have a duration
        if let duration, duration > 0 {
            Task {
                _ = await timerNotifier.requestAuthorization()
            }
            startTimer(duration: duration)
        }

        startMonitoring()
    }

    private func startTimer(duration: TimeInterval) {
        timerCancellable = Timer.publish(every: duration, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.handleTimerComplete()
            }
    }

    private func handleTimerComplete() {
        timerCancellable?.cancel()
        timerCancellable = nil

        guard let report = endSession() else { return }

        // Show notification
        timerNotifier.notifySessionComplete(report: report)

        // Mark task complete
        onTimerComplete?()

        // Show report (handled by onEndFocusSession callback in UI)
    }

    func endSession() -> DeepFocusReport? {
        timerCancellable?.cancel()
        timerCancellable = nil

        guard isActive, let sessionId = currentSessionId, let startTime = sessionStartTime else {
            return nil
        }

        let duration = Date().timeIntervalSince(startTime)
        let sessionDistractionCount = distractionAttempts.values.reduce(0, +)
        stats.totalFocusTime += duration
        stats.sessionCount += 1
        stats.distractionCount += sessionDistractionCount
        stats.save()

        let report = DeepFocusReport(
            duration: duration,
            distractionCount: sessionDistractionCount,
            blockedApps: Array(blockedApps),
            focusTaskTitle: nil,
            stats: stats,
            focusTaskId: currentFocusTaskId
        )
        lastReport = report

        hideOverlay()
        reset()
        onEndFocusSession?(report)
        return report
    }

    func recordDistraction(appBundleId: String, appName: String) {
        guard isActive else { return }
        distractionAttempts[appBundleId, default: 0] += 1
        distractionAppNames[appBundleId] = appName
    }

    private func startMonitoring() {
        let workspace = NSWorkspace.shared
        let notificationCenter = workspace.notificationCenter

        appMonitor = notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  let bundleId = app.bundleIdentifier else { return }
            Task { @MainActor in
                self.handleAppActivationForApp(app: app, bundleId: bundleId)
            }
        }
    }

    private var lastShownOverlayBundleId: String?
    private var lastShownOverlayTime: Date?

    private func handleAppActivationForApp(app: NSRunningApplication, bundleId: String) {
        guard isActive else { return }

        if blockedApps.contains(bundleId) {
            let now = Date()
            let shouldShowOverlay: Bool
            if lastShownOverlayBundleId == bundleId,
               let lastTime = lastShownOverlayTime,
               now.timeIntervalSince(lastTime) < 3 {
                shouldShowOverlay = false
            } else {
                shouldShowOverlay = true
                lastShownOverlayBundleId = bundleId
                lastShownOverlayTime = now
            }
            recordDistraction(appBundleId: bundleId, appName: app.localizedName ?? bundleId)
            if shouldShowOverlay {
                showOverlay(for: app.localizedName ?? bundleId, bundleId: bundleId)
            }
        }
    }

    private func stopMonitoring() {
        if let monitor = appMonitor {
            NSWorkspace.shared.notificationCenter.removeObserver(monitor)
            appMonitor = nil
        }
    }

    private func showOverlay(for appName: String, bundleId: String) {
        hideOverlay()

        let count = distractionAttempts[bundleId] ?? 0
        let message = "Focus Mode: \(appName) blocked\nDistractions: \(count)"

        let overlay = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 80),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        overlay.level = .floating
        overlay.backgroundColor = NSColor.black.withAlphaComponent(0.85)
        overlay.isOpaque = false
        overlay.hasShadow = true
        overlay.ignoresMouseEvents = true
        overlay.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let label = NSTextField(labelWithString: message)
        label.alignment = .center
        label.textColor = .white
        label.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        label.frame = NSRect(x: 20, y: 20, width: 260, height: 40)

        let container = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 80))
        container.addSubview(label)
        overlay.contentView = container

        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - 150
            let y = screenFrame.maxY - 120
            overlay.setFrameOrigin(NSPoint(x: x, y: y))
        }

        overlay.orderFront(nil)
        overlayWindow = overlay

        let windowToHide = overlay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            windowToHide.orderOut(nil)
            if self?.overlayWindow === windowToHide {
                self?.overlayWindow = nil
            }
        }
    }

    private func hideOverlay() {
        overlayWindow?.orderOut(nil)
        overlayWindow = nil
    }

    private func reset() {
        isActive = false
        currentSessionId = nil
        currentFocusTaskId = nil
        blockedApps = []
        distractionAttempts = [:]
        distractionAppNames = [:]
        sessionStartTime = nil
        lastShownOverlayBundleId = nil
        lastShownOverlayTime = nil
        stopMonitoring()
    }
}

struct DeepFocusReport {
    let duration: TimeInterval
    let distractionCount: Int
    let blockedApps: [String]
    let focusTaskTitle: String?
    let stats: DeepFocusStats
    let focusTaskId: String?
}
