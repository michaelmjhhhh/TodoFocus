import Foundation
import Observation
import AppKit

@Observable
@MainActor
final class TodoAppStore {
    private let appModel: AppModel
    private let listRepository: ListRepository
    private let todoRepository: TodoRepository
    private let stepRepository: StepRepository
    private let now: () -> Date
    private var notesUpdateWorkItems: [String: DispatchWorkItem] = [:]

    var lists: [TodoList] = []
    var todos: [Todo] = []

    var deepFocusService: DeepFocusService { appModel.deepFocusService }

    var todoCount: Int { todos.count }
    var completedCount: Int { todos.filter { $0.isCompleted }.count }
    var importantCount: Int { todos.filter { $0.isImportant }.count }
    var myDayCount: Int { todos.filter { $0.isMyDay }.count }
    var todayCount: Int { todos.filter { ($0.dueDate ?? .distantPast) < Date() && !$0.isCompleted }.count }
    var plannedCount: Int { todos.filter { $0.dueDate != nil && !$0.isCompleted }.count }
    var overdueCount: Int { todos.filter { $0.isOverdue }.count }
    var totalOverdueDebtSeconds: Int { todos.compactMap { $0.debtSeconds }.reduce(0, +) }

    func formatDebt(_ seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds)s"
        } else if seconds < 3600 {
            let minutes = seconds / 60
            return "\(minutes)m"
        } else {
            let hours = seconds / 3600
            let minutes = (seconds % 3600) / 60
            if minutes > 0 {
                return "\(hours)h \(minutes)m"
            } else {
                return "\(hours)h"
            }
        }
    }

    func countForList(_ listId: String) -> Int {
        todos.filter { $0.listId == listId && !$0.isCompleted }.count
    }

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
        // Play completion sound when marking as complete (not uncompleting)
        if !current.isCompleted {
            NSSound(named: NSSound.Name("Pop"))?.play()
        }
    }

    func markComplete(todoId: String) throws {
        var input = UpdateTodoInput()
        input.isCompleted = true
        try todoRepository.updateTodo(id: todoId, input: input, now: now())
        try reload()
        NSSound(named: NSSound.Name("Pop"))?.play()
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

    func deleteTodo(todoId: String) throws {
        try todoRepository.deleteTodo(id: todoId)
        if appModel.selectedTodoID == todoId {
            appModel.selectedTodoID = nil
        }
        try reload()
    }

    func clearCompletedTodos() throws {
        let selectedTodoWasRemoved = selectedTodo?.isCompleted ?? false
        _ = try todoRepository.clearCompletedTodos()
        if selectedTodoWasRemoved {
            appModel.selectedTodoID = nil
        }
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

    func setDueDate(todoId: String, date: Date?) throws {
        var input = UpdateTodoInput()
        input.dueDate = date
        try todoRepository.updateTodo(id: todoId, input: input, now: now())
        try reload()
    }

    func updateTitle(todoId: String, title: String) -> Result<Void, TodoRepositoryError> {
        do {
            try todoRepository.updateTitle(id: todoId, title: title, now: now())
            try reload()
            return .success(())
        } catch let error as TodoRepositoryError {
            return .failure(error)
        } catch {
            return .failure(.notFound)
        }
    }

    func addStep(todoId: String, title: String) throws {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            return
        }
        _ = try stepRepository.addStep(todoID: todoId, title: trimmedTitle)
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

    func saveLaunchResources(todoId: String, items: [LaunchResource]) -> Result<Void, TodoRepositoryError> {
        switch trySerializeLaunchResources(items) {
        case .payloadTooLarge:
            return .failure(.launchResourcesTooLarge)
        case let .ok(serialized):
            do {
                var input = UpdateTodoInput()
                input.launchResources = serialized
                try todoRepository.updateTodo(id: todoId, input: input, now: now())
                try reload()
                return .success(())
            } catch let error as TodoRepositoryError {
                return .failure(error)
            } catch {
                return .failure(.notFound)
            }
        }
    }

    func deleteList(listId: String) {
        try? listRepository.deleteList(id: listId)
        if case let .customList(current) = appModel.selection, current == listId {
            appModel.selectSidebar(.all)
        }
        try? reload()
    }

    func createList(name: String, color: String = "#6366F1") {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = try? listRepository.createList(name: trimmed, color: color, now: now())
        try? reload()
    }

    func renameList(listId: String, newName: String, color: String? = nil) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if let color {
            try? listRepository.renameList(id: listId, name: trimmed, color: color, now: now())
        } else {
            try? listRepository.renameList(id: listId, name: trimmed, now: now())
        }
        try? reload()
    }

    func startDeepFocus(blockedApps: [String], duration: TimeInterval?, focusTaskId: String) {
        appModel.deepFocusService.startSession(
            blockedApps: blockedApps,
            duration: duration,
            focusTaskId: focusTaskId,
            onTimerComplete: { [weak self] report in
                try? self?.markComplete(todoId: focusTaskId)
                try? self?.updateFocusTime(todoId: focusTaskId, additionalSeconds: Int(report.duration))
            }
        )
    }

    func endDeepFocus() -> DeepFocusReport? {
        guard let report = appModel.deepFocusService.endSession() else {
            return nil
        }

        if let focusTaskId = report.focusTaskId {
            try? updateFocusTime(todoId: focusTaskId, additionalSeconds: Int(report.duration))
        }

        return report
    }

    func updateFocusTime(todoId: String, additionalSeconds: Int) throws {
        guard let current = try todoRepository.fetchTodo(id: todoId) else {
            return
        }
        var input = UpdateTodoInput()
        input.focusTimeSeconds = (current.focusTimeSeconds ?? 0) + additionalSeconds
        try todoRepository.updateTodo(id: todoId, input: input, now: now())
        try reload()
    }

    func formatFocusTime(_ seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds)s"
        } else if seconds < 3600 {
            let minutes = seconds / 60
            return "\(minutes)m"
        } else {
            let hours = seconds / 3600
            let minutes = (seconds % 3600) / 60
            if minutes > 0 {
                return "\(hours)h \(minutes)m"
            } else {
                return "\(hours)h"
            }
        }
    }

    func appendToFocusTaskNotes(_ text: String) {
        if let focusTaskId = appModel.deepFocusService.currentFocusTaskId,
           let todo = todos.first(where: { $0.id == focusTaskId }) {
            let currentNotes = todo.notes
            let newNotes = currentNotes.isEmpty ? text : currentNotes + text
            updateNotesDebounced(todoId: focusTaskId, notes: newNotes)
        } else {
            let captureText = text.trimmingCharacters(in: .whitespacesAndNewlines)
            let title = captureText.components(separatedBy: .newlines).first ?? captureText
            
            _ = try? quickAdd(
                title: title,
                planned: false,
                isImportant: false,
                isMyDay: false,
                list: nil
            )
        }
    }
}

private extension Todo {
    var coreTodo: CoreTodo {
        CoreTodo(id: id, isMyDay: isMyDay, isImportant: isImportant, isCompleted: isCompleted, dueDate: dueDate, listId: listId)
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
            listId: listId,
            launchResourcesRaw: launchResources,
            focusTimeSeconds: focusTimeSeconds
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
