import Foundation
import XCTest
@testable import TodoFocusMac

final class TodoAppStoreTests: XCTestCase {
    private func makeStore(now: Date = Date(timeIntervalSince1970: 1_763_520_000)) throws -> (TodoAppStore, AppModel, ListRepository, TodoRepository) {
        let path = NSTemporaryDirectory() + UUID().uuidString + ".sqlite"
        let manager = try DatabaseManager(databasePath: path)
        let listRepository = ListRepository(dbQueue: manager.dbQueue)
        let todoRepository = TodoRepository(dbQueue: manager.dbQueue)
        let stepRepository = StepRepository(dbQueue: manager.dbQueue)
        let hardFocusRepository = HardFocusSessionRepository(dbQueue: manager.dbQueue)
        let appModel = AppModel()
        let store = TodoAppStore(
            appModel: appModel,
            listRepository: listRepository,
            todoRepository: todoRepository,
            stepRepository: stepRepository,
            hardFocusRepository: hardFocusRepository,
            now: { now }
        )
        return (store, appModel, listRepository, todoRepository)
    }

    @MainActor
    func testEndDeepFocusAlsoEndsHardFocusSession() async throws {
        let path = NSTemporaryDirectory() + UUID().uuidString + ".sqlite"
        let manager = try DatabaseManager(databasePath: path)
        let listRepository = ListRepository(dbQueue: manager.dbQueue)
        let todoRepository = TodoRepository(dbQueue: manager.dbQueue)
        let stepRepository = StepRepository(dbQueue: manager.dbQueue)
        let hardFocusRepository = HardFocusSessionRepository(dbQueue: manager.dbQueue)
        let appModel = AppModel()
        let enforcer = MockTestHardFocusInProcessEnforcer()
        let hardFocusManager = HardFocusSessionManager(
            repository: hardFocusRepository,
            agentManager: MockTestHardFocusAgentManager(isRegistered: true, isRunning: true),
            inProcessEnforcer: enforcer,
            isAccessibilityTrusted: { true },
            agentStartupTimeout: 0,
            agentPollInterval: 0.01
        )

        let store = TodoAppStore(
            appModel: appModel,
            listRepository: listRepository,
            todoRepository: todoRepository,
            stepRepository: stepRepository,
            hardFocusRepository: hardFocusRepository,
            hardFocusManager: hardFocusManager,
            now: Date.init
        )

        let todo = try store.quickAdd(
            title: "Focus Task",
            planned: false,
            isImportant: false,
            isMyDay: false,
            list: nil
        )

        store.startDeepFocus(
            blockedApps: ["com.apple.Safari"],
            duration: nil,
            focusTaskId: todo.id,
            passphrase: "unlock"
        )

        let started = expectation(description: "Hard focus started")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if hardFocusManager.isEnforcing {
                started.fulfill()
            }
        }
        await fulfillment(of: [started], timeout: 1.0)
        XCTAssertTrue(hardFocusManager.isEnforcing)

        _ = await store.endDeepFocus()

