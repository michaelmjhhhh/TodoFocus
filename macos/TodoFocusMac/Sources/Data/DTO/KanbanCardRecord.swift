import Foundation
import GRDB

struct KanbanCardRecord: Codable, FetchableRecord, PersistableRecord, Equatable {
    static let databaseTableName = "kanban_card"

    var id: String
    var projectId: String
    var title: String
    var description: String
    var status: String
    var priority: String
    var dueDate: Date?
    var sortOrder: Int
    var isArchived: Bool
    var createdAt: Date
    var updatedAt: Date
}
