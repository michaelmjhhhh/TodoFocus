import XCTest
@testable import TodoFocusMac

final class DeepFocusServiceTests: XCTestCase {
    func testStatsAccumulation() {
        let service = DeepFocusService()
        
        service.startSession(blockedApps: [], focusTaskId: nil)
        service.endSession()
        
        XCTAssertEqual(service.stats.sessionCount, 1)
        XCTAssertGreaterThan(service.stats.totalFocusTime, 0)
    }
    
    func testInterruptionTracking() {
        let service = DeepFocusService()
        
        service.startSession(blockedApps: [], focusTaskId: nil)
        service.recordInterruption()
        service.recordInterruption()
        service.endSession()
        
        XCTAssertEqual(service.stats.interruptionCount, 2)
    }
}
