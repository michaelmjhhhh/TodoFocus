import XCTest
@testable import TodoFocusMac

@MainActor
final class DeepFocusServiceTests: XCTestCase {
    func testStatsAccumulation() {
        let service = DeepFocusService()
        
        service.startSession(blockedApps: [], focusTaskId: "test-task-id")
        service.endSession()
        
        XCTAssertEqual(service.stats.sessionCount, 1)
        XCTAssertGreaterThan(service.stats.totalFocusTime, 0)
    }
    
    func testDistractionTracking() {
        let service = DeepFocusService()
        
        service.startSession(blockedApps: [], focusTaskId: "test-task-id")
        service.recordDistraction(appBundleId: "com.apple.Safari", appName: "Safari")
        service.recordDistraction(appBundleId: "com.apple.Safari", appName: "Safari")
        service.recordDistraction(appBundleId: "com.apple.Mail", appName: "Mail")
        service.endSession()
        
        XCTAssertEqual(service.stats.distractionCount, 3)
    }
}
