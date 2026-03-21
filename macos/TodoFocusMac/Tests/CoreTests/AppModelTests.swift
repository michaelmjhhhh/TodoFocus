import XCTest
@testable import TodoFocusMac

final class AppModelTests: XCTestCase {
    func testDefaultDetailPanelWidth() {
        UserDefaults.standard.removeObject(forKey: WindowPersistence.detailWidthKey)
        let model = AppModel()
        XCTAssertEqual(model.detailPanelWidth, 380)
    }
}
