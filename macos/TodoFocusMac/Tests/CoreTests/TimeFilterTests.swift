import Foundation
import XCTest
@testable import TodoFocusMac

final class TimeFilterTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        let components = DateComponents(
            timeZone: TimeZone(secondsFromGMT: 0),
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        )
        return calendar.date(from: components)!
    }

    func testOverdueExcludesTasksDueEarlierToday() {
        let now = date(2026, 3, 21, 23, 59)
        let dueEarlierToday = date(2026, 3, 21, 0, 1)

        XCTAssertFalse(matches(filter: .overdue, dueDate: dueEarlierToday, now: now, calendar: calendar))
        XCTAssertTrue(matches(filter: .today, dueDate: dueEarlierToday, now: now, calendar: calendar))
    }

    func testOverdueMatchesPreviousDay() {
        let now = date(2026, 3, 21, 10)
        let dueYesterday = date(2026, 3, 20, 23, 59)

        XCTAssertTrue(matches(filter: .overdue, dueDate: dueYesterday, now: now, calendar: calendar))
    }

    func testTodayMatchesOnlyLocalToday() {
        let now = date(2026, 3, 21, 10)
        let dueToday = date(2026, 3, 21, 23, 30)
        let dueTomorrow = date(2026, 3, 22, 0, 0)

        XCTAssertTrue(matches(filter: .today, dueDate: dueToday, now: now, calendar: calendar))
        XCTAssertFalse(matches(filter: .today, dueDate: dueTomorrow, now: now, calendar: calendar))
    }

    func testTomorrowMatchesNextLocalDayOnly() {
        let now = date(2026, 3, 21, 10)
        let dueTomorrow = date(2026, 3, 22, 9)
        let dueInTwoDays = date(2026, 3, 23, 9)

        XCTAssertTrue(matches(filter: .tomorrow, dueDate: dueTomorrow, now: now, calendar: calendar))
        XCTAssertFalse(matches(filter: .tomorrow, dueDate: dueInTwoDays, now: now, calendar: calendar))
    }

    func testNext7DaysIncludesTodayAndNextSixDays() {
        let now = date(2026, 3, 21, 10)
        let dueToday = date(2026, 3, 21, 8)
        let dueDaySix = date(2026, 3, 27, 12)
        let dueDaySeven = date(2026, 3, 28, 12)
        let dueYesterday = date(2026, 3, 20, 12)

        XCTAssertTrue(matches(filter: .next7Days, dueDate: dueToday, now: now, calendar: calendar))
        XCTAssertTrue(matches(filter: .next7Days, dueDate: dueDaySix, now: now, calendar: calendar))
        XCTAssertFalse(matches(filter: .next7Days, dueDate: dueDaySeven, now: now, calendar: calendar))
        XCTAssertFalse(matches(filter: .next7Days, dueDate: dueYesterday, now: now, calendar: calendar))
    }

    func testNoDateMatchesOnlyNilDueDate() {
        let now = date(2026, 3, 21, 10)
        let dueToday = date(2026, 3, 21, 18)

        XCTAssertTrue(matches(filter: .noDate, dueDate: nil, now: now, calendar: calendar))
        XCTAssertFalse(matches(filter: .noDate, dueDate: dueToday, now: now, calendar: calendar))
    }

    func testAllDatesAlwaysMatches() {
        let now = date(2026, 3, 21, 10)
        let dueToday = date(2026, 3, 21, 18)

        XCTAssertTrue(matches(filter: .allDates, dueDate: nil, now: now, calendar: calendar))
        XCTAssertTrue(matches(filter: .allDates, dueDate: dueToday, now: now, calendar: calendar))
    }

    func testNonAllDateFiltersRejectNilDueDate() {
        let now = date(2026, 3, 21, 10)

        XCTAssertFalse(matches(filter: .overdue, dueDate: nil, now: now, calendar: calendar))
        XCTAssertFalse(matches(filter: .today, dueDate: nil, now: now, calendar: calendar))
        XCTAssertFalse(matches(filter: .tomorrow, dueDate: nil, now: now, calendar: calendar))
        XCTAssertFalse(matches(filter: .next7Days, dueDate: nil, now: now, calendar: calendar))
    }
}
