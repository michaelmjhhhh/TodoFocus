import XCTest
@testable import TodoFocusMac

final class WindowPersistenceTests: XCTestCase {
    func testClampDetailWidthRespectsMinAndMaxBounds() {
        XCTAssertEqual(WindowPersistence.clampDetailWidth(100, windowWidth: 1200), 340)
        XCTAssertEqual(WindowPersistence.clampDetailWidth(900, windowWidth: 1200), 740)
        XCTAssertEqual(WindowPersistence.clampDetailWidth(500, windowWidth: 1200), 500)
    }

    func testClampDetailWidthHonorsHardMax760() {
        XCTAssertEqual(WindowPersistence.clampDetailWidth(800, windowWidth: 2000), 760)
    }
}
