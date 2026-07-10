import GRDB

struct KanbanCardLabelRecord: Codable, FetchableRecord, PersistableRecord, Equatable {
    static let databaseTableName = "kanban_card_label"

    var id: String
    var cardId: String
    var name: String
    var sortOrder: Int
}
