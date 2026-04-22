import Foundation

enum DailyReviewLane: String {
    case open
    case completed
}

enum DailyReviewTimeBucket: String, CaseIterable, Identifiable {
    case overdue
    case today
    case tomorrow
    case later
    case noDate

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overdue: return "Overdue"
        case .today: return "Today"
        case .tomorrow: return "Tomorrow"
        case .later: return "Later"
        case .noDate: return "No Date"
        }
    }
}

struct DailyReviewColumn: Identifiable {
    let bucket: DailyReviewTimeBucket
    let todos: [Todo]

    var id: String { bucket.rawValue }
}

struct DailyReviewBoard {
    let openColumns: [DailyReviewColumn]
    let completedColumns: [DailyReviewColumn]

    static let empty = DailyReviewBoard(
        openColumns: DailyReviewTimeBucket.allCases.map { DailyReviewColumn(bucket: $0, todos: []) },
        completedColumns: DailyReviewTimeBucket.allCases.map { DailyReviewColumn(bucket: $0, todos: []) }
    )
}

struct DailyReviewColumnCollapseKey: Hashable {
    let lane: DailyReviewLane
    let bucket: DailyReviewTimeBucket
}

enum DailyReview {
    private static let dueDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    static func sortedForReview(_ todos: [Todo]) -> [Todo] {
        todos.sorted { lhs, rhs in
            if lhs.isCompleted != rhs.isCompleted {
                return !lhs.isCompleted && rhs.isCompleted
            }
            switch (lhs.dueDate, rhs.dueDate) {
            case let (l?, r?):
                return l < r
            case (.some, .none):
                return true
            case (.none, .some):
                return false
            case (.none, .none):
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            }
        }
    }

    static func dueText(for dueDate: Date?, now: Date = Date(), calendar: Calendar = .current) -> String {
        guard let dueDate else { return "No Date" }
        if calendar.isDate(dueDate, inSameDayAs: now) { return "Today" }
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))
        if let tomorrow, calendar.isDate(dueDate, inSameDayAs: tomorrow) { return "Tomorrow" }
        if dueDate < now { return "Overdue" }
        return dueDateFormatter.string(from: dueDate)
    }

    static func dueBucket(for dueDate: Date?, now: Date = Date(), calendar: Calendar = .current) -> DailyReviewTimeBucket {
        guard let dueDate else { return .noDate }
        if calendar.isDate(dueDate, inSameDayAs: now) { return .today }
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))
        if let tomorrow, calendar.isDate(dueDate, inSameDayAs: tomorrow) { return .tomorrow }
        if dueDate < now { return .overdue }
        return .later
    }

    static func buildBoard(_ todos: [Todo], now: Date = Date(), calendar: Calendar = .current) -> DailyReviewBoard {
        var openMap: [DailyReviewTimeBucket: [Todo]] = [:]
        var completedMap: [DailyReviewTimeBucket: [Todo]] = [:]
        DailyReviewTimeBucket.allCases.forEach {
            openMap[$0] = []
            completedMap[$0] = []
        }

        for todo in todos {
            let bucket = dueBucket(for: todo.dueDate, now: now, calendar: calendar)
            if todo.isCompleted {
                completedMap[bucket, default: []].append(todo)
            } else {
                openMap[bucket, default: []].append(todo)
            }
        }

        let openColumns = DailyReviewTimeBucket.allCases.map { bucket in
            DailyReviewColumn(bucket: bucket, todos: sortColumnTodos(openMap[bucket] ?? []))
        }
        let completedColumns = DailyReviewTimeBucket.allCases.map { bucket in
            DailyReviewColumn(bucket: bucket, todos: sortColumnTodos(completedMap[bucket] ?? []))
        }

        return DailyReviewBoard(openColumns: openColumns, completedColumns: completedColumns)
    }

    static func sortColumnTodos(_ todos: [Todo]) -> [Todo] {
        todos.sorted { lhs, rhs in
            switch (lhs.dueDate, rhs.dueDate) {
            case let (l?, r?):
                if l != r { return l < r }
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            case (.some, .none):
                return true
            case (.none, .some):
                return false
            case (.none, .none):
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            }
        }
    }
}