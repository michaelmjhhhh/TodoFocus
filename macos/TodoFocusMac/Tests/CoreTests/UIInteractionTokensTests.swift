import XCTest
@testable import TodoFocusMac

final class UIInteractionTokensTests: XCTestCase {
    func testMotionDurationsStayInExpectedRanges() {
        XCTAssertTrue((0.12...0.20).contains(MotionTokens.quickDuration))
        XCTAssertTrue((0.16...0.24).contains(MotionTokens.standardDuration))
        XCTAssertTrue((0.22...0.32).contains(MotionTokens.emphasisDuration))
    }

    func testVisualTokensExposeSemanticAccents() {
        _ = VisualTokens.violetAccent
        _ = VisualTokens.cyanAccent
        _ = VisualTokens.roseAccent
        _ = VisualTokens.accent
        XCTAssertTrue(true)
    }
}
