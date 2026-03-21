import AppKit
import Foundation

struct LaunchExecutionResult: Equatable {
    enum Status: Equatable {
        case launched
        case rejected
        case failed
    }

    let resourceID: String
    let status: Status
}

struct LaunchSummary: Equatable {
    let launchedCount: Int
    let failedCount: Int
    let rejectedCount: Int
    let results: [LaunchExecutionResult]
}

protocol LaunchOpening {
    func open(url: URL) -> Bool
    func openFile(atPath path: String) -> Bool
    func openApplication(atPath path: String) -> Bool
}

struct WorkspaceLauncher: LaunchOpening {
    func open(url: URL) -> Bool {
        NSWorkspace.shared.open(url)
    }

    func openFile(atPath path: String) -> Bool {
        NSWorkspace.shared.openFile(path)
    }

    func openApplication(atPath path: String) -> Bool {
        NSWorkspace.shared.openFile(path)
    }
}

final class LaunchpadService {
    private let opener: LaunchOpening

    init(opener: LaunchOpening = WorkspaceLauncher()) {
        self.opener = opener
    }

    func launchAll(_ resources: [LaunchResource]) -> LaunchSummary {
        var results: [LaunchExecutionResult] = []
        results.reserveCapacity(resources.count)

        var launched = 0
        var failed = 0
        var rejected = 0

        for resource in resources {
            guard case .success(let validResource) = validateLaunchResource(resource) else {
                results.append(LaunchExecutionResult(resourceID: resource.id, status: .rejected))
                rejected += 1
                continue
            }

            let didOpen: Bool
            switch validResource.type {
            case .url:
                guard let url = URL(string: validResource.value) else {
                    results.append(LaunchExecutionResult(resourceID: validResource.id, status: .rejected))
                    rejected += 1
                    continue
                }
                didOpen = opener.open(url: url)
            case .file:
                didOpen = opener.openFile(atPath: validResource.value)
            case .app:
                if validResource.value.hasPrefix("/") {
                    didOpen = opener.openApplication(atPath: validResource.value)
                } else if let url = URL(string: validResource.value) {
                    didOpen = opener.open(url: url)
                } else {
                    didOpen = false
                }
            }

            if didOpen {
                results.append(LaunchExecutionResult(resourceID: validResource.id, status: .launched))
                launched += 1
            } else {
                results.append(LaunchExecutionResult(resourceID: validResource.id, status: .failed))
                failed += 1
            }
        }

        return LaunchSummary(
            launchedCount: launched,
            failedCount: failed,
            rejectedCount: rejected,
            results: results
        )
    }
}