        XCTAssertFalse(hardFocusManager.isEnforcing)
        XCTAssertNil(try hardFocusRepository.activeSession())
        XCTAssertGreaterThanOrEqual(enforcer.stopCallCount, 1)
    }

    @MainActor
    func testEndDeepFocusTriggeredByHardFocusMarksTaskCompleteWhenTimedSessionElapsed() async throws {
        let path = NSTemporaryDirectory() + UUID().uuidString + ".sqlite"
        let manager = try DatabaseManager(databasePath: path)
        let listRepository = ListRepository(dbQueue: manager.dbQueue)
        let todoRepository = TodoRepository(dbQueue: manager.dbQueue)
        let stepRepository = StepRepository(dbQueue: manager.dbQueue)
        let hardFocusRepository = HardFocusSessionRepository(dbQueue: manager.dbQueue)
        let appModel = AppModel()
        let hardFocusManager = HardFocusSessionManager(
            repository: hardFocusRepository,
            agentManager: MockTestHardFocusAgentManager(isRegistered: true, isRunning: true),
            inProcessEnforcer: MockTestHardFocusInProcessEnforcer(),
            isAccessibilityTrusted: { true },
            agentStartupTimeout: 0,
            agentPollInterval: 0.01
        )

        let store = TodoAppStore(
            appModel: appModel,
            listRepository: listRepository,
            todoRepository: todoRepository,
            stepRepository: stepRepository,
            hardFocusRepository: hardFocusRepository,
            hardFocusManager: hardFocusManager,
            now: Date.init
        )

        let todo = try store.quickAdd(
            title: "Timed Focus Task",
            planned: false,
            isImportant: false,
            isMyDay: false,
            list: nil
        )

        store.startDeepFocus(
            blockedApps: [],
            duration: nil,
            focusTaskId: todo.id,
            passphrase: "unlock"
        )

        let started = expectation(description: "Hard focus started")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if hardFocusManager.isEnforcing {
                started.fulfill()
            }
        }
        await fulfillment(of: [started], timeout: 1.0)

        // Simulate a timed session whose planned duration has already elapsed.
        store.deepFocusService.sessionDuration = 0

        _ = await store.endDeepFocus(endedByHardFocus: true)

        let persisted = try XCTUnwrap(todoRepository.fetchTodo(id: todo.id))
        XCTAssertTrue(persisted.isCompleted)
    }

    func testVisibleTodosUsesAppModelSelectionAndTimeFilter() throws {
        let now = Date(timeIntervalSince1970: 1_763_520_000)
        let tomorrow = now.addingTimeInterval(86_400)
        let (store, appModel, _, todoRepository) = try makeStore(now: now)

        _ = try todoRepository.addTodo(
            AddTodoInput(title: "Today important", listID: nil, isMyDay: false, isImportant: true, planned: true),
            now: now
        )
        _ = try todoRepository.addTodo(
            AddTodoInput(title: "Tomorrow important", listID: nil, isMyDay: false, isImportant: true, planned: false),
            now: now
        )
        _ = try todoRepository.addTodo(
            AddTodoInput(title: "Today normal", listID: nil, isMyDay: false, isImportant: false, planned: true),
            now: now
        )

        let all = try todoRepository.fetchTodosOrdered()
        let tomorrowId = try XCTUnwrap(all.first(where: { $0.title == "Tomorrow important" })?.id)
        var patch = UpdateTodoInput()
        patch.dueDate = tomorrow
        try todoRepository.updateTodo(id: tomorrowId, input: patch, now: now)

        try store.reload()
        appModel.selection = .important
        appModel.timeFilter = .today

        XCTAssertEqual(store.visibleTodos.map(\.title), ["Today important"])
    }

    func testQuickAddMapsFlagsAndListToRepositoryRecord() throws {
        let now = Date(timeIntervalSince1970: 1_763_520_000)
        let (store, _, listRepository, todoRepository) = try makeStore(now: now)
        let listRecord = try listRepository.createList(name: "Work", now: now)
        let list = TodoList(id: listRecord.id, name: listRecord.name, color: listRecord.color, sortOrder: listRecord.sortOrder)

        let created = try store.quickAdd(
            title: "  Ship desktop build  ",
            planned: true,
            isImportant: true,
            isMyDay: true,
            list: list
        )

        let persisted = try XCTUnwrap(todoRepository.fetchTodo(id: created.id))
        XCTAssertEqual(persisted.title, "Ship desktop build")
        XCTAssertTrue(persisted.isImportant)
        XCTAssertTrue(persisted.isMyDay)
        XCTAssertEqual(persisted.listId, list.id)
        XCTAssertEqual(persisted.dueDate, now)
    }

    func testUpdateNotesDebouncedPersistsLatestValue() throws {
        let now = Date(timeIntervalSince1970: 1_763_520_000)
        let (store, _, _, todoRepository) = try makeStore(now: now)
        let created = try store.quickAdd(
            title: "Debounce target",
            planned: false,
            isImportant: false,
            isMyDay: false,
            list: nil
        )

        store.updateNotesDebounced(todoId: created.id, notes: "first")
        store.updateNotesDebounced(todoId: created.id, notes: "second")

        let debounceFinished = expectation(description: "Debounced notes update executes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            debounceFinished.fulfill()
        }
        wait(for: [debounceFinished], timeout: 1.5)

        let persisted = try XCTUnwrap(todoRepository.fetchTodo(id: created.id))
        XCTAssertEqual(persisted.notes, "second")
    }

    func testDueDateClearButtonVisibilityHelper() {
        XCTAssertFalse(TaskDetailView.shouldShowDueDateClearButton(dueDate: nil))
        XCTAssertTrue(TaskDetailView.shouldShowDueDateClearButton(dueDate: Date(timeIntervalSince1970: 1_763_520_000)))
    }

    func testDeleteActiveCustomListRoutesSelectionToAll() throws {
        let (store, appModel, listRepository, _) = try makeStore()
        let list = try listRepository.createList(name: "Temp")
        appModel.selectSidebar(.customList(list.id))

        store.deleteList(listId: list.id)

        XCTAssertEqual(appModel.selection, .all)
    }

    func testDeleteTodoRemovesItAndClearsSelectionWhenSelected() throws {
        let (store, _, _, _) = try makeStore()
        let created = try store.quickAdd(
            title: "Delete selected",
            planned: false,
            isImportant: false,
            isMyDay: false,
            list: nil
        )
        store.selectTodo(todoId: created.id)

        try store.deleteTodo(todoId: created.id)

        XCTAssertNil(store.selectedTodo)
        XCTAssertFalse(store.todos.contains(where: { $0.id == created.id }))
    }

    func testClearCompletedTodosRemovesCompletedAndClearsSelectionForCompletedSelection() throws {
        let (store, _, _, _) = try makeStore()
        let active = try store.quickAdd(
            title: "Active",
            planned: false,
            isImportant: false,
            isMyDay: false,
            list: nil
        )
        let completed = try store.quickAdd(
            title: "Completed",
            planned: false,
            isImportant: false,
            isMyDay: false,
            list: nil
        )

        try store.toggleComplete(todoId: completed.id)
        store.selectTodo(todoId: completed.id)

        try store.clearCompletedTodos()

        XCTAssertNil(store.selectedTodo)
        XCTAssertTrue(store.todos.contains(where: { $0.id == active.id }))
        XCTAssertFalse(store.todos.contains(where: { $0.id == completed.id }))
    }

    @MainActor
    func testTaskListSearchFiltersByTitleAndNotesCaseInsensitive() {
        let todoA = Todo(
            id: "a",
            title: "Plan Sprint",
            isCompleted: false,
            isImportant: false,
            isMyDay: false,
            dueDate: nil,
            notes: "Review roadmap",
            listId: nil,
            launchResourcesRaw: "[]"
        )
        let todoB = Todo(
            id: "b",
            title: "Write docs",
            isCompleted: false,
            isImportant: false,
            isMyDay: false,
            dueDate: nil,
            notes: "Add API SEARCH examples",
            listId: nil,
            launchResourcesRaw: "[]"
        )
        let preFiltered = [todoA, todoB]

        XCTAssertEqual(TaskListView.filterTodos(preFiltered, query: "sprint").map(\.id), ["a"])
        XCTAssertEqual(TaskListView.filterTodos(preFiltered, query: "search").map(\.id), ["b"])
        XCTAssertEqual(TaskListView.filterTodos(preFiltered, query: "").map(\.id), ["a", "b"])
        XCTAssertEqual(TaskListView.filterTodos(preFiltered, query: "vendor").map(\.id), [])
    }
}

private final class MockTestHardFocusAgentManager: HardFocusAgentControlling {
    var isRegistered: Bool
    var isRunning: Bool

    init(isRegistered: Bool, isRunning: Bool) {
        self.isRegistered = isRegistered
        self.isRunning = isRunning
    }

    func register() throws {
        isRegistered = true
    }
}

@MainActor
private final class MockTestHardFocusInProcessEnforcer: HardFocusInProcessEnforcing {
    private(set) var stopCallCount = 0

    func start(blockedApps: [String]) { }

    func stop() {
        stopCallCount += 1
    }
}
