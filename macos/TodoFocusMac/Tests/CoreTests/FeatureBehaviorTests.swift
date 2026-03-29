import Foundation
import XCTest
@testable import TodoFocusMac

@MainActor
final class FeatureBehaviorTests: XCTestCase {
    func testSelectingSidebarClearsSelectedTask() {
        let model = AppModel()
        model.selectedTodoID = "todo-1"

        model.selectSidebar(.important)

        XCTAssertNil(model.selectedTodoID)
    }

    func testDetailPanelWidthPersistenceClampBehavior() {
        let model = AppModel()

        model.updateDetailPanelWidth(100, windowWidth: 1200)
        XCTAssertEqual(model.detailPanelWidth, 340)

        model.updateDetailPanelWidth(800, windowWidth: 1200)
        XCTAssertEqual(model.detailPanelWidth, 740)
    }

    func testLaunchAllSummaryTextWhenMixedOutcome() {
        let summary = LaunchSummary(launchedCount: 2, failedCount: 1, rejectedCount: 0, results: [])
        let text = launchSummaryText(summary)
        XCTAssertEqual(text, "Launched 2. 1 failed")
    }

    private func launchSummaryText(_ summary: LaunchSummary) -> String {
        if summary.results.isEmpty {
            return summary.failedCount + summary.rejectedCount == 0 ? "No resources" : "Launched \(summary.launchedCount). \(summary.failedCount + summary.rejectedCount) failed"
        }
        if summary.failedCount == 0, summary.rejectedCount == 0 {
            return "Launched \(summary.launchedCount)"
        }
        return "Launched \(summary.launchedCount). \(summary.failedCount + summary.rejectedCount) failed"
    }
}
