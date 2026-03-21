import XCTest
@testable import TodoFocusMac

final class AppModelTests: XCTestCase {
    func testDefaultDetailPanelWidth() {
        let model = AppModel()
        XCTAssertEqual(model.detailPanelWidth, 360)
    }
}
