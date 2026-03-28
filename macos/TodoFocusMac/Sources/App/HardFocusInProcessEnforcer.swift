import Foundation
import AppKit

@MainActor
protocol HardFocusInProcessEnforcing {
    func start(blockedApps: [String])
    func stop()
}

@MainActor
final class HardFocusInProcessEnforcer: HardFocusInProcessEnforcing {
    private var launchObserver: NSObjectProtocol?
    private var activationObserver: NSObjectProtocol?
    private var blockedApps: Set<String> = []

    func start(blockedApps: [String]) {
        self.blockedApps = Set(blockedApps)

        // Initial sweep: terminate already-running blocked apps.
        for app in NSWorkspace.shared.runningApplications {
            guard let bundleId = app.bundleIdentifier,
                  self.blockedApps.contains(bundleId),
                  bundleId != Bundle.main.bundleIdentifier else { continue }
            terminate(app)
        }

        let center = NSWorkspace.shared.notificationCenter

        launchObserver = center.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
            Task { @MainActor [weak self] in
                self?.handle(app: app)
            }
        }

        activationObserver = center.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
            Task { @MainActor [weak self] in
                self?.handle(app: app)
            }
        }
    }

    func stop() {
        if let launchObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(launchObserver)
            self.launchObserver = nil
        }
        if let activationObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(activationObserver)
            self.activationObserver = nil
        }
        blockedApps = []
    }

    private func handle(app: NSRunningApplication) {
        guard let bundleId = app.bundleIdentifier,
              bundleId != Bundle.main.bundleIdentifier,
              blockedApps.contains(bundleId) else { return }
        terminate(app)
    }

    private func terminate(_ app: NSRunningApplication) {
        let terminated = app.terminate()
        if !terminated {
            app.forceTerminate()
        }
    }
}
