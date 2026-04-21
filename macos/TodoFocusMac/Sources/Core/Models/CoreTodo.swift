import Foundation

struct CoreTodo: Equatable {
    let id: String
    let isMyDay: Bool
    let isImportant: Bool
    let isCompleted: Bool
    let isArchived: Bool
    let dueDate: Date?
    let listId: String?

    init(
        id: String,
        isMyDay: Bool,
        isImportant: Bool,
        isCompleted: Bool,
        isArchived: Bool = false,
        dueDate: Date?,
        listId: String?
    ) {
        self.id = id
        self.isMyDay = isMyDay
        self.isImportant = isImportant
        self.isCompleted = isCompleted
        self.isArchived = isArchived
        self.dueDate = dueDate
        self.listId = listId
    }
}
