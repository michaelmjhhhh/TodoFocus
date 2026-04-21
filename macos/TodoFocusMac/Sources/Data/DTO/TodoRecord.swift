import Foundation
import GRDB

struct TodoRecord: Codable, FetchableRecord, PersistableRecord, Equatable {
    static let databaseTableName = "todo"

    var id: String
    var title: String
    var isCompleted: Bool
    var isArchived: Bool = false
    var isImportant: Bool
    var isMyDay: Bool
    var recurrence: String?
    var recurrenceInterval: Int
    var lastCompletedAt: Date?
    var notes: String
    var launchResources: String
    var dueDate: Date?
    var sortOrder: Int
    var createdAt: Date
    var updatedAt: Date
    var listId: String?
    var focusTimeSeconds: Int = 0
}
