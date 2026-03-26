import Foundation
import UserNotifications

final class DeepFocusTimerNotifier: @unchecked Sendable {
    private let notificationCenter = UNUserNotificationCenter.current()
    private let categoryIdentifier = "DEEP_FOCUS_COMPLETE"

    init() {
        setupNotificationCategory()
    }

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound])
            return granted
        } catch {
            return false
        }
    }

    func notifySessionComplete(report: DeepFocusReport) {
        let content = UNMutableNotificationContent()
        content.title = "Focus Session Complete"
        content.body = formatNotificationContent(from: report)
        content.sound = .default
        content.categoryIdentifier = categoryIdentifier

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Fire immediately
        )

        notificationCenter.add(request) { error in
            if let error {
                print("Failed to deliver notification: \(error)")
            }
        }
    }

    func formatNotificationContent(from report: DeepFocusReport) -> String {
        let minutes = Int(report.duration / 60)
        let minutesText = minutes == 1 ? "minute" : "minutes"
        let distractionText = report.distractionCount == 1 ? "distraction" : "distractions"
        return "You focused for \(minutes) \(minutesText). \(report.distractionCount) \(distractionText)."
    }

    private func setupNotificationCategory() {
        let category = UNNotificationCategory(
            identifier: categoryIdentifier,
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        notificationCenter.setNotificationCategories([category])
    }
}
