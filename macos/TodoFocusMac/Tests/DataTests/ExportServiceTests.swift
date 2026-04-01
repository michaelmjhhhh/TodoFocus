import Foundation
import XCTest
@testable import TodoFocusMac

final class ExportServiceTests: XCTestCase {
    private func makeManager() throws -> DatabaseManager {
        let path = NSTemporaryDirectory() + UUID().uuidString + ".sqlite"
        return try DatabaseManager(databasePath: path)
    }

    private func makeService(_ manager: DatabaseManager) -> ExportService {
        ExportService(dbQueue: manager.dbQueue)
    }

    private func seedBasicData(_ manager: DatabaseManager) throws {
        try manager.dbQueue.write { db in
            let list = ListRecord(
                id: "list-1",
                name: "Work",
                color: "#C46849",
                sortOrder: 0,
                createdAt: Date(),
                updatedAt: Date()
            )
            try list.insert(db)

            let resources = [
                LaunchResource(
                    id: "res-1",
                    type: .url,
                    label: "Docs",
                    value: "https://example.com",
                    createdAt: Date()
                ),
                LaunchResource(
                    id: "res-2",
                    type: .file,
                    label: "Spec",
                    value: "/Users/example/spec.md",
                    createdAt: Date()
                ),
                LaunchResource(
                    id: "res-3",
                    type: .app,
                    label: "Safari",
                    value: "/Applications/Safari.app",
                    createdAt: Date()
                )
            ]
            let resourcesData = try JSONEncoder().encode(resources)
            let resourcesJSON = String(data: resourcesData, encoding: .utf8) ?? "[]"

            let todo = TodoRecord(
                id: "todo-1",
                title: "Ship",
                isCompleted: false,
                isImportant: true,
                isMyDay: true,
                recurrence: nil,
                recurrenceInterval: 1,
                lastCompletedAt: nil,
                notes: "note",
                launchResources: resourcesJSON,
                dueDate: nil,
                sortOrder: 0,
                createdAt: Date(),
                updatedAt: Date(),
                listId: "list-1",
                focusTimeSeconds: 90
            )
            try todo.insert(db)

            let step = StepRecord(
                id: "step-1",
                title: "Step",
                isCompleted: false,
                sortOrder: 0,
                todoId: "todo-1"
            )
            try step.insert(db)
        }
    }

    func testDecodeV1_0PayloadStillWorks() throws {
        let payload = """
        {
          "version": "1.0",
          "exportedAt": "2026-03-28T12:00:00Z",
          "lists": [],
          "todos": []
        }
        """.data(using: .utf8)!

        let decoded = try ExportData.decode(from: payload)
        XCTAssertEqual(decoded.version, "1.0")
    }

    func testPreflightRejectsUnsupportedVersion() throws {
        let manager = try makeManager()
        let service = makeService(manager)

        let payload = """
        {
          "version": "9.9",
          "exportedAt": "2026-03-28T12:00:00Z",
          "lists": [],
          "todos": []
        }
        """.data(using: .utf8)!

        let preflight = try service.preflightImportJSON(payload)
        XCTAssertFalse(preflight.blockingErrors.isEmpty)
    }

    func testExportIncludesOnlyURLLaunchResources() throws {
        let manager = try makeManager()
        try seedBasicData(manager)
        let service = makeService(manager)

        let data = try service.exportToJSON()
        let payload = try ExportData.decode(from: data)
        let todo = try XCTUnwrap(payload.todos.first { $0.id == "todo-1" })

        XCTAssertEqual(todo.launchResources.count, 1)
        XCTAssertEqual(todo.launchResources.first?.type, LaunchResourceType.url.rawValue)
        XCTAssertEqual(todo.launchResources.first?.value, "https://example.com")
    }

    func testPreflightWarnsWhenNonPortableLaunchResourcesExist() throws {
        let manager = try makeManager()
        let service = makeService(manager)

        let payload = """
        {
          "version": "1.2",
          "exportedAt": "2026-03-30T12:00:00Z",
          "lists": [],
          "todos": [
            {
              "id": "todo-1",
              "title": "Imported",
              "isCompleted": false,
              "isImportant": false,
              "isMyDay": false,
              "dueDate": null,
              "notes": "",
              "listId": null,
              "focusTimeSeconds": 0,
              "recurrence": null,
              "recurrenceInterval": 1,
              "sortOrder": 0,
              "steps": [],
              "launchResources": [
                { "type": "url", "value": "https://example.com", "label": "Docs" },
                { "type": "file", "value": "/tmp/spec.md", "label": "Spec" }
              ]
            }
          ]
        }
        """.data(using: .utf8)!

        let preflight = try service.preflightImportJSON(payload)
        XCTAssertEqual(preflight.counts.launchResources, 2)
        XCTAssertTrue(preflight.warnings.contains(where: { $0.contains("non-portable launch resources") }))
    }

    func testImportReplaceReturnsStructuredReport() throws {
        let manager = try makeManager()
        try seedBasicData(manager)
        let service = makeService(manager)

        let data = try service.exportToJSON()
        let report = try service.executeImportJSON(data, mode: .replace)

        XCTAssertGreaterThanOrEqual(report.created.todos, 1)
    }

