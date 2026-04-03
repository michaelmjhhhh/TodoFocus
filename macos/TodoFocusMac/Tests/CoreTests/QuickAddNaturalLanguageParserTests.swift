import Foundation
import XCTest
@testable import TodoFocusMac

final class QuickAddNaturalLanguageParserTests: XCTestCase {
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        return cal
    }

    func testParsesFlagsAndDateAndStripsTokensFromTitle() throws {
        let now = Date(timeIntervalSince1970: 1_763_520_000) // 2025-11-03T00:00:00Z
        let parsed = QuickAddNaturalLanguageParser.parse(
            "ship desktop ! @myday tomorrow",
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(parsed.title, "ship desktop")
        XCTAssertTrue(parsed.isImportant)
        XCTAssertTrue(parsed.isMyDay)
        XCTAssertNotNil(parsed.dueDate)

        let due = try XCTUnwrap(parsed.dueDate)
        let expectedDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))
        let dueDay = calendar.startOfDay(for: due)
        XCTAssertEqual(dueDay, expectedDay)
        let components = calendar.dateComponents([.hour, .minute], from: due)
        XCTAssertEqual(components.hour, 0)
        XCTAssertEqual(components.minute, 0)
    }

    func testTimeTokenIsNotParsedAsDueDate() throws {
        let now = Date(timeIntervalSince1970: 1_763_552_400) // 2025-11-03T09:00:00Z
        let parsed = QuickAddNaturalLanguageParser.parse(
            "write report 8:00",
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(parsed.title, "write report 8:00")
        XCTAssertNil(parsed.dueDate)
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
        XCTAssertNil(parsed.dueDate)
    }

    func testHighlightedTokenRangesMatchRecognizedTokens() {
        let now = Date(timeIntervalSince1970: 1_763_520_000)
        let input = "ship #Work ! @myday tomorrow 9:30am !high"
        let ranges = QuickAddNaturalLanguageParser.highlightedTokenRanges(in: input, now: now, calendar: calendar)
        let tokens = ranges.map { String(input[$0]) }

        XCTAssertEqual(tokens, ["!", "@myday", "tomorrow"])
    }

    func testHighlightedTokenRangesIncludeNextWeekPair() {
        let now = Date(timeIntervalSince1970: 1_763_520_000)
        let input = "prepare next week plan"
        let ranges = QuickAddNaturalLanguageParser.highlightedTokenRanges(in: input, now: now, calendar: calendar)
        let tokens = ranges.map { String(input[$0]) }

        XCTAssertEqual(tokens, ["next", "week"])
    }

    func testHighlightedTokenRangesHandlePunctuationAndWhitespace() {
        let now = Date(timeIntervalSince1970: 1_763_520_000)
        let input = " \ttomorrow,\n#Work)\t!high  tomorrow: 9:30am:"
        let ranges = QuickAddNaturalLanguageParser.highlightedTokenRanges(in: input, now: now, calendar: calendar)
        let tokens = ranges.map { String(input[$0]) }

        XCTAssertEqual(tokens, ["tomorrow,", "tomorrow:"])
    }

    func testHighlightedTokenRangesHandleUnicodeGraphemes() {
        let now = Date(timeIntervalSince1970: 1_763_520_000)
        let input = "计划🚀 tomorrow 9am"
        let ranges = QuickAddNaturalLanguageParser.highlightedTokenRanges(in: input, now: now, calendar: calendar)
        let tokens = ranges.map { String(input[$0]) }

        XCTAssertEqual(tokens, ["tomorrow"])
    }

    func testParseUsesLastRecognizedTokenForConflicts() throws {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        let now = Date(timeIntervalSince1970: 1_763_552_400) // 2025-11-03T09:00:00Z
        let parsed = QuickAddNaturalLanguageParser.parse(
            "ship today tomorrow",
            now: now,
            calendar: cal
        )

        XCTAssertEqual(parsed.title, "ship")
        let due = try XCTUnwrap(parsed.dueDate)
        let expectedDay = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: now))
        XCTAssertEqual(cal.startOfDay(for: due), expectedDay)
        let components = cal.dateComponents([.hour, .minute], from: due)
        XCTAssertEqual(components.hour, 0)
        XCTAssertEqual(components.minute, 0)
    }

    func testParsePrecedenceBetweenNextWeekAndWeekdayUsesLastTokenWins() throws {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        let now = try XCTUnwrap(
            cal.date(from: DateComponents(year: 2025, month: 11, day: 5, hour: 9, minute: 0)) // Wednesday
        )
        let startOfToday = cal.startOfDay(for: now)

        let parsedWeekdayLast = QuickAddNaturalLanguageParser.parse(
            "plan next week monday",
            now: now,
            calendar: cal
        )
        let dueWeekdayLast = try XCTUnwrap(parsedWeekdayLast.dueDate)
        let expectedMonday = try XCTUnwrap(cal.date(byAdding: .day, value: 5, to: startOfToday))
        XCTAssertEqual(dueWeekdayLast, expectedMonday)

        let parsedNextWeekLast = QuickAddNaturalLanguageParser.parse(
            "plan monday next week",
            now: now,
            calendar: cal
        )
        let dueNextWeekLast = try XCTUnwrap(parsedNextWeekLast.dueDate)
        let expectedNextWeek = try XCTUnwrap(cal.date(byAdding: .day, value: 7, to: startOfToday))
        XCTAssertEqual(dueNextWeekLast, expectedNextWeek)

        let highlighted = QuickAddNaturalLanguageParser.highlightedTokenRanges(
            in: "plan monday next week",
            now: now,
            calendar: cal
        ).map { String("plan monday next week"[$0]) }
        XCTAssertEqual(highlighted, ["monday", "next", "week"])
    }
}
