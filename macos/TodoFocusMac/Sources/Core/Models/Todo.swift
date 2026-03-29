import Foundation

struct Todo: Identifiable, Equatable {
    let id: String
    var title: String
    var isCompleted: Bool
    var isImportant: Bool
    var isMyDay: Bool
    var dueDate: Date?
    var notes: String
    var listId: String?
    var launchResourcesRaw: String
    var focusTimeSeconds: Int = 0

    func debtSeconds(at now: Date = Date(), calendar: Calendar = .current) -> Int? {
        guard !isCompleted, let dueDate else { return nil }

        // Due date is day-based in the UI, so a task should only become overdue
        // after the local due day has fully passed.
        let dueDay = calendar.startOfDay(for: dueDate)
        let nowDay = calendar.startOfDay(for: now)
        guard dueDay < nowDay else { return nil }

        let diff = Int(now.timeIntervalSince(dueDate))
        guard diff > 0 else { return nil }
        return diff
    }

    var debtSeconds: Int? { debtSeconds() }

    func isOverdue(at now: Date = Date(), calendar: Calendar = .current) -> Bool {
        debtSeconds(at: now, calendar: calendar) != nil
    }

    var isOverdue: Bool { isOverdue() }
}
