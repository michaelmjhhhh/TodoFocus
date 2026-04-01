import Foundation

struct QuickAddParsedInput: Equatable {
    let title: String
    let isImportant: Bool
    let isMyDay: Bool
    let listName: String?
    let dueDate: Date?
}

enum QuickAddNaturalLanguageParser {
    static func parse(_ input: String, now: Date, calendar: Calendar = .current) -> QuickAddParsedInput {
        let tokens = input
            .split(whereSeparator: \.isWhitespace)
            .map(String.init)

        var consumed = Set<Int>()
        var isImportant = false
        var isMyDay = false
        var listName: String?
        var parsedDay: Date?
        var parsedTime: (hour: Int, minute: Int)?

        var idx = 0
        while idx < tokens.count {
            let token = tokens[idx]
            let normalized = normalizeToken(token)

            if normalized == "!" || normalized == "!high" {
                isImportant = true
                consumed.insert(idx)
                idx += 1
                continue
            }

            if normalized == "@myday" {
                isMyDay = true
                consumed.insert(idx)
                idx += 1
                continue
            }

            if token.hasPrefix("#"), token.count > 1 {
                listName = String(token.dropFirst())
                    .trimmingCharacters(in: .punctuationCharacters)
                consumed.insert(idx)
                idx += 1
                continue
            }

            if normalized == "today" {
                parsedDay = calendar.startOfDay(for: now)
                consumed.insert(idx)
                idx += 1
                continue
            }

            if normalized == "tomorrow" {
                parsedDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))
                consumed.insert(idx)
                idx += 1
                continue
            }

            if normalized == "next", idx + 1 < tokens.count, normalizeToken(tokens[idx + 1]) == "week" {
                parsedDay = calendar.date(byAdding: .day, value: 7, to: calendar.startOfDay(for: now))
                consumed.insert(idx)
                consumed.insert(idx + 1)
                idx += 2
                continue
            }

            if let weekday = weekdayIndex(for: normalized) {
                parsedDay = nextWeekdayDate(from: now, weekday: weekday, calendar: calendar)
                consumed.insert(idx)
                idx += 1
                continue
            }

            if let time = parseTime(normalized) {
                parsedTime = time
                consumed.insert(idx)
                idx += 1
                continue
            }

            idx += 1
        }

        let title = tokens
            .enumerated()
            .compactMap { consumed.contains($0.offset) ? nil : $0.element }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let dueDate = resolveDueDate(
            day: parsedDay,
            time: parsedTime,
            now: now,
            calendar: calendar
        )

        return QuickAddParsedInput(
            title: title,
            isImportant: isImportant,
            isMyDay: isMyDay,
            listName: listName,
            dueDate: dueDate
        )
    }

    private static func normalizeToken(_ token: String) -> String {
        token
            .trimmingCharacters(in: .punctuationCharacters.subtracting(CharacterSet(charactersIn: "#@!:")))
            .lowercased()
    }

    private static func weekdayIndex(for token: String) -> Int? {
        switch token {
        case "sun", "sunday": return 1
        case "mon", "monday": return 2
        case "tue", "tues", "tuesday": return 3
        case "wed", "wednesday": return 4
        case "thu", "thur", "thurs", "thursday": return 5
        case "fri", "friday": return 6
        case "sat", "saturday": return 7
        default: return nil
        }
    }

    private static func nextWeekdayDate(from now: Date, weekday: Int, calendar: Calendar) -> Date? {
        let startOfToday = calendar.startOfDay(for: now)
        let currentWeekday = calendar.component(.weekday, from: startOfToday)
        var delta = (weekday - currentWeekday + 7) % 7
        if delta == 0 {
            delta = 7
        }
        return calendar.date(byAdding: .day, value: delta, to: startOfToday)
    }

    private static func parseTime(_ token: String) -> (hour: Int, minute: Int)? {
        let cleaned = token.replacingOccurrences(of: ".", with: "")
        let hasMeridiem = cleaned.hasSuffix("am") || cleaned.hasSuffix("pm")

        let suffix: String?
        let body: String
        if hasMeridiem {
            suffix = String(cleaned.suffix(2))
            body = String(cleaned.dropLast(2))
        } else {
            suffix = nil
            body = cleaned
        }

        guard !body.isEmpty else { return nil }
        let segments = body.split(separator: ":")
        guard segments.count == 1 || segments.count == 2 else { return nil }

        guard let rawHour = Int(segments[0]) else { return nil }
        let rawMinute: Int
        if segments.count == 2 {
            guard let minute = Int(segments[1]), (0...59).contains(minute) else { return nil }
            rawMinute = minute
        } else {
            rawMinute = 0
        }

        if let suffix {
            guard (1...12).contains(rawHour) else { return nil }
            var hour = rawHour % 12
            if suffix == "pm" {
                hour += 12
            }
            return (hour: hour, minute: rawMinute)
        }

        guard (0...23).contains(rawHour) else { return nil }
        return (hour: rawHour, minute: rawMinute)
    }

    private static func resolveDueDate(
        day: Date?,
        time: (hour: Int, minute: Int)?,
        now: Date,
        calendar: Calendar
    ) -> Date? {
        guard day != nil || time != nil else { return nil }

        let baseDay = day ?? calendar.startOfDay(for: now)
        var components = calendar.dateComponents([.year, .month, .day], from: baseDay)
        if let time {
            components.hour = time.hour
            components.minute = time.minute
        } else {
            components.hour = 0
            components.minute = 0
        }
        components.second = 0

        guard var due = calendar.date(from: components) else { return nil }
        if day == nil, time != nil, due <= now {
            due = calendar.date(byAdding: .day, value: 1, to: due) ?? due
        }
        return due
    }
}
