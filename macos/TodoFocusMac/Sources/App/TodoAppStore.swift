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
    @ObservationIgnored private var notesUpdateTasks: [String: Task<Void, Never>] = [:]
    @ObservationIgnored private var notesUpdateTokens: [String: UUID] = [:]

    var lists: [TodoList] = []
    var todos: [Todo] = []
    var mutationErrorMessage: String?

    var deepFocusService: DeepFocusService { appModel.deepFocusService }
    let hardFocusManager: HardFocusSessionManager

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
        hardFocusRepository: HardFocusSessionRepository,
        hardFocusManager: HardFocusSessionManager? = nil,
        now: @escaping () -> Date = Date.init
    ) {
        self.appModel = appModel
        self.listRepository = listRepository
        self.todoRepository = todoRepository
        self.stepRepository = stepRepository
        self.hardFocusManager = hardFocusManager ?? HardFocusSessionManager(repository: hardFocusRepository)
        self.now = now
    }

    var visibleTodos: [Todo] {
        let query = appModel.query()
        let visibleIDs = Set(query.apply(todos.map { $0.coreTodo }, now: now()).map(\.id))
        return todos.filter { visibleIDs.contains($0.id) }
    }

    func filteredVisibleTodos(searchQuery: String) -> [Todo] {
        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let visible = visibleTodos
        guard !trimmedQuery.isEmpty else {
            return visible
        }

        return visible.filter {
            $0.title.localizedCaseInsensitiveContains(trimmedQuery) ||
            $0.notes.localizedCaseInsensitiveContains(trimmedQuery)
        }
    }

    var selectedTodo: Todo? {
        guard let id = appModel.selectedTodoID else {
            return nil
        }
        return todos.first(where: { $0.id == id })
    }

    func reload() throws {
        try reloadLists()
        try reloadTodos()
    }

    func reloadLists() throws {
        lists = try listRepository.fetchListsOrdered().map { $0.todoList }
    }

    func reloadTodos() throws {
        todos = try todoRepository.fetchTodosOrdered().map { $0.todo }
    }

    private func refreshTodo(todoId: String) throws {
        guard let record = try todoRepository.fetchTodo(id: todoId) else {
            todos.removeAll { $0.id == todoId }
            return
        }
        if let idx = todos.firstIndex(where: { $0.id == todoId }) {
            todos[idx] = record.todo
        } else {
            todos.append(record.todo)
        }
    }

    func clearMutationError() {
        mutationErrorMessage = nil
    }

    private func setMutationError(_ error: Error, context: String) {
        if let localized = error as? LocalizedError, let description = localized.errorDescription, !description.isEmpty {
            mutationErrorMessage = "\(context): \(description)"
            return
        }
        mutationErrorMessage = "\(context): \(error.localizedDescription)"
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
        try reloadTodos()
        return created.todo
    }

    func toggleComplete(todoId: String) throws {
        guard let current = try todoRepository.fetchTodo(id: todoId) else {
            return
        }
        var input = UpdateTodoInput()
        input.isCompleted = !current.isCompleted
        try todoRepository.updateTodo(id: todoId, input: input, now: now())
        try reloadTodos()
        // Play completion sound when marking as complete (not uncompleting)
        if !current.isCompleted {
            NSSound(named: NSSound.Name("Pop"))?.play()
        }
    }

    func markComplete(todoId: String) throws {
        var input = UpdateTodoInput()
        input.isCompleted = true
        try todoRepository.updateTodo(id: todoId, input: input, now: now())
        try reloadTodos()
        NSSound(named: NSSound.Name("Pop"))?.play()
    }

    func toggleImportant(todoId: String) throws {
        guard let current = try todoRepository.fetchTodo(id: todoId) else {
            return
        }
        var input = UpdateTodoInput()
        input.isImportant = !current.isImportant
        try todoRepository.updateTodo(id: todoId, input: input, now: now())
        try reloadTodos()
    }

    func deleteTodo(todoId: String) throws {
        try todoRepository.deleteTodo(id: todoId)
        if appModel.selectedTodoID == todoId {
            appModel.selectedTodoID = nil
        }
        try reloadTodos()
    }

    func clearCompletedTodos() throws {
        let selectedTodoWasRemoved = selectedTodo?.isCompleted ?? false
        _ = try todoRepository.clearCompletedTodos()
        if selectedTodoWasRemoved {
            appModel.selectedTodoID = nil
        }
        try reloadTodos()
    }

    func selectTodo(todoId: String) {
        appModel.selectedTodoID = todoId
    }

    func clearSelection() {
        appModel.selectedTodoID = nil
    }

    func updateNotesDebounced(todoId: String, notes: String) {
        if let idx = todos.firstIndex(where: { $0.id == todoId }) {
            var updated = todos[idx]
            updated.notes = notes
            todos[idx] = updated
        }

        notesUpdateTasks[todoId]?.cancel()
        let token = UUID()
        notesUpdateTokens[todoId] = token

        notesUpdateTasks[todoId] = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
            guard self.notesUpdateTokens[todoId] == token else { return }

            var input = UpdateTodoInput()
            input.notes = notes
            do {
                try self.todoRepository.updateTodo(id: todoId, input: input, now: self.now())
                try self.refreshTodo(todoId: todoId)
            } catch {
                self.setMutationError(error, context: "Failed to save notes")
                try? self.refreshTodo(todoId: todoId)
            }

            if self.notesUpdateTokens[todoId] == token {
                self.notesUpdateTasks[todoId] = nil
                self.notesUpdateTokens[todoId] = nil
            }
        }
    }

    func setDueDate(todoId: String, date: Date?) throws {
        var input = UpdateTodoInput()
        input.dueDate = date
        try todoRepository.updateTodo(id: todoId, input: input, now: now())
        try refreshTodo(todoId: todoId)
    }

    func setMyDay(todoId: String, isMyDay: Bool) throws {
        var input = UpdateTodoInput()
        input.isMyDay = isMyDay
        try todoRepository.updateTodo(id: todoId, input: input, now: now())
        try reloadTodos()
    }

    func updateTitle(todoId: String, title: String) -> Result<Void, TodoRepositoryError> {
        do {
            try todoRepository.updateTitle(id: todoId, title: title, now: now())
            try reloadTodos()
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
        do {
            try stepRepository.toggleStep(id: stepId, isCompleted: isCompleted)
        } catch {
            setMutationError(error, context: "Failed to update step")
        }
    }

    func deleteStep(stepId: String) {
        do {
            try stepRepository.deleteStep(id: stepId)
        } catch {
            setMutationError(error, context: "Failed to delete step")
        }
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
                try reloadTodos()
                return .success(())
            } catch let error as TodoRepositoryError {
                return .failure(error)
            } catch {
                return .failure(.notFound)
            }
        }
    }

    func deleteList(listId: String) {
        do {
            try listRepository.deleteList(id: listId)
            if case let .customList(current) = appModel.selection, current == listId {
                appModel.selectSidebar(.all)
            }
            try reload()
        } catch {
            setMutationError(error, context: "Failed to delete list")
        }
    }

    func createList(name: String, color: String = "#6366F1") {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        do {
            _ = try listRepository.createList(name: trimmed, color: color, now: now())
            try reloadLists()
        } catch {
            setMutationError(error, context: "Failed to create list")
        }
    }

    func renameList(listId: String, newName: String, color: String? = nil) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        do {
            if let color {
                try listRepository.renameList(id: listId, name: trimmed, color: color, now: now())
            } else {
                try listRepository.renameList(id: listId, name: trimmed, now: now())
            }
            try reloadLists()
        } catch {
            setMutationError(error, context: "Failed to rename list")
        }
    }

    func startDeepFocus(blockedApps: [String], duration: TimeInterval?, focusTaskId: String, passphrase: String) {
        Task { @MainActor in
            // Start hard focus session (kills blocked apps) - must succeed before starting deep focus
            do {
                try await hardFocusManager.startSession(
                    blockedApps: blockedApps,
                    duration: duration,
                    focusTaskId: focusTaskId,
                    passphrase: passphrase
                )
            } catch {
                // Hard focus failed (e.g., missing Accessibility permission) — do not start deep focus
                return
            }

            // Hard focus started successfully — now start deep focus service for UI overlay
            appModel.deepFocusService.startSession(
                blockedApps: blockedApps,
                duration: duration,
                focusTaskId: focusTaskId,
                onTimerComplete: { [weak self] report in
                    do {
                        try self?.markComplete(todoId: focusTaskId)
                        try self?.updateFocusTime(todoId: focusTaskId, additionalSeconds: Int(report.duration))
                    } catch {
                        self?.setMutationError(error, context: "Failed to finalize focus task")
                    }
                    Task { @MainActor [weak self] in
                        do {
                            try await self?.hardFocusManager.emergencyEndSession()
                        } catch {
                            self?.setMutationError(error, context: "Failed to end Hard Focus session")
                        }
                    }
                }
            )
        }
    }

    func endDeepFocus(endedByHardFocus: Bool = false) async -> DeepFocusReport? {
        let configuredDuration = appModel.deepFocusService.sessionDuration
        guard let report = appModel.deepFocusService.endSession() else {
            return nil
        }

        if endedByHardFocus,
           let duration = configuredDuration,
           report.duration + 0.5 >= duration,
           let focusTaskId = report.focusTaskId {
            do {
                try markComplete(todoId: focusTaskId)
            } catch {
                setMutationError(error, context: "Failed to complete focus task")
            }
        }

        if let focusTaskId = report.focusTaskId {
            do {
                try updateFocusTime(todoId: focusTaskId, additionalSeconds: Int(report.duration))
            } catch {
                setMutationError(error, context: "Failed to update focus time")
            }
        }

        if hardFocusManager.isEnforcing {
            do {
                try await hardFocusManager.emergencyEndSession()
            } catch {
                setMutationError(error, context: "Failed to end Hard Focus session")
            }
        }

        return report
    }

    func endDeepFocusWithPassphrase(_ passphrase: String) async throws -> DeepFocusReport? {
        if hardFocusManager.isEnforcing {
            try await hardFocusManager.endSession(passphrase: passphrase)
        }

        guard let report = appModel.deepFocusService.endSession() else {
            return nil
        }

        if let focusTaskId = report.focusTaskId {
            do {
                try updateFocusTime(todoId: focusTaskId, additionalSeconds: Int(report.duration))
            } catch {
                setMutationError(error, context: "Failed to update focus time")
            }
        }

        return report
    }

    func endFocusForAppTermination() async {
        if appModel.deepFocusService.isActive {
            _ = await endDeepFocus(endedByHardFocus: true)
            return
        }

        if hardFocusManager.isEnforcing {
            do {
                try await hardFocusManager.emergencyEndSession()
            } catch {
                setMutationError(error, context: "Failed to end Hard Focus session")
            }
        }
    }

    func updateFocusTime(todoId: String, additionalSeconds: Int) throws {
        guard let current = try todoRepository.fetchTodo(id: todoId) else {
            return
        }
        var input = UpdateTodoInput()
        input.focusTimeSeconds = current.focusTimeSeconds + additionalSeconds
        try todoRepository.updateTodo(id: todoId, input: input, now: now())
        try refreshTodo(todoId: todoId)
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

            do {
                _ = try quickAdd(
                    title: title,
                    planned: false,
                    isImportant: false,
                    isMyDay: false,
                    list: nil
                )
            } catch {
                setMutationError(error, context: "Failed to capture quick note")
            }
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
