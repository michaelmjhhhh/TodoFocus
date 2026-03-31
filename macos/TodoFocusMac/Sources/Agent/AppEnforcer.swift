import Foundation
import AppKit

final class AppEnforcer: @unchecked Sendable {
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
              bundleId != Bundle.main.bundleIdentifier,
              blockedApps.contains(bundleId) else { return }
        terminateApp(app)
    }

    private func handleAppActivation(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              let bundleId = app.bundleIdentifier,
              bundleId != Bundle.main.bundleIdentifier,
              blockedApps.contains(bundleId) else { return }
        // Activation means it stole focus — kill it
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
        // Our sandboxed process can't SIGKILL apps owned by other users
    }
}
