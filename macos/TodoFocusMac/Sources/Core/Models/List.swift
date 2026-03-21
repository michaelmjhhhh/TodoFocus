import Foundation

struct TodoList: Identifiable, Equatable {
    let id: String
    var name: String
    var color: String
    var sortOrder: Int
}
