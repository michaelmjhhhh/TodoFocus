import Foundation

struct CoreTodo: Equatable {
    let id: String
    let isMyDay: Bool
    let isImportant: Bool
    let dueDate: Date?
    let listId: String?
}