    func testImportSkipsNonURLLaunchResources() throws {
        let manager = try makeManager()
        let service = makeService(manager)

        let payload = """
        {
          "version": "1.2",
          "exportedAt": "2026-03-30T12:00:00Z",
          "lists": [
            { "id": "list-1", "name": "Work", "color": "#C46849", "sortOrder": 0 }
          ],
          "todos": [
            {
              "id": "todo-1",
              "title": "Imported",
              "isCompleted": false,
              "isImportant": false,
              "isMyDay": false,
              "dueDate": null,
              "notes": "",
              "listId": "list-1",
              "focusTimeSeconds": 0,
              "recurrence": null,
              "recurrenceInterval": 1,
              "sortOrder": 0,
              "steps": [],
              "launchResources": [
                { "type": "url", "value": "https://example.com", "label": "Docs" },
                { "type": "file", "value": "/tmp/spec.md", "label": "Spec" },
                { "type": "app", "value": "/Applications/Safari.app", "label": "Safari" }
              ]
            }
          ]
        }
        """.data(using: .utf8)!

        let report = try service.executeImportJSON(payload, mode: .replace)
        XCTAssertEqual(report.created.launchResources, 1)
        XCTAssertEqual(report.skipped.launchResources, 2)

        let todoRepo = TodoRepository(dbQueue: manager.dbQueue)
        let merged = try XCTUnwrap(todoRepo.fetchTodo(id: "todo-1"))
        let decoded = try JSONDecoder().decode([LaunchResource].self, from: Data(merged.launchResources.utf8))
        XCTAssertEqual(decoded.count, 1)
        XCTAssertEqual(decoded.first?.type, .url)
    }

    func testReplaceImportCreatesBackupSnapshotBeforeMutation() throws {
        let manager = try makeManager()
        try seedBasicData(manager)
        let service = makeService(manager)

        let data = try service.exportToJSON()
        let report = try service.executeImportJSON(data, mode: .replace)

        XCTAssertNotNil(report.backupFilePath)
        XCTAssertTrue(FileManager.default.fileExists(atPath: report.backupFilePath ?? ""))
    }

    func testMergeImportKeepsUnrelatedLocalRows() throws {
        let manager = try makeManager()
        let service = makeService(manager)
        try seedBasicData(manager)

        try manager.dbQueue.write { db in
            let extra = TodoRecord(
                id: "todo-local",
                title: "Local",
                isCompleted: false,
                isImportant: false,
                isMyDay: false,
                recurrence: nil,
                recurrenceInterval: 1,
                lastCompletedAt: nil,
                notes: "",
                launchResources: "[]",
                dueDate: nil,
                sortOrder: 10,
                createdAt: Date(),
                updatedAt: Date(),
                listId: nil,
                focusTimeSeconds: 0
            )
            try extra.insert(db)
        }

        let data = try service.exportToJSON()
        _ = try service.executeImportJSON(data, mode: .merge)

        let todoRepo = TodoRepository(dbQueue: manager.dbQueue)
        let local = try todoRepo.fetchTodo(id: "todo-local")
        XCTAssertNotNil(local)
    }

    func testMergeImportCanClearExistingLaunchResources() throws {
        let manager = try makeManager()
        let service = makeService(manager)
        try seedBasicData(manager)

        // Export current dataset and then modify payload to clear launch resources for todo-1.
        let exported = try service.exportToJSON()
        var payload = try ExportData.decode(from: exported)
        let updatedTodos = payload.todos.map { todo -> ExportTodo in
            guard todo.id == "todo-1" else { return todo }
            return ExportTodo(
                id: todo.id,
                title: todo.title,
                isCompleted: todo.isCompleted,
                isImportant: todo.isImportant,
                isMyDay: todo.isMyDay,
                dueDate: todo.dueDate,
                notes: todo.notes,
                listId: todo.listId,
                focusTimeSeconds: todo.focusTimeSeconds,
                recurrence: todo.recurrence,
                recurrenceInterval: todo.recurrenceInterval,
                sortOrder: todo.sortOrder,
                createdAt: todo.createdAt,
                updatedAt: todo.updatedAt,
                lastCompletedAt: todo.lastCompletedAt,
                steps: todo.steps,
                launchResources: []
            )
        }
        payload = ExportData(
            version: payload.version,
            exportedAt: payload.exportedAt,
            meta: payload.meta,
            lists: payload.lists,
            todos: updatedTodos
        )

        _ = try service.executeImportJSON(try payload.encode(), mode: .merge)

        let todoRepo = TodoRepository(dbQueue: manager.dbQueue)
        let merged = try XCTUnwrap(todoRepo.fetchTodo(id: "todo-1"))
        XCTAssertEqual(merged.launchResources, "[]")
    }

    func testExportIncludesTemporalFields() throws {
        let manager = try makeManager()
        try seedBasicData(manager)
        let service = makeService(manager)

        let data = try service.exportToJSON()
        let payload = try ExportData.decode(from: data)
        let todo = try XCTUnwrap(payload.todos.first)

        XCTAssertNotNil(todo.createdAt)
        XCTAssertNotNil(todo.updatedAt)
    }

