import Foundation

enum TimeFilter: String, CaseIterable, Identifiable {
    case allDates = "all-dates"
    case overdue = "overdue"
    case today = "today"
    case tomorrow = "tomorrow"
    case next7Days = "next-7-days"
    case noDate = "no-date"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .allDates: return "All"
        case .overdue: return "Overdue"
        case .today: return "Today"
        case .tomorrow: return "Tomorrow"
        case .next7Days: return "Next 7"
        case .noDate: return "No Date"
        }
    }
}

private func startOfLocalDay(_ date: Date, calendar: Calendar) -> Date {
    calendar.startOfDay(for: date)
}

private func diffInLocalDays(from: Date, to: Date, calendar: Calendar) -> Int {
    let fromDay = startOfLocalDay(from, calendar: calendar)
    let toDay = startOfLocalDay(to, calendar: calendar)
    return calendar.dateComponents([.day], from: fromDay, to: toDay).day ?? 0
}

func matches(
    filter: TimeFilter,
    dueDate: Date?,
    now: Date = Date(),
    calendar: Calendar = .current
) -> Bool {
    if filter == .allDates {
        return true
    }

    if filter == .noDate {
        return dueDate == nil
    }

    guard let dueDate else {
        return false
    }

    let dayDiff = diffInLocalDays(from: now, to: dueDate, calendar: calendar)

    if filter == .overdue {
        return dayDiff < 0
    }

    if filter == .today {
        return dayDiff == 0
    }

    if filter == .tomorrow {
        return dayDiff == 1
    }

    return dayDiff >= 0 && dayDiff <= 6
}

func matchesTimeFilter(
    _ filter: TimeFilter,
    dueDate: Date?,
    now: Date = Date(),
    calendar: Calendar = .current
) -> Bool {
    matches(filter: filter, dueDate: dueDate, now: now, calendar: calendar)
}
