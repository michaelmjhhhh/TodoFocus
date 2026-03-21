import Foundation
import GRDB

struct ListRecord: Codable, FetchableRecord, PersistableRecord, Equatable {
    static let databaseTableName = "list"

    var id: String
    var name: String
    var color: String
    var sortOrder: Int
    var createdAt: Date
    var updatedAt: Date
}
