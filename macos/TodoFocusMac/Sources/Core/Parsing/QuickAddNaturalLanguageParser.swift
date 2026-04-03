import Foundation

struct QuickAddParsedInput: Equatable {
    let title: String
    let isImportant: Bool
    let isMyDay: Bool
    let dueDate: Date?
}

enum QuickAddNaturalLanguageParser {
    static func parse(_ input: String, now: Date, calendar: Calendar = .current) -> QuickAddParsedInput {
        let analysis = analyze(input, now: now, calendar: calendar)

        let title = analysis.tokens
            .enumerated()
            .compactMap { analysis.consumed.contains($0.offset) ? nil : $0.element.raw }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let dueDate = resolveDueDate(
            day: analysis.parsedDay,
            now: now,
            calendar: calendar
        )

        return QuickAddParsedInput(
            title: title,
            isImportant: analysis.isImportant,
            isMyDay: analysis.isMyDay,
            dueDate: dueDate
        )
    }

    static func highlightedTokenRanges(in input: String, now: Date, calendar: Calendar = .current) -> [Range<String.Index>] {
        let analysis = analyze(input, now: now, calendar: calendar)
        return analysis.tokens
            .enumerated()
            .compactMap { analysis.consumed.contains($0.offset) ? $0.element.range : nil }
    }

    private static func normalizeToken(_ token: String) -> String {
        token
            .trimmingCharacters(in: .punctuationCharacters.subtracting(CharacterSet(charactersIn: "#@!")))
            .lowercased()
    }

    private static func analyze(_ input: String, now: Date, calendar: Calendar) -> TokenAnalysis {
        let tokens = tokenize(input)
        var consumed = Set<Int>()
        var isImportant = false
        var isMyDay = false
        var parsedDay: Date?

        var idx = 0
        while idx < tokens.count {
            let token = tokens[idx].raw
            let normalized = normalizeToken(token)

            if normalized == "!" {
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

            if normalized == "next", idx + 1 < tokens.count, normalizeToken(tokens[idx + 1].raw) == "week" {
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

            idx += 1
        }

        return TokenAnalysis(
            tokens: tokens,
            consumed: consumed,
            isImportant: isImportant,
            isMyDay: isMyDay,
            parsedDay: parsedDay
        )
    }

    private static func tokenize(_ input: String) -> [TokenSlice] {
        var result: [TokenSlice] = []
        var idx = input.startIndex
        while idx < input.endIndex {
            while idx < input.endIndex, input[idx].isWhitespace {
                idx = input.index(after: idx)
            }
            guard idx < input.endIndex else { break }

            let start = idx
            while idx < input.endIndex, !input[idx].isWhitespace {
                idx = input.index(after: idx)
            }
            let end = idx
            result.append(TokenSlice(raw: String(input[start..<end]), range: start..<end))
        }
        return result
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

    private static func resolveDueDate(
        day: Date?,
        now: Date,
        calendar: Calendar
    ) -> Date? {
        _ = now
        guard let day else { return nil }
        return day
    }
}

private struct TokenSlice {
    let raw: String
    let range: Range<String.Index>
}

private struct TokenAnalysis {
    let tokens: [TokenSlice]
    let consumed: Set<Int>
    let isImportant: Bool
    let isMyDay: Bool
    let parsedDay: Date?
}
