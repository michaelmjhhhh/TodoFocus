import Foundation
import GRDB

struct StepRecord: Codable, FetchableRecord, PersistableRecord, Equatable {
    static let databaseTableName = "step"

    var id: String
    var title: String
    var isCompleted: Bool
    var sortOrder: Int
    var todoId: String
}
