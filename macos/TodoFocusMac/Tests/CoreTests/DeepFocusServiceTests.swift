import XCTest
@testable import TodoFocusMac

@MainActor
final class DeepFocusServiceTests: XCTestCase {
    func testStatsAccumulation() {
        let service = DeepFocusService()
        
        service.startSession(blockedApps: [], duration: nil, focusTaskId: "test-task-id")
        let report = service.endSession()
        
        XCTAssertEqual(report?.stats.sessionCount, 1)
        XCTAssertGreaterThan(report?.stats.totalFocusTime ?? 0, 0)
    }
    
    func testDistractionTracking() {
        let service = DeepFocusService()
        
        service.startSession(blockedApps: [], duration: nil, focusTaskId: "test-task-id")
        service.recordDistraction(appBundleId: "com.apple.Safari", appName: "Safari")
        service.recordDistraction(appBundleId: "com.apple.Safari", appName: "Safari")
        service.recordDistraction(appBundleId: "com.apple.Mail", appName: "Mail")
        let report = service.endSession()
        
        XCTAssertEqual(report?.stats.distractionCount, 3)
    }
}