    func testReplaceImportPreservesTemporalFieldsFromPayload() throws {
        let manager = try makeManager()
        let service = makeService(manager)
        let createdAt = Date(timeIntervalSince1970: 1_700_000_000)
        let updatedAt = Date(timeIntervalSince1970: 1_700_000_100)
        let lastCompletedAt = Date(timeIntervalSince1970: 1_700_000_200)

        let payload = ExportData(
            version: ExportFormatVersion.current,
            exportedAt: Date(),
            meta: nil,
            lists: [
                ExportList(id: "list-1", name: "Work", color: "#C46849", sortOrder: 0)
            ],
            todos: [
                ExportTodo(
                    id: "todo-1",
                    title: "Imported",
                    isCompleted: true,
                    isImportant: false,
                    isMyDay: false,
                    dueDate: nil,
                    notes: "",
                    listId: "list-1",
                    focusTimeSeconds: 0,
                    recurrence: nil,
                    recurrenceInterval: 1,
                    sortOrder: 0,
                    createdAt: createdAt,
                    updatedAt: updatedAt,
                    lastCompletedAt: lastCompletedAt,
                    steps: [],
                    launchResources: []
                )
            ]
        )

        _ = try service.executeImportJSON(try payload.encode(), mode: .replace)
        let todo = try XCTUnwrap(TodoRepository(dbQueue: manager.dbQueue).fetchTodo(id: "todo-1"))

        XCTAssertEqual(todo.createdAt, createdAt)
        XCTAssertEqual(todo.updatedAt, updatedAt)
        XCTAssertEqual(todo.lastCompletedAt, lastCompletedAt)
    }

    func testPreflightRejectsTodoListReferenceMissingInReplaceMode() throws {
        let manager = try makeManager()
        let service = makeService(manager)

        let payload = """
        {
          "version": "1.2",
          "exportedAt": "2026-03-30T12:00:00Z",
          "lists": [],
          "todos": [
            {
              "id": "todo-1",
              "title": "Imported",
              "isCompleted": false,
              "isImportant": false,
              "isMyDay": false,
              "dueDate": null,
              "notes": "",
              "listId": "missing-list",
              "focusTimeSeconds": 0,
              "recurrence": null,
              "recurrenceInterval": 1,
              "sortOrder": 0,
              "steps": [],
              "launchResources": []
            }
          ]
        }
        """.data(using: .utf8)!

        let preflight = try service.preflightImportJSON(payload, mode: .replace)
        XCTAssertTrue(preflight.blockingErrors.contains(where: { $0.contains("missing listId") }))
    }

    func testMergeImportSkipsStepCollisionAcrossTodos() throws {
        let manager = try makeManager()
        let service = makeService(manager)

        try manager.dbQueue.write { db in
            let list = ListRecord(
                id: "list-1",
                name: "Work",
                color: "#C46849",
                sortOrder: 0,
                createdAt: Date(),
                updatedAt: Date()
            )
            try list.insert(db)

            let localTodo = TodoRecord(
                id: "todo-local",
                title: "Local",
                isCompleted: false,
                isImportant: false,
                isMyDay: false,
                recurrence: nil,
                recurrenceInterval: 1,
                lastCompletedAt: nil,
                notes: "",
                launchResources: "[]",
                dueDate: nil,
                sortOrder: 0,
                createdAt: Date(),
                updatedAt: Date(),
                listId: "list-1",
                focusTimeSeconds: 0
            )
            try localTodo.insert(db)

            let localStep = StepRecord(id: "step-shared", title: "Local Step", isCompleted: false, sortOrder: 0, todoId: "todo-local")
            try localStep.insert(db)
        }

        let payload = ExportData(
            version: ExportFormatVersion.current,
            exportedAt: Date(),
            meta: nil,
            lists: [ExportList(id: "list-1", name: "Work", color: "#C46849", sortOrder: 0)],
            todos: [
                ExportTodo(
                    id: "todo-import",
                    title: "Imported",
                    isCompleted: false,
                    isImportant: false,
                    isMyDay: false,
                    dueDate: nil,
                    notes: "",
                    listId: "list-1",
                    focusTimeSeconds: 0,
                    recurrence: nil,
                    recurrenceInterval: 1,
                    sortOrder: 1,
                    createdAt: nil,
                    updatedAt: nil,
                    lastCompletedAt: nil,
                    steps: [ExportStep(id: "step-shared", title: "Imported Step", isCompleted: false, sortOrder: 0)],
                    launchResources: []
                )
            ]
        )

        let report = try service.executeImportJSON(try payload.encode(), mode: .merge)
        XCTAssertEqual(report.skipped.steps, 1)

        let steps = try manager.dbQueue.read { db in
            try StepRecord.fetchAll(db)
        }
        let shared = try XCTUnwrap(steps.first { $0.id == "step-shared" })
        XCTAssertEqual(shared.todoId, "todo-local")
    }
}
