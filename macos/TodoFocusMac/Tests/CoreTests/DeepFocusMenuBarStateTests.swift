import XCTest
@testable import TodoFocusMac

final class DeepFocusMenuBarStateTests: XCTestCase {
    func testFromInactiveReturnsInactiveCopy() {
        let now = Date(timeIntervalSince1970: 1_000)

        let state = DeepFocusMenuBarState.from(
            isActive: false,
            sessionDuration: nil,
            sessionStartedAt: nil,
            now: now
        )

        XCTAssertEqual(state.title, "Deep Focus")
        XCTAssertEqual(state.subtitle, "Not active")
        XCTAssertNil(state.menuBarBadge)
        XCTAssertFalse(state.isActive)
    }

    func testFromTimedSessionShowsRemainingMinutes() {
        let sessionStartedAt = Date(timeIntervalSince1970: 1_000)
        let now = Date(timeIntervalSince1970: 1_600)

        let state = DeepFocusMenuBarState.from(
            isActive: true,
            sessionDuration: 25 * 60,
            sessionStartedAt: sessionStartedAt,
            now: now
        )

        XCTAssertEqual(state.subtitle, "15m remaining")
        XCTAssertEqual(state.menuBarBadge, "15m")
        XCTAssertTrue(state.isActive)
    }

    func testFromTimedSessionClampsRemainingMinutesToZero() {
        let sessionStartedAt = Date(timeIntervalSince1970: 1_000)
        let now = Date(timeIntervalSince1970: 2_600)

        let state = DeepFocusMenuBarState.from(
            isActive: true,
            sessionDuration: 25 * 60,
            sessionStartedAt: sessionStartedAt,
            now: now
        )

        XCTAssertEqual(state.subtitle, "0m remaining")
        XCTAssertEqual(state.menuBarBadge, "0m")
        XCTAssertTrue(state.isActive)
    }

    func testFromTimedSessionDoesNotExceedConfiguredMinutesWhenNowSlightlyBeforeStart() {
        let sessionStartedAt = Date(timeIntervalSince1970: 1_000)
        let now = Date(timeIntervalSince1970: 999.7)

        let state = DeepFocusMenuBarState.from(
            isActive: true,
            sessionDuration: 25 * 60,
            sessionStartedAt: sessionStartedAt,
            now: now
        )

        XCTAssertEqual(state.menuBarBadge, "25m")
        XCTAssertEqual(state.subtitle, "25m remaining")
    }
}
