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

    var debtSeconds: Int? {
        guard !isCompleted, let dueDate = dueDate else { return nil }
        let diff = Int(Date().timeIntervalSince(dueDate))
        guard diff > 0 else { return nil }
        return diff
    }

    var isOverdue: Bool {
        debtSeconds != nil
    }
}
