import Foundation
import Observation

@Observable
final class TodoAppStore {
    private let appModel: AppModel
    private let listRepository: ListRepository
    private let todoRepository: TodoRepository
    private let stepRepository: StepRepository
    private let now: () -> Date
    private var notesUpdateWorkItems: [String: DispatchWorkItem] = [:]

    var lists: [TodoList] = []
    var todos: [Todo] = []

    init(
        appModel: AppModel,
        listRepository: ListRepository,
        todoRepository: TodoRepository,
        stepRepository: StepRepository,
        now: @escaping () -> Date = Date.init
    ) {
        self.appModel = appModel
        self.listRepository = listRepository
        self.todoRepository = todoRepository
        self.stepRepository = stepRepository
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

    func updateNotesDebounced(todoId: String, notes: String) {
        notesUpdateWorkItems[todoId]?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            var input = UpdateTodoInput()
            input.notes = notes
            try? self.todoRepository.updateTodo(id: todoId, input: input, now: self.now())
            try? self.reload()
            self.notesUpdateWorkItems[todoId] = nil
        }

        notesUpdateWorkItems[todoId] = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
    }

    func setDueDate(todoId: String, date: Date?) {
        var input = UpdateTodoInput()
        input.dueDate = date
        try? todoRepository.updateTodo(id: todoId, input: input, now: now())
        try? reload()
    }

    func addStep(todoId: String, title: String) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            return
        }
        _ = try? stepRepository.addStep(todoID: todoId, title: trimmedTitle)
    }

    func toggleStep(stepId: String, isCompleted: Bool) {
        try? stepRepository.toggleStep(id: stepId, isCompleted: isCompleted)
    }

    func deleteStep(stepId: String) {
        try? stepRepository.deleteStep(id: stepId)
    }

    func loadSteps(todoId: String) -> [TodoStep] {
        (try? stepRepository.fetchSteps(todoID: todoId).map(\.todoStep)) ?? []
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

private extension StepRecord {
    var todoStep: TodoStep {
        TodoStep(id: id, title: title, isCompleted: isCompleted, sortOrder: sortOrder, todoId: todoId)
    }
}
