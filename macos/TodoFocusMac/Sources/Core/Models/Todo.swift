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
}
