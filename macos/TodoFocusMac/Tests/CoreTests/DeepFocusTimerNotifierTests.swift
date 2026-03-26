import XCTest
@testable import TodoFocusMac

final class DeepFocusTimerNotifierTests: XCTestCase {
    func testNotificationContent() async {
        let notifier = DeepFocusTimerNotifier()
        let report = DeepFocusReport(
            duration: 1500, // 25 minutes
            distractionCount: 3,
            blockedApps: ["com.apple.MobileSMS"],
            focusTaskTitle: "Test Task",
            stats: DeepFocusStats(),
            focusTaskId: "test-id"
        )
        // Verify notifier can format notification content
        let content = notifier.formatNotificationContent(from: report)
        XCTAssertTrue(content.contains("25"))
        XCTAssertTrue(content.contains("3"))
    }
}
