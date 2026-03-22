import Foundation
import AppKit
import Observation

@Observable
@MainActor
final class DeepFocusService {
    var isActive: Bool = false
    var currentSessionId: String?
    var blockedApps: Set<String> = []
    var distractionAttempts: [String: Int] = [:]
    var distractionAppNames: [String: String] = [:]
    var onEndFocusSession: ((DeepFocusReport?) -> Void)?

    private var sessionStartTime: Date?
    private var overlayWindow: NSWindow?
    private var appMonitor: NSObjectProtocol?

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
            distractionAppNames: distractionAppNames,
            startTime: startTime...Date(),
            completed: true
        )

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
    let sessionId: String
    let blockedApps: [String]
    let distractionAttempts: [String: Int]
    let distractionAppNames: [String: String]
    let startTime: ClosedRange<Date>
    let completed: Bool
    
    var totalDistractionAttempts: Int {
        distractionAttempts.values.reduce(0, +)
    }
}