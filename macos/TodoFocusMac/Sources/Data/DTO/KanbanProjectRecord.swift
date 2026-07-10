import Foundation
import GRDB

struct KanbanProjectRecord: Codable, FetchableRecord, PersistableRecord, Equatable {
    static let databaseTableName = "kanban_project"

    var id: String
    var name: String
    var color: String
    var goal: String
    var createdAt: Date
    var updatedAt: Date
}
