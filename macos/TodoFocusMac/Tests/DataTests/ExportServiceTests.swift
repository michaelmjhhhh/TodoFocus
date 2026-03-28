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

    func testImportReplaceReturnsStructuredReport() throws {
        let manager = try makeManager()
        try seedBasicData(manager)
        let service = makeService(manager)

        let data = try service.exportToJSON()
        let report = try service.executeImportJSON(data, mode: .replace)

        XCTAssertGreaterThanOrEqual(report.created.todos, 1)
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
}
