# Data Export/Import Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add Import/Export functionality to Settings page, allowing users to export all data as JSON and import from it.

**Architecture:** Create ExportModels (Codable DTOs), ExportService (serialization logic), extend DatabaseManager with clearAllTables(), add UI buttons to Settings.

**Tech Stack:** Swift, GRDB, NSSavePanel/NSOpenPanel, Codable

---

## Task 1: Create ExportModels.swift with Codable DTOs

**Files:**
- Create: `macos/TodoFocusMac/Sources/Data/Export/ExportModels.swift`

**Step 1: Create the file with Codable structs**

```swift
import Foundation

struct ExportData: Codable {
    let version: String
    let exportedAt: Date
    let lists: [ExportList]
    let todos: [ExportTodo]
}

struct ExportList: Codable {
    let id: String
    let name: String
    let color: String
    let sortOrder: Int
}

struct ExportTodo: Codable {
    let id: String
    let title: String
    let isCompleted: Bool
    let isImportant: Bool
    let isMyDay: Bool
    let dueDate: Date?
    let notes: String
    let listId: String?
    let focusTimeSeconds: Int?
    let steps: [ExportStep]
    let launchResources: [ExportLaunchResource]
}

struct ExportStep: Codable {
    let id: String
    let title: String
    let isCompleted: Bool
    let sortOrder: Int
}

struct ExportLaunchResource: Codable {
    let type: String
    let value: String
}
```

**Step 2: Add JSON encoding/decoding extensions**

Add to ExportModels.swift:
```swift
extension ExportData {
    static func decode(from data: Data) throws -> ExportData {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(ExportData.self, from: data)
    }

    func encode() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(self)
    }
}
```

**Step 3: Commit**
```bash
git add macos/TodoFocusMac/Sources/Data/Export/ExportModels.swift
git commit -m "feat(export): add ExportModels with Codable structs"
```

---

## Task 2: Create ExportService.swift

**Files:**
- Create: `macos/TodoFocusMac/Sources/Data/Export/ExportService.swift`
- Modify: `macos/TodoFocusMac/Sources/Data/Export/ExportModels.swift` (already created in Task 1)

**Step 1: Create ExportService with export logic**

```swift
import Foundation
import GRDB

final class ExportService {
    private let dbQueue: DatabaseQueue

    init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }

    func exportToJSON() throws -> Data {
        let lists = try dbQueue.read { db in
            try ListRecord.fetchAll(db).map { record in
                ExportList(
                    id: record.id,
                    name: record.name,
                    color: record.color,
                    sortOrder: record.sortOrder
                )
            }
        }

        let todos = try dbQueue.read { db in
            try TodoRecord.fetchAll(db).map { record in
                let steps = try StepRecord.filter(Column("todoId") == record.id).fetchAll(db)
                let exportSteps = steps.map { step in
                    ExportStep(
                        id: step.id,
                        title: step.title,
                        isCompleted: step.isCompleted,
                        sortOrder: step.sortOrder
                    )
                }

                let resources = (try? decodeLaunchResources(record.launchResources)) ?? []

                return ExportTodo(
                    id: record.id,
                    title: record.title,
                    isCompleted: record.isCompleted,
                    isImportant: record.isImportant,
                    isMyDay: record.isMyDay,
                    dueDate: record.dueDate,
                    notes: record.notes ?? "",
                    listId: record.listId,
                    focusTimeSeconds: record.focusTimeSeconds,
                    steps: exportSteps,
                    launchResources: resources.map { ExportLaunchResource(type: $0.type.rawValue, value: $0.value) }
                )
            }
        }

        let exportData = ExportData(
            version: "1.0",
            exportedAt: Date(),
            lists: lists,
            todos: todos
        )

        return try exportData.encode()
    }

    private func decodeLaunchResources(_ raw: String?) throws -> [LaunchResource] {
        guard let raw, !raw.isEmpty else { return [] }
        return try JSONDecoder().decode([LaunchResource].self, from: Data(raw.utf8))
    }
}
```

**Step 2: Commit**
```bash
git add macos/TodoFocusMac/Sources/Data/Export/ExportService.swift
git commit -m "feat(export): add ExportService with exportToJSON logic"
```

---

## Task 3: Add clearAllTables() to DatabaseManager

**Files:**
- Modify: `macos/TodoFocusMac/Sources/Data/Database/DatabaseManager.swift`

**Step 1: Read the DatabaseManager file to understand its structure**

**Step 2: Add clearAllTables() method**

```swift
func clearAllTables() throws {
    try dbQueue.write { db in
        try db.execute(sql: "DELETE FROM step")
        try db.execute(sql: "DELETE FROM todo")
        try db.execute(sql: "DELETE FROM list")
    }
}
```

**Step 3: Commit**
```bash
git add macos/TodoFocusMac/Sources/Data/Database/DatabaseManager.swift
git commit -m "feat(export): add clearAllTables() for import reset"
```

---

## Task 4: Add importToJSON() to ExportService

**Files:**
- Modify: `macos/TodoFocusMac/Sources/Data/Export/ExportService.swift`

**Step 1: Add importFromJSON method**

