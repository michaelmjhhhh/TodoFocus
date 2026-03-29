import Foundation

struct DeepFocusMenuBarState: Equatable {
    let title: String
    let subtitle: String
    let menuBarBadge: String?
    let isActive: Bool

    static func from(
        isActive: Bool,
        sessionDuration: TimeInterval?,
        sessionStartedAt: Date?,
        now: Date = .now
    ) -> DeepFocusMenuBarState {
        guard isActive else {
            return DeepFocusMenuBarState(
                title: "Deep Focus",
                subtitle: "Not active",
                menuBarBadge: nil,
                isActive: false
            )
        }

        if let sessionDuration, let sessionStartedAt {
            let elapsed = now.timeIntervalSince(sessionStartedAt)
            let remainingSeconds = max(0, sessionDuration - elapsed)
            let remainingMinutes = Int(ceil(remainingSeconds / 60.0))
            let remaining = "\(remainingMinutes)m"

            return DeepFocusMenuBarState(
                title: "Deep Focus",
                subtitle: "\(remaining) remaining",
                menuBarBadge: remaining,
                isActive: true
            )
        }

        return DeepFocusMenuBarState(
            title: "Deep Focus",
            subtitle: "Active",
            menuBarBadge: nil,
            isActive: true
        )
    }

    @MainActor
    static func from(service: DeepFocusService, now: Date = .now) -> DeepFocusMenuBarState {
        from(
            isActive: service.isActive,
            sessionDuration: service.sessionDuration,
            sessionStartedAt: service.sessionStartedAt,
            now: now
        )
    }
}
