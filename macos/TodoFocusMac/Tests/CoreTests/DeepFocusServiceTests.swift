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

    func testSessionStartedAtExposedDuringSessionAndClearedAfterEnd() {
        let service = DeepFocusService()

        XCTAssertNil(service.sessionStartedAt)

        service.startSession(blockedApps: [], duration: 25 * 60, focusTaskId: "test-task-id")

        guard let sessionStartedAt = service.sessionStartedAt else {
            return XCTFail("Expected sessionStartedAt while active session exists")
        }
        XCTAssertLessThanOrEqual(abs(sessionStartedAt.timeIntervalSinceNow), 1.0)

        _ = service.endSession()
        XCTAssertNil(service.sessionStartedAt)
    }
}
