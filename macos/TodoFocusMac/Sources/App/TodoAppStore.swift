import Foundation
import Observation

@Observable
final class TodoAppStore {
    private let appModel: AppModel
    private let listRepository: ListRepository
    private let todoRepository: TodoRepository
    private let now: () -> Date

    var lists: [TodoList] = []
    var todos: [Todo] = []

    init(
        appModel: AppModel,
        listRepository: ListRepository,
        todoRepository: TodoRepository,
        now: @escaping () -> Date = Date.init
    ) {
        self.appModel = appModel
        self.listRepository = listRepository
        self.todoRepository = todoRepository
        self.now = now
    }

    var visibleTodos: [Todo] {
        let query = appModel.query()
        let visibleIDs = Set(query.apply(todos.map { $0.coreTodo }, now: now()).map(\.id))
        return todos.filter { visibleIDs.contains($0.id) }
    }

    var selectedTodo: Todo? {
        guard let id = appModel.selectedTodoID else {
            return nil
        }
        return todos.first(where: { $0.id == id })
    }

    func reload() throws {
        lists = try listRepository.fetchListsOrdered().map { $0.todoList }
        todos = try todoRepository.fetchTodosOrdered().map { $0.todo }
    }

    @discardableResult
    func quickAdd(
        title: String,
        planned: Bool,
        isImportant: Bool,
        isMyDay: Bool,
        list: TodoList?
    ) throws -> Todo {
        let created = try todoRepository.addTodo(
            AddTodoInput(
                title: title,
                listID: list?.id,
                isMyDay: isMyDay,
                isImportant: isImportant,
                planned: planned
            ),
            now: now()
        )
        try reload()
        return created.todo
    }

    func toggleComplete(todoId: String) throws {
        guard let current = try todoRepository.fetchTodo(id: todoId) else {
            return
        }
        var input = UpdateTodoInput()
        input.isCompleted = !current.isCompleted
        try todoRepository.updateTodo(id: todoId, input: input, now: now())
        try reload()
    }

    func toggleImportant(todoId: String) throws {
        guard let current = try todoRepository.fetchTodo(id: todoId) else {
            return
        }
        var input = UpdateTodoInput()
        input.isImportant = !current.isImportant
        try todoRepository.updateTodo(id: todoId, input: input, now: now())
        try reload()
    }

    func selectTodo(todoId: String) {
        appModel.selectedTodoID = todoId
    }

    func clearSelection() {
        appModel.selectedTodoID = nil
    }
}

private extension Todo {
    var coreTodo: CoreTodo {
        CoreTodo(id: id, isMyDay: isMyDay, isImportant: isImportant, dueDate: dueDate, listId: listId)
    }
}

private extension TodoRecord {
    var todo: Todo {
        Todo(
            id: id,
            title: title,
            isCompleted: isCompleted,
            isImportant: isImportant,
            isMyDay: isMyDay,
            dueDate: dueDate,
            notes: notes,
            listId: listId
        )
    }
}

private extension ListRecord {
    var todoList: TodoList {
        TodoList(id: id, name: name, color: color, sortOrder: sortOrder)
    }
}
