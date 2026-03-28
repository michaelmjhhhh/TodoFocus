import Foundation
import ServiceManagement

enum HardFocusAgentError: Error {
    case registrationFailed
    case unregistrationFailed
}

protocol HardFocusAgentControlling {
    func register() throws
    var isRegistered: Bool { get }
    var isRunning: Bool { get }
}

final class HardFocusAgentManager {
    private let service: SMAppService

    init() {
        // Note: plist must be present in ~/Library/LaunchAgents
        // SMAppService.agent(plistName:) references it by name
        self.service = SMAppService.agent(plistName: "com.todofocus.hardfocus.agent")
    }

    /// Register the agent with launchd (one-time install)
    func register() throws {
        try service.register()
    }

    /// Unregister the agent from launchd
    func unregister() throws {
        try service.unregister()
    }

    /// Whether the agent is registered (enabled or requires user approval)
    var isRegistered: Bool {
        service.status == .enabled || service.status == .requiresApproval
    }

    /// Whether the agent is actively running and enforcing
    var isRunning: Bool {
        service.status == .enabled
    }
}

extension HardFocusAgentManager: HardFocusAgentControlling {}
