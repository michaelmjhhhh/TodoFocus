import Foundation
import XCTest
@testable import TodoFocusMac

final class QuickAddNaturalLanguageParserTests: XCTestCase {
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        return cal
    }

    func testParsesFlagsListDateAndTimeAndStripsTokensFromTitle() throws {
        let now = Date(timeIntervalSince1970: 1_763_520_000) // 2025-11-03T00:00:00Z
        let parsed = QuickAddNaturalLanguageParser.parse(
            "ship desktop #Work ! @myday tomorrow 9:30am",
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(parsed.title, "ship desktop")
        XCTAssertEqual(parsed.listName, "Work")
        XCTAssertTrue(parsed.isImportant)
        XCTAssertTrue(parsed.isMyDay)
        XCTAssertNotNil(parsed.dueDate)

        let due = try XCTUnwrap(parsed.dueDate)
        let expectedDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))
        let dueDay = calendar.startOfDay(for: due)
        XCTAssertEqual(dueDay, expectedDay)
        let components = calendar.dateComponents([.hour, .minute], from: due)
        XCTAssertEqual(components.hour, 9)
        XCTAssertEqual(components.minute, 30)
    }

    func testTimeOnlySchedulesTomorrowWhenTimeAlreadyPassed() throws {
        let now = Date(timeIntervalSince1970: 1_763_552_400) // 2025-11-03T09:00:00Z
        let parsed = QuickAddNaturalLanguageParser.parse(
            "write report 8:00",
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(parsed.title, "write report")
        let due = try XCTUnwrap(parsed.dueDate)
        let expectedDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))
        XCTAssertEqual(calendar.startOfDay(for: due), expectedDay)
        let components = calendar.dateComponents([.hour, .minute], from: due)
        XCTAssertEqual(components.hour, 8)
        XCTAssertEqual(components.minute, 0)
    }

    func testNoTokensKeepsTitleAndNoMetadata() {
        let now = Date(timeIntervalSince1970: 1_763_520_000)
        let parsed = QuickAddNaturalLanguageParser.parse(
            "plain task title",
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(parsed.title, "plain task title")
        XCTAssertFalse(parsed.isImportant)
        XCTAssertFalse(parsed.isMyDay)
        XCTAssertNil(parsed.listName)
        XCTAssertNil(parsed.dueDate)
    }
}
