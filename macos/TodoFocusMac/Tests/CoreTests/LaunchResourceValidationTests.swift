import Foundation
import XCTest
@testable import TodoFocusMac

final class LaunchResourceValidationTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_763_520_000)

    private func makeManager() throws -> DatabaseManager {
        let path = NSTemporaryDirectory() + UUID().uuidString + ".sqlite"
        return try DatabaseManager(databasePath: path)
    }

    private func makeExportService(_ manager: DatabaseManager) -> ExportService {
        ExportService(dbQueue: manager.dbQueue)
    }

    func testValidateURLAcceptsHTTPSAndTrimsFields() {
        let resource = makeResource(
            id: " ",
            type: .url,
            label: "  Docs  ",
            value: "  https://example.com/docs  "
        )

        let result = validateLaunchResource(resource)

        guard case let .success(value) = result else {
            return XCTFail("Expected valid URL resource")
        }

        XCTAssertEqual(value.type, .url)
        XCTAssertEqual(value.label, "Docs")
        XCTAssertEqual(value.value, "https://example.com/docs")
        XCTAssertFalse(value.id.isEmpty)
    }

    func testValidateLabelRejectsEmptyAfterTrim() {
        let resource = makeResource(type: .url, label: "   ", value: "https://example.com")

        let result = validateLaunchResource(resource)

        XCTAssertEqual(result, .failure(.invalidLabel))
    }

    func testValidateLabelRejectsOverEightyCharacters() {
        let resource = makeResource(type: .url, label: String(repeating: "a", count: 81), value: "https://example.com")

        let result = validateLaunchResource(resource)

        XCTAssertEqual(result, .failure(.invalidLabel))
    }

    func testValidateURLRejectsNonHTTPProtocols() {
        let resource = makeResource(type: .url, label: "Bad", value: "javascript:alert(1)")

        let result = validateLaunchResource(resource)

        XCTAssertEqual(result, .failure(.invalidURL))
    }

    func testValidateFileRequiresAbsolutePath() {
        let resource = makeResource(type: .file, label: "Notes", value: "./notes/today.md")

        let result = validateLaunchResource(resource)

        XCTAssertEqual(result, .failure(.invalidFilePath))
    }

    func testValidateFileRejectsTraversalPattern() {
        let resource = makeResource(type: .file, label: "Unsafe", value: "/Users/me/../secret.txt")

        let result = validateLaunchResource(resource)

        XCTAssertEqual(result, .failure(.invalidFilePath))
    }

    func testValidateAppAcceptsAbsoluteAppBundlePath() {
        let resource = makeResource(type: .app, label: "Obsidian", value: "/Applications/Obsidian.app")

        let result = validateLaunchResource(resource)

        guard case let .success(value) = result else {
            return XCTFail("Expected valid app path")
        }

        XCTAssertEqual(value.value, "/Applications/Obsidian.app")
    }

    func testValidateAppAcceptsAllowlistedDeepLink() {
        let resource = makeResource(type: .app, label: "Obsidian", value: "obsidian://open?vault=personal")

        let result = validateLaunchResource(resource)

        guard case .success = result else {
            return XCTFail("Expected valid deep link")
        }
    }

    func testValidateAppRejectsUnallowlistedDeepLink() {
        let resource = makeResource(type: .app, label: "Unsafe", value: "slack://channel")

        let result = validateLaunchResource(resource)

        XCTAssertEqual(result, .failure(.invalidAppTarget))
    }

    func testParseLaunchResourcesReturnsEmptyForMalformedJSON() {
        XCTAssertEqual(parseLaunchResources(raw: "not-json"), [])
    }

    func testParseLaunchResourcesEnforcesResourceLimitAndFiltersInvalidEntries() {
        let validItems: [[String: String]] = (1...15).map { index in
            [
                "id": "id-\(index)",
                "type": "url",
                "label": "Link \(index)",
                "value": "https://example.com/\(index)",
                "createdAt": "2026-03-21T00:00:00.000Z"
            ]
        }

        var payload: [Any] = validItems
        payload.insert([
            "id": "bad",
            "type": "url",
            "label": "Bad",
            "value": "javascript:alert(1)",
            "createdAt": "2026-03-21T00:00:00.000Z"
        ], at: 0)

        let data = try! JSONSerialization.data(withJSONObject: payload)
        let raw = String(data: data, encoding: .utf8)

        let parsed = parseLaunchResources(raw: raw)

        XCTAssertEqual(parsed.count, 12)
        XCTAssertTrue(parsed.allSatisfy { $0.type == .url })
        XCTAssertTrue(parsed.allSatisfy { $0.value.hasPrefix("https://") })
    }

    func testParseLaunchResourcesRejectsOversizedPayload() {
        let raw = String(repeating: "a", count: 16_001)
        XCTAssertEqual(parseLaunchResources(raw: raw), [])
    }

    func testTrySerializeLaunchResourcesTrimsToMaxResourceCount() {
        let items = (1...14).map { index in
            makeResource(
                id: "id-\(index)",
                type: .url,
                label: "Link \(index)",
                value: "https://example.com/\(index)"
            )
        }

        let result = trySerializeLaunchResources(items)

        guard case let .ok(serialized) = result else {
            return XCTFail("Expected serialization to succeed")
        }

        let parsed = parseLaunchResources(raw: serialized)
        XCTAssertEqual(parsed.count, 12)
    }

    func testTrySerializeLaunchResourcesReturnsPayloadTooLarge() {
        let hugeValue = "https://example.com/" + String(repeating: "x", count: 4_000)
        let items = (1...12).map { index in
            makeResource(
                id: "id-\(index)",
                type: .url,
                label: "Huge \(index)",
                value: hugeValue
            )
        }

        let result = trySerializeLaunchResources(items)
        XCTAssertEqual(result, .payloadTooLarge)
    }

    func testImportRejectsAndReportsInvalidURLLaunchResourcePayload() throws {
        let manager = try makeManager()
        let service = makeExportService(manager)
        let payload = try makeImportPayload(launchResources: [
            ["type": "url", "value": "https://example.com", "label": "Docs"],
            ["type": "url", "value": "javascript:alert(1)", "label": "Unsafe"]
        ])

        let report = try service.executeImportJSON(payload, mode: .replace)

        XCTAssertEqual(report.created.launchResources, 1)
        XCTAssertEqual(report.skipped.launchResources, 1)
        XCTAssertTrue(report.errors.contains(where: { $0.contains("Invalid URL launch resource") }))

        let todo = try XCTUnwrap(TodoRepository(dbQueue: manager.dbQueue).fetchTodo(id: "todo-1"))
        let decoded = try JSONDecoder().decode([LaunchResource].self, from: Data(todo.launchResources.utf8))
        XCTAssertEqual(decoded.count, 1)
        XCTAssertEqual(decoded.first?.value, "https://example.com")
    }

    func testImportKeepsValidURLAndSkipsNonPortableResources() throws {
        let manager = try makeManager()
        let service = makeExportService(manager)
        let payload = try makeImportPayload(launchResources: [
            ["type": "url", "value": "https://example.com/docs", "label": "Docs"],
            ["type": "file", "value": "/tmp/spec.md", "label": "Spec"]
        ])

        let report = try service.executeImportJSON(payload, mode: .replace)

        XCTAssertEqual(report.created.launchResources, 1)
        XCTAssertEqual(report.skipped.launchResources, 1)
        XCTAssertTrue(report.errors.isEmpty)

        let todo = try XCTUnwrap(TodoRepository(dbQueue: manager.dbQueue).fetchTodo(id: "todo-1"))
        let decoded = try JSONDecoder().decode([LaunchResource].self, from: Data(todo.launchResources.utf8))
        XCTAssertEqual(decoded.count, 1)
        XCTAssertEqual(decoded.first?.value, "https://example.com/docs")
    }

    private func makeImportPayload(launchResources: [[String: String]]) throws -> Data {
        let payload: [String: Any] = [
            "version": "1.2",
            "exportedAt": "2026-03-30T12:00:00Z",
            "lists": [
                [
                    "id": "list-1",
                    "name": "Work",
                    "color": "#C46849",
                    "sortOrder": 0
                ]
            ],
            "todos": [
                [
                    "id": "todo-1",
                    "title": "Imported",
                    "isCompleted": false,
                    "isImportant": false,
                    "isMyDay": false,
                    "dueDate": NSNull(),
                    "notes": "",
                    "listId": "list-1",
                    "focusTimeSeconds": 0,
                    "recurrence": NSNull(),
                    "recurrenceInterval": 1,
                    "sortOrder": 0,
                    "steps": [],
                    "launchResources": launchResources
                ]
            ]
        ]

        return try JSONSerialization.data(withJSONObject: payload)
    }

    private func makeResource(
        id: String = "id",
        type: LaunchResourceType,
        label: String,
        value: String
    ) -> LaunchResource {
        LaunchResource(id: id, type: type, label: label, value: value, createdAt: now)
    }
}
