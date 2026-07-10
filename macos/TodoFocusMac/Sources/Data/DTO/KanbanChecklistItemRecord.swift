import GRDB

struct KanbanChecklistItemRecord: Codable, FetchableRecord, PersistableRecord, Equatable {
    static let databaseTableName = "kanban_checklist_item"

    var id: String
    var cardId: String
    var title: String
    var isCompleted: Bool
    var sortOrder: Int
}
