import Foundation

struct TodoStep: Identifiable, Equatable {
    let id: String
    var title: String
    var isCompleted: Bool
    var sortOrder: Int
    var todoId: String
}