```swift
func importFromJSON(_ data: Data) throws {
    let importData = try ExportData.decode(from: data)

    guard importData.version == "1.0" else {
        throw ExportError.unsupportedVersion
    }

    try dbQueue.write { db in
        // Clear existing data
        try db.execute(sql: "DELETE FROM step")
        try db.execute(sql: "DELETE FROM todo")
        try db.execute(sql: "DELETE FROM list")

        // Import lists
        for list in importData.lists {
            var record = ListRecord()
            record.id = list.id
            record.name = list.name
            record.color = list.color
            record.sortOrder = list.sortOrder
            try record.insert(db)
        }

        // Import todos
        for todo in importData.todos {
            var record = TodoRecord()
            record.id = todo.id
            record.title = todo.title
            record.isCompleted = todo.isCompleted
            record.isImportant = todo.isImportant
            record.isMyDay = todo.isMyDay
            record.dueDate = todo.dueDate
            record.notes = todo.notes.isEmpty ? nil : todo.notes
            record.listId = todo.listId
            record.focusTimeSeconds = todo.focusTimeSeconds
            try record.insert(db)

            // Import steps
            for step in todo.steps {
                var stepRecord = StepRecord()
                stepRecord.id = step.id
                stepRecord.title = step.title
                stepRecord.isCompleted = step.isCompleted
                stepRecord.sortOrder = step.sortOrder
                stepRecord.todoId = todo.id
                try stepRecord.insert(db)
            }

            // Import launch resources
            if !todo.launchResources.isEmpty {
                let resources = todo.launchResources.map { er in
                    LaunchResource(type: LaunchResourceType(rawValue: er.type) ?? .url, value: er.value)
                }
                let encoded = try JSONEncoder().encode(resources)
                try db.execute(
                    sql: "UPDATE todo SET launchResources = ? WHERE id = ?",
                    arguments: [String(data: encoded, encoding: .utf8), todo.id]
                )
            }
        }
    }
}

enum ExportError: Error, LocalizedError {
    case unsupportedVersion

    var errorDescription: String? {
        switch self {
        case .unsupportedVersion:
            return "Unsupported export file version"
        }
    }
}
```

**Step 2: Commit**
```bash
git add macos/TodoFocusMac/Sources/Data/Export/ExportService.swift
git commit -m "feat(export): add importFromJSON with replacement strategy"
```

---

## Task 5: Add Export/Import buttons to Settings

**Files:**
- Find: Settings view file in `macos/TodoFocusMac/Sources/Features/`
- Modify: Settings view to add buttons

**Step 1: Find the Settings view**

```bash
find macos/TodoFocusMac/Sources -name "*Settings*" -o -name "*Setting*" | head -10
```

**Step 2: Add Export/Import buttons**

In Settings view, add two buttons:
```swift
Button("Export Data") {
    exportData()
}
.buttonStyle(.bordered)

Button("Import Data") {
    importData()
}
.buttonStyle(.bordered)
```

**Step 3: Wire up ExportService calls**

```swift
@State private var showingExportPanel = false
@State private var showingImportPanel = false
@State private var exportError: String?
@State private var importError: String?

private var exportService: ExportService

func exportData() {
    do {
        let data = try exportService.exportToJSON()
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "TodoFocus-export.json"
        panel.canCreateDirectories = true

        if panel.runModal() == .OK, let url = panel.url {
            try data.write(to: url)
        }
    } catch {
        exportError = error.localizedDescription
    }
}

func importData() {
    let panel = NSOpenPanel()
    panel.allowedContentTypes = [.json]
    panel.canChooseFiles = true
    panel.canChooseDirectories = false
    panel.allowsMultipleSelection = false

    if panel.runModal() == .OK, let url = panel.url {
        do {
            let data = try Data(contentsOf: url)
            try exportService.importFromJSON(data)
            // Reload data in store
        } catch {
            importError = error.localizedDescription
        }
    }
}
```

**Step 4: Commit**
```bash
git add macos/TodoFocusMac/Sources/Features/...
git commit -m "feat(export): add Export/Import buttons to Settings"
```

---

## Task 6: Test round-trip export/import

**Files:**
- Test: `macos/TodoFocusMac/Tests/`

**Step 1: Write test**

```swift
func testExportImportRoundTrip() throws {
    // Setup: create some data
    let listId = try listRepository.createList(name: "Test List", color: "#FF0000")
    let todo = try todoRepository.addTodo(
        AddTodoInput(title: "Test Todo", listID: listId, isMyDay: false, isImportant: true, planned: false)
    )

    // Export
    let data = try exportService.exportToJSON()
    let decoded = try ExportData.decode(from: data)

    XCTAssertEqual(decoded.lists.count, 1)
    XCTAssertEqual(decoded.todos.count, 1)
    XCTAssertEqual(decoded.todos.first?.title, "Test Todo")
    XCTAssertEqual(decoded.version, "1.0")
}

func testImportClearsExistingData() throws {
    // Setup: create data
    let listId = try listRepository.createList(name: "Original", color: "#000000")

    // Import
    let exportData = ExportData(
        version: "1.0",
        exportedAt: Date(),
        lists: [ExportList(id: "new-list", name: "Imported", color: "#00FF00", sortOrder: 0)],
        todos: []
    )
    let data = try exportData.encode()
    try exportService.importFromJSON(data)

    // Verify old data is gone
    let lists = try listRepository.fetchListsOrdered()
    XCTAssertEqual(lists.count, 1)
    XCTAssertEqual(lists.first?.name, "Imported")
}
```

**Step 2: Run tests**

```bash
xcodebuild test -project macos/TodoFocusMac/TodoFocusMac.xcodeproj -scheme TodoFocusMac -destination platform=macOS -only-testing:DataTests/ExportServiceTests
```

**Step 3: Commit**
```bash
git add macos/TodoFocusMac/Tests/...
git commit -m "test(export): add round-trip and clear tests"
```

---

## Verification Checklist

After all tasks:
- [ ] Build succeeds: `xcodebuild build -project macos/TodoFocusMac/TodoFocusMac.xcodeproj -scheme TodoFocusMac -destination platform=macOS`
- [ ] Tests pass
- [ ] Export creates valid JSON file
- [ ] Import restores all data
- [ ] Import clears existing data first
