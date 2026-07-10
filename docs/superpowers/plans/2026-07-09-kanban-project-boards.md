# Kanban Project Boards Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a dedicated, persistent Kanban area for multiple long-term projects with five fixed workflow columns, manually ordered project cards, labels, checklists, archiving, and a right-side detail panel.

**Architecture:** Build Kanban as an isolated SwiftUI + Observation module backed by four GRDB tables. A `KanbanRepository` owns transactional persistence, while `KanbanStore` owns view state and publishes only confirmed repository state. `RootView` routes the new sidebar selection to the board and reuses the existing resizable detail-panel seam without allowing Kanban records to enter daily Todo flows.

**Tech Stack:** Swift 6, SwiftUI on macOS 14+, Observation (`@Observable`), GRDB + SQLite, XCTest, XcodeGen.

## Global Constraints

- Keep Kanban projects and cards separate from `Todo`, `TodoRepository`, `TodoAppStore`, daily task search, Daily Review, Deep Focus, Quick Capture, and Launchpad.
- Use exactly five statuses in this order: Backlog, Ready, In Progress, Blocked, Done.
- Use exactly four priorities: Low, Medium, High, Urgent.
- Keep Done cards visible until manual archive or delete.
- Persist dense zero-based card order within each project/status; cross-column moves update both columns transactionally.
- Limit project names to 100 characters and non-empty goals to 500 characters.
- Limit card titles to 200 characters and descriptions to 10,000 characters.
- Limit label names to 40 characters and each card to 10 labels.
- Limit checklist titles to 200 characters and each card to 50 checklist items.
- Validate project colors as `#RRGGBB`.
- Invalid persisted status falls back to Backlog; invalid priority falls back to Medium; either fallback surfaces a repair banner.
- Do not add custom columns, collaboration, cloud sync, task links, focus/Launchpad integration, GitHub sync, templates, analytics, estimates, or changes to Daily Review.
- Follow TDD for every behavior change and keep commits scoped to one task.
- Before final completion run `xcodegen generate`, the full macOS test suite, and a Release build.

---

## File Structure

### Core domain

- Create `macos/TodoFocusMac/Sources/Core/Kanban/KanbanModels.swift` — statuses, priorities, project/card/label/checklist value types, and board-column projection.
- Create `macos/TodoFocusMac/Sources/Core/Kanban/KanbanValidation.swift` — named limits, trimming, color validation, and typed validation errors.
- Create `macos/TodoFocusMac/Sources/Core/Kanban/KanbanOrdering.swift` — pure dense-order and move calculations.

### Persistence

- Modify `macos/TodoFocusMac/Sources/Data/Database/Migrations.swift` — add migration `v5_kanban_project_boards`.
- Modify `macos/TodoFocusMac/Sources/Data/Database/DatabaseManager.swift` — include Kanban tables in `clearAllTables()`.
- Create `macos/TodoFocusMac/Sources/Data/DTO/KanbanProjectRecord.swift`.
- Create `macos/TodoFocusMac/Sources/Data/DTO/KanbanCardRecord.swift`.
- Create `macos/TodoFocusMac/Sources/Data/DTO/KanbanCardLabelRecord.swift`.
- Create `macos/TodoFocusMac/Sources/Data/DTO/KanbanChecklistItemRecord.swift`.
- Create `macos/TodoFocusMac/Sources/Data/DTO/KanbanRecordMappings.swift` — safe enum decoding and domain aggregation.
- Create `macos/TodoFocusMac/Sources/Data/Repositories/KanbanRepository.swift` — protocol, inputs, errors, shared transaction helpers.
- Create `macos/TodoFocusMac/Sources/Data/Repositories/KanbanProjectRepository.swift` — project CRUD.
- Create `macos/TodoFocusMac/Sources/Data/Repositories/KanbanCardRepository.swift` — card CRUD, archive/restore, and transactional moves.
- Create `macos/TodoFocusMac/Sources/Data/Repositories/KanbanCardChildrenRepository.swift` — labels and checklist CRUD/reordering.

### State and navigation

- Create `macos/TodoFocusMac/Sources/App/KanbanStore.swift` — observable project/card state, selection, mutation orchestration, rollback, debouncing, and errors.
- Modify `macos/TodoFocusMac/Sources/App/SelectionState.swift` — add `.kanban`.
- Modify `macos/TodoFocusMac/Sources/App/AppModel.swift` — add `kanban` active-view identity.
- Modify `macos/TodoFocusMac/Sources/TodoFocusMacApp.swift` — construct and inject `KanbanRepository` and `KanbanStore`.
- Modify `macos/TodoFocusMac/Sources/RootView.swift` — route Kanban and show its detail panel.
- Modify `macos/TodoFocusMac/Sources/Features/Sidebar/SidebarView.swift` — add Kanban sidebar item.

### Views

- Create `macos/TodoFocusMac/Sources/Features/Kanban/KanbanView.swift` — feature shell, loading/error/empty states, project switcher, and project forms.
- Create `macos/TodoFocusMac/Sources/Features/Kanban/KanbanBoardView.swift` — horizontal board and fixed status columns.
- Create `macos/TodoFocusMac/Sources/Features/Kanban/KanbanColumnView.swift` — column header, count, composer, card list, and bottom drop target.
- Create `macos/TodoFocusMac/Sources/Features/Kanban/KanbanCardView.swift` — card summary and per-card insertion drop target.
- Create `macos/TodoFocusMac/Sources/Features/Kanban/KanbanCardDragPayload.swift` — native transferable payload.
- Create `macos/TodoFocusMac/Sources/Features/Kanban/KanbanCardDetailView.swift` — all card fields, status alternative, labels, checklist, archive, and delete.
- Create `macos/TodoFocusMac/Sources/Features/Kanban/KanbanArchiveView.swift` — restore and permanent-delete sheet.

### Tests

- Create `macos/TodoFocusMac/Tests/CoreTests/KanbanModelTests.swift`.
- Create `macos/TodoFocusMac/Tests/CoreTests/KanbanOrderingTests.swift`.
- Create `macos/TodoFocusMac/Tests/CoreTests/KanbanStoreTests.swift`.
- Create `macos/TodoFocusMac/Tests/CoreTests/KanbanViewBehaviorTests.swift`.
- Create `macos/TodoFocusMac/Tests/DataTests/KanbanMigrationTests.swift`.
- Create `macos/TodoFocusMac/Tests/DataTests/KanbanRepositoryTests.swift`.

---

### Task 1: Core Kanban Domain, Validation, and Ordering

**Files:**
- Create: `macos/TodoFocusMac/Sources/Core/Kanban/KanbanModels.swift`
- Create: `macos/TodoFocusMac/Sources/Core/Kanban/KanbanValidation.swift`
- Create: `macos/TodoFocusMac/Sources/Core/Kanban/KanbanOrdering.swift`
- Test: `macos/TodoFocusMac/Tests/CoreTests/KanbanModelTests.swift`
- Test: `macos/TodoFocusMac/Tests/CoreTests/KanbanOrderingTests.swift`

**Interfaces:**
- Consumes: Foundation only.
- Produces: `KanbanStatus`, `KanbanPriority`, `KanbanProject`, `KanbanCard`, `KanbanCardLabel`, `KanbanChecklistItem`, `KanbanColumn`, `KanbanValidation`, `KanbanValidationError`, and `KanbanOrdering.move(...)`.

- [ ] **Step 1: Write failing model and validation tests**

```swift
import XCTest
@testable import TodoFocusMac

final class KanbanModelTests: XCTestCase {
    func testStatusesStayInProductOrder() {
        XCTAssertEqual(KanbanStatus.allCases, [.backlog, .ready, .inProgress, .blocked, .done])
        XCTAssertEqual(KanbanStatus.allCases.map(\.title), ["Backlog", "Ready", "In Progress", "Blocked", "Done"])
    }

    func testInvalidRawValuesUseSpecifiedFallbacks() {
        XCTAssertEqual(KanbanStatus.persisted("unknown").value, .backlog)
        XCTAssertTrue(KanbanStatus.persisted("unknown").usedFallback)
        XCTAssertEqual(KanbanPriority.persisted("unknown").value, .medium)
        XCTAssertTrue(KanbanPriority.persisted("unknown").usedFallback)
    }

    func testValidationTrimsAndEnforcesLimits() throws {
        XCTAssertEqual(try KanbanValidation.projectName("  Apollo  "), "Apollo")
        XCTAssertEqual(try KanbanValidation.projectGoal("  Ship v1  "), "Ship v1")
        XCTAssertThrowsError(try KanbanValidation.projectName(String(repeating: "a", count: 101)))
        XCTAssertThrowsError(try KanbanValidation.cardDescription(String(repeating: "a", count: 10_001)))
        XCTAssertThrowsError(try KanbanValidation.color("terracotta"))
        XCTAssertEqual(try KanbanValidation.color("#C46849"), "#C46849")
    }
}
```

- [ ] **Step 2: Write failing dense-order tests**

```swift
import XCTest
@testable import TodoFocusMac

final class KanbanOrderingTests: XCTestCase {
    func testMoveWithinColumnProducesDenseOrder() {
        let result = KanbanOrdering.move(cardID: "c", from: ["a", "b", "c"], to: ["a", "b", "c"], destinationIndex: 0)
        XCTAssertEqual(result.source, ["c", "a", "b"])
        XCTAssertEqual(result.destination, ["c", "a", "b"])
    }

    func testMoveAcrossColumnsProducesDenseOrder() {
        let result = KanbanOrdering.move(cardID: "b", from: ["a", "b", "c"], to: ["x", "y"], destinationIndex: 1)
        XCTAssertEqual(result.source, ["a", "c"])
        XCTAssertEqual(result.destination, ["x", "b", "y"])
    }
}
```

- [ ] **Step 3: Run the tests to verify they fail**

Run:

```bash
cd macos/TodoFocusMac
xcodegen generate
xcodebuild test -project TodoFocusMac.xcodeproj -scheme TodoFocusMac -destination 'platform=macOS' \
  -only-testing:CoreTests/KanbanModelTests \
  -only-testing:CoreTests/KanbanOrderingTests
```

Expected: FAIL because the Kanban types do not exist.

- [ ] **Step 4: Implement the domain types and validation constants**

```swift
import Foundation

enum KanbanStatus: String, CaseIterable, Codable, Identifiable {
    case backlog, ready, inProgress, blocked, done
    var id: String { rawValue }
    var title: String {
        switch self {
        case .backlog: "Backlog"
        case .ready: "Ready"
        case .inProgress: "In Progress"
        case .blocked: "Blocked"
        case .done: "Done"
        }
    }
    static func persisted(_ raw: String) -> (value: KanbanStatus, usedFallback: Bool) {
        guard let value = Self(rawValue: raw) else { return (.backlog, true) }
        return (value, false)
    }
}

enum KanbanPriority: String, CaseIterable, Codable, Identifiable {
    case low, medium, high, urgent
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    static func persisted(_ raw: String) -> (value: KanbanPriority, usedFallback: Bool) {
        guard let value = Self(rawValue: raw) else { return (.medium, true) }
        return (value, false)
    }
}

struct KanbanProject: Identifiable, Equatable {
    let id: String
    var name: String
    var color: String
    var goal: String
    var createdAt: Date
    var updatedAt: Date
}

struct KanbanCardLabel: Identifiable, Equatable { let id: String; let cardID: String; var name: String; var sortOrder: Int }
struct KanbanChecklistItem: Identifiable, Equatable { let id: String; let cardID: String; var title: String; var isCompleted: Bool; var sortOrder: Int }

struct KanbanCard: Identifiable, Equatable {
    let id: String
    let projectID: String
    var title: String
    var description: String
    var status: KanbanStatus
    var priority: KanbanPriority
    var dueDate: Date?
    var sortOrder: Int
    var isArchived: Bool
    var labels: [KanbanCardLabel]
    var checklist: [KanbanChecklistItem]
    var createdAt: Date
    var updatedAt: Date
}

struct KanbanColumn: Identifiable, Equatable {
    let status: KanbanStatus
    let cards: [KanbanCard]
    var id: KanbanStatus { status }
}
```

```swift
import Foundation

enum KanbanValidationError: Error, Equatable {
    case empty(String)
    case tooLong(String, maximum: Int)
    case invalidColor
    case tooManyLabels
    case tooManyChecklistItems
}

enum KanbanValidation {
    static let projectNameLimit = 100
    static let projectGoalLimit = 500
    static let cardTitleLimit = 200
    static let cardDescriptionLimit = 10_000
    static let labelNameLimit = 40
    static let labelCountLimit = 10
    static let checklistTitleLimit = 200
    static let checklistCountLimit = 50

    static func projectName(_ value: String) throws -> String { try required(value, field: "Project name", maximum: projectNameLimit) }
    static func projectGoal(_ value: String) throws -> String { try required(value, field: "Project goal", maximum: projectGoalLimit) }
    static func cardTitle(_ value: String) throws -> String { try required(value, field: "Card title", maximum: cardTitleLimit) }
    static func cardDescription(_ value: String) throws -> String { try bounded(value, field: "Card description", maximum: cardDescriptionLimit) }
    static func labelName(_ value: String) throws -> String { try required(value, field: "Label", maximum: labelNameLimit) }
    static func checklistTitle(_ value: String) throws -> String { try required(value, field: "Checklist item", maximum: checklistTitleLimit) }

    static func color(_ value: String) throws -> String {
        guard value.range(of: "^#[0-9A-Fa-f]{6}$", options: .regularExpression) != nil else { throw KanbanValidationError.invalidColor }
        return value.uppercased()
    }

    private static func required(_ value: String, field: String, maximum: Int) throws -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw KanbanValidationError.empty(field) }
        guard trimmed.count <= maximum else { throw KanbanValidationError.tooLong(field, maximum: maximum) }
        return trimmed
    }

    private static func bounded(_ value: String, field: String, maximum: Int) throws -> String {
        guard value.count <= maximum else { throw KanbanValidationError.tooLong(field, maximum: maximum) }
        return value
    }
}
```

- [ ] **Step 5: Implement pure ordering**

```swift
enum KanbanOrdering {
    struct Result: Equatable { let source: [String]; let destination: [String] }

    static func move(cardID: String, from source: [String], to destination: [String], destinationIndex: Int) -> Result {
        var newSource = source.filter { $0 != cardID }
        var newDestination = source == destination ? newSource : destination.filter { $0 != cardID }
        let index = min(max(0, destinationIndex), newDestination.count)
        newDestination.insert(cardID, at: index)
        if source == destination { newSource = newDestination }
        return Result(source: newSource, destination: newDestination)
    }
}
```

- [ ] **Step 6: Run focused tests and commit**

Run the Task 1 command again. Expected: PASS.

```bash
git add macos/TodoFocusMac/Sources/Core/Kanban macos/TodoFocusMac/Tests/CoreTests/KanbanModelTests.swift macos/TodoFocusMac/Tests/CoreTests/KanbanOrderingTests.swift macos/TodoFocusMac/TodoFocusMac.xcodeproj
git commit -m "feat(kanban): add project card domain rules"
```

---

### Task 2: GRDB Migration, Records, and Safe Mapping

**Files:**
- Modify: `macos/TodoFocusMac/Sources/Data/Database/Migrations.swift`
- Modify: `macos/TodoFocusMac/Sources/Data/Database/DatabaseManager.swift`
- Create: `macos/TodoFocusMac/Sources/Data/DTO/KanbanProjectRecord.swift`
- Create: `macos/TodoFocusMac/Sources/Data/DTO/KanbanCardRecord.swift`
- Create: `macos/TodoFocusMac/Sources/Data/DTO/KanbanCardLabelRecord.swift`
- Create: `macos/TodoFocusMac/Sources/Data/DTO/KanbanChecklistItemRecord.swift`
- Create: `macos/TodoFocusMac/Sources/Data/DTO/KanbanRecordMappings.swift`
- Test: `macos/TodoFocusMac/Tests/DataTests/KanbanMigrationTests.swift`

**Interfaces:**
- Consumes: Task 1 domain enums/models and `DatabaseManager`.
- Produces: four GRDB records and `KanbanCardRecord.card(labels:checklist:) -> (card: KanbanCard, usedFallback: Bool)`.

- [ ] **Step 1: Write failing migration tests**

```swift
import XCTest
import GRDB
@testable import TodoFocusMac

final class KanbanMigrationTests: XCTestCase {
    func testMigrationCreatesKanbanSchemaAndIndexes() throws {
        let manager = try DatabaseManager(databasePath: ":memory:")
        try manager.dbQueue.read { db in
            for table in ["kanban_project", "kanban_card", "kanban_card_label", "kanban_checklist_item"] {
                XCTAssertTrue(try db.tableExists(table))
            }
            let cardColumns = Set(try db.columns(in: "kanban_card").map(\.name))
            XCTAssertTrue(["projectId", "status", "priority", "sortOrder", "isArchived"].allSatisfy(cardColumns.contains))
            XCTAssertNotNil(try db.indexes(on: "kanban_card").first { $0.name == "idx_kanban_card_board_order" })
        }
    }

    func testDeletingProjectCascadesCardsAndChildren() throws {
        let manager = try DatabaseManager(databasePath: ":memory:")
        try manager.dbQueue.write { db in
            try db.execute(sql: "INSERT INTO kanban_project (id,name,color,goal,createdAt,updatedAt) VALUES ('p','P','#C46849','Goal',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)")
            try db.execute(sql: "INSERT INTO kanban_card (id,projectId,title,description,status,priority,sortOrder,isArchived,createdAt,updatedAt) VALUES ('c','p','C','','backlog','medium',0,0,CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)")
            try db.execute(sql: "INSERT INTO kanban_card_label (id,cardId,name,sortOrder) VALUES ('l','c','UI',0)")
            try db.execute(sql: "DELETE FROM kanban_project WHERE id = 'p'")
            XCTAssertEqual(try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM kanban_card"), 0)
            XCTAssertEqual(try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM kanban_card_label"), 0)
        }
    }
}
```

- [ ] **Step 2: Run the migration test and verify failure**

Run:

```bash
cd macos/TodoFocusMac
xcodegen generate
xcodebuild test -project TodoFocusMac.xcodeproj -scheme TodoFocusMac -destination 'platform=macOS' -only-testing:DataTests/KanbanMigrationTests
```

Expected: FAIL because `kanban_project` does not exist.

- [ ] **Step 3: Add migration `v5_kanban_project_boards`**

Add one migration after `v4_archive_todos`:

```swift
migrator.registerMigration("v5_kanban_project_boards") { db in
    try db.create(table: "kanban_project") { t in
        t.column("id", .text).primaryKey()
        t.column("name", .text).notNull()
        t.column("color", .text).notNull()
        t.column("goal", .text).notNull()
        t.column("createdAt", .datetime).notNull()
        t.column("updatedAt", .datetime).notNull()
    }
    try db.create(table: "kanban_card") { t in
        t.column("id", .text).primaryKey()
        t.column("projectId", .text).notNull().references("kanban_project", onDelete: .cascade)
        t.column("title", .text).notNull()
        t.column("description", .text).notNull().defaults(to: "")
        t.column("status", .text).notNull().defaults(to: KanbanStatus.backlog.rawValue)
        t.column("priority", .text).notNull().defaults(to: KanbanPriority.medium.rawValue)
        t.column("dueDate", .datetime)
        t.column("sortOrder", .integer).notNull().defaults(to: 0)
        t.column("isArchived", .boolean).notNull().defaults(to: false)
        t.column("createdAt", .datetime).notNull()
        t.column("updatedAt", .datetime).notNull()
    }
    try db.create(table: "kanban_card_label") { t in
        t.column("id", .text).primaryKey()
        t.column("cardId", .text).notNull().references("kanban_card", onDelete: .cascade)
        t.column("name", .text).notNull()
        t.column("sortOrder", .integer).notNull().defaults(to: 0)
    }
    try db.create(table: "kanban_checklist_item") { t in
        t.column("id", .text).primaryKey()
        t.column("cardId", .text).notNull().references("kanban_card", onDelete: .cascade)
        t.column("title", .text).notNull()
        t.column("isCompleted", .boolean).notNull().defaults(to: false)
        t.column("sortOrder", .integer).notNull().defaults(to: 0)
    }
    try db.create(index: "idx_kanban_project_name", on: "kanban_project", columns: ["name"])
    try db.create(index: "idx_kanban_card_board_order", on: "kanban_card", columns: ["projectId", "isArchived", "status", "sortOrder"])
    try db.create(index: "idx_kanban_label_order", on: "kanban_card_label", columns: ["cardId", "sortOrder"])
    try db.create(index: "idx_kanban_checklist_order", on: "kanban_checklist_item", columns: ["cardId", "sortOrder"])
}
```

Update `clearAllTables()` to delete child tables first:

```swift
try db.execute(sql: "DELETE FROM kanban_checklist_item")
try db.execute(sql: "DELETE FROM kanban_card_label")
try db.execute(sql: "DELETE FROM kanban_card")
try db.execute(sql: "DELETE FROM kanban_project")
```

- [ ] **Step 4: Add records and safe domain mapping**

Each record conforms to `Codable, FetchableRecord, PersistableRecord, Equatable` and declares its exact table name. Use persisted status/priority fallbacks in the card mapping:

```swift
extension KanbanCardRecord {
    func card(labels: [KanbanCardLabelRecord], checklist: [KanbanChecklistItemRecord]) -> (card: KanbanCard, usedFallback: Bool) {
        let decodedStatus = KanbanStatus.persisted(status)
        let decodedPriority = KanbanPriority.persisted(priority)
        return (
            KanbanCard(
                id: id, projectID: projectId, title: title, description: description,
                status: decodedStatus.value, priority: decodedPriority.value,
                dueDate: dueDate, sortOrder: sortOrder, isArchived: isArchived,
                labels: labels.map(\.label), checklist: checklist.map(\.item),
                createdAt: createdAt, updatedAt: updatedAt
            ),
            decodedStatus.usedFallback || decodedPriority.usedFallback
        )
    }
}
```

- [ ] **Step 5: Run focused tests and commit**

Expected: `KanbanMigrationTests` PASS.

```bash
git add macos/TodoFocusMac/Sources/Data/Database macos/TodoFocusMac/Sources/Data/DTO/Kanban* macos/TodoFocusMac/Tests/DataTests/KanbanMigrationTests.swift macos/TodoFocusMac/TodoFocusMac.xcodeproj
git commit -m "feat(kanban): add project board database schema"
```

---

### Task 3: Project Repository CRUD

**Files:**
- Create: `macos/TodoFocusMac/Sources/Data/Repositories/KanbanRepository.swift`
- Create: `macos/TodoFocusMac/Sources/Data/Repositories/KanbanProjectRepository.swift`
- Test: `macos/TodoFocusMac/Tests/DataTests/KanbanRepositoryTests.swift`

**Interfaces:**
- Consumes: Task 1 validation and Task 2 records.
- Produces: `KanbanRepositoryProtocol`, `KanbanRepository`, `CreateKanbanProjectInput`, `UpdateKanbanProjectInput`, and project CRUD methods.

- [ ] **Step 1: Write failing project CRUD tests**

```swift
func testProjectCRUDSortsAlphabeticallyAndValidates() throws {
    let repo = try makeKanbanRepository()
    let zeta = try repo.createProject(.init(name: "Zeta", color: "#C46849", goal: "Ship Zeta"), now: fixedNow)
    let alpha = try repo.createProject(.init(name: " Alpha ", color: "#336699", goal: " Build Alpha "), now: fixedNow)
    XCTAssertEqual(try repo.fetchProjects().map(\.id), [alpha.id, zeta.id])
    XCTAssertEqual(alpha.name, "Alpha")
    XCTAssertEqual(alpha.goal, "Build Alpha")

    try repo.updateProject(id: alpha.id, input: .init(name: "Beta", color: "#ABCDEF", goal: "Beta goal"), now: fixedNow)
    XCTAssertEqual(try repo.fetchProject(id: alpha.id)?.name, "Beta")
    try repo.deleteProject(id: zeta.id)
    XCTAssertNil(try repo.fetchProject(id: zeta.id))
}

func testProjectRejectsBlankGoalAndInvalidColor() throws {
    let repo = try makeKanbanRepository()
    XCTAssertThrowsError(try repo.createProject(.init(name: "P", color: "orange", goal: "Goal")))
    XCTAssertThrowsError(try repo.createProject(.init(name: "P", color: "#C46849", goal: "  ")))
}
```

Use this helper at the top of the test file:

```swift
private let fixedNow = Date(timeIntervalSince1970: 1_700_000_000)
private func makeKanbanRepository() throws -> KanbanRepository {
    let manager = try DatabaseManager(databasePath: ":memory:")
    return KanbanRepository(dbQueue: manager.dbQueue)
}
```

- [ ] **Step 2: Run and verify failure**

Run `xcodebuild test ... -only-testing:DataTests/KanbanRepositoryTests`. Expected: FAIL because `KanbanRepository` is undefined.

- [ ] **Step 3: Define repository contract and project inputs**

```swift
struct CreateKanbanProjectInput { let name: String; let color: String; let goal: String }
struct UpdateKanbanProjectInput { let name: String; let color: String; let goal: String }

enum KanbanRepositoryError: Error, Equatable {
    case notFound
    case invalidProject
    case invalidCard
    case labelLimit
    case checklistLimit
    case invalidMove
}

protocol KanbanRepositoryProtocol {
    func fetchProjects() throws -> [KanbanProject]
    func fetchProject(id: String) throws -> KanbanProject?
    func createProject(_ input: CreateKanbanProjectInput, now: Date) throws -> KanbanProject
    func updateProject(id: String, input: UpdateKanbanProjectInput, now: Date) throws
    func deleteProject(id: String) throws
    // Add card and child signatures in Task 4 without renaming these methods.
}

struct KanbanRepository: KanbanRepositoryProtocol {
    let dbQueue: DatabaseQueue
    init(dbQueue: DatabaseQueue) { self.dbQueue = dbQueue }
}
```

- [ ] **Step 4: Implement project CRUD with validation**

Use `KanbanValidation.projectName`, `.projectGoal`, and `.color`; fetch with case-insensitive name ordering:

```swift
func fetchProjects() throws -> [KanbanProject] {
    try dbQueue.read { db in
        try KanbanProjectRecord.fetchAll(
            db,
            sql: "SELECT * FROM kanban_project ORDER BY name COLLATE NOCASE ASC"
        ).map(\.project)
    }
}
```

Create IDs with `UUID().uuidString`, update `updatedAt`, and throw `.notFound` when update/delete affects no row.

- [ ] **Step 5: Run focused tests and commit**

```bash
git add macos/TodoFocusMac/Sources/Data/Repositories/Kanban* macos/TodoFocusMac/Tests/DataTests/KanbanRepositoryTests.swift macos/TodoFocusMac/TodoFocusMac.xcodeproj
git commit -m "feat(kanban): add project persistence"
```

---

### Task 4: Card, Label, Checklist, Archive, and Move Persistence

**Files:**
- Modify: `macos/TodoFocusMac/Sources/Data/Repositories/KanbanRepository.swift`
- Create: `macos/TodoFocusMac/Sources/Data/Repositories/KanbanCardRepository.swift`
- Create: `macos/TodoFocusMac/Sources/Data/Repositories/KanbanCardChildrenRepository.swift`
- Modify: `macos/TodoFocusMac/Tests/DataTests/KanbanRepositoryTests.swift`

**Interfaces:**
- Consumes: Task 3 repository and project CRUD.
- Produces: complete card/child repository API used by `KanbanStore`.

- [ ] **Step 1: Add failing card lifecycle and ordering tests**

```swift
func testCreateMoveArchiveRestoreAndDeleteCard() throws {
    let repo = try makeKanbanRepository()
    let project = try repo.createProject(.init(name: "App", color: "#C46849", goal: "Ship"), now: fixedNow)
    let a = try repo.createCard(.init(projectID: project.id, title: "A", status: .backlog), now: fixedNow)
    let b = try repo.createCard(.init(projectID: project.id, title: "B", status: .backlog), now: fixedNow)

    try repo.moveCard(id: b.id, to: .ready, destinationIndex: 0, now: fixedNow)
    XCTAssertEqual(try repo.fetchCards(projectID: project.id, includeArchived: false).first { $0.id == b.id }?.status, .ready)
    XCTAssertEqual(try repo.fetchCards(projectID: project.id, includeArchived: false).filter { $0.status == .backlog }.map(\.sortOrder), [0])

    try repo.archiveCard(id: b.id, now: fixedNow)
    XCTAssertFalse(try repo.fetchCards(projectID: project.id, includeArchived: false).contains { $0.id == b.id })
    try repo.restoreCard(id: b.id, now: fixedNow)
    XCTAssertEqual(try repo.fetchCards(projectID: project.id, includeArchived: false).first { $0.id == b.id }?.status, .ready)
    try repo.deleteCard(id: a.id)
    XCTAssertNil(try repo.fetchCard(id: a.id))
}

func testLabelsAndChecklistEnforceLimitsAndOrder() throws {
    let (repo, card) = try makeProjectAndCard()
    let label = try repo.addLabel(cardID: card.id, name: " UI ")
    XCTAssertEqual(label.name, "UI")
    let item = try repo.addChecklistItem(cardID: card.id, title: " Test it ")
    try repo.setChecklistItemCompleted(id: item.id, isCompleted: true)
    XCTAssertTrue(try XCTUnwrap(repo.fetchCard(id: card.id)).checklist.first?.isCompleted == true)
}
```

- [ ] **Step 2: Run and verify failure**

Expected: FAIL because card methods and inputs do not exist.

- [ ] **Step 3: Extend the repository protocol with exact signatures**

```swift
struct CreateKanbanCardInput { let projectID: String; let title: String; let status: KanbanStatus }
struct UpdateKanbanCardInput {
    var title: String?
    var description: String?
    var priority: KanbanPriority?
    var dueDate: Date??
}

struct KanbanCardFetchResult {
    let cards: [KanbanCard]
    let dataRepairRequired: Bool
}

func fetchCards(projectID: String, includeArchived: Bool) throws -> KanbanCardFetchResult
func fetchCard(id: String) throws -> (card: KanbanCard, dataRepairRequired: Bool)?
func createCard(_ input: CreateKanbanCardInput, now: Date) throws -> KanbanCard
func updateCard(id: String, input: UpdateKanbanCardInput, now: Date) throws
func moveCard(id: String, to status: KanbanStatus, destinationIndex: Int, now: Date) throws
func archiveCard(id: String, now: Date) throws
func restoreCard(id: String, now: Date) throws
func deleteCard(id: String) throws
func addLabel(cardID: String, name: String) throws -> KanbanCardLabel
func updateLabel(id: String, name: String) throws
func deleteLabel(id: String) throws
func addChecklistItem(cardID: String, title: String) throws -> KanbanChecklistItem
func updateChecklistItem(id: String, title: String) throws
func setChecklistItemCompleted(id: String, isCompleted: Bool) throws
func moveChecklistItem(id: String, destinationIndex: Int) throws
func deleteChecklistItem(id: String) throws
```

Give `now` default values of `Date()` only on the concrete implementation, not the protocol.

- [ ] **Step 4: Implement aggregate fetches and validated mutations**

Fetch card rows in `(status, sortOrder)` order, fetch all children for those IDs, group by `cardId`, and call Task 2 mapping. Return the `KanbanCardFetchResult` defined in Step 3, setting `dataRepairRequired = true` when any mapping used fallback. Apply the same signatures consistently in the concrete repository and tests.

- [ ] **Step 5: Implement transactional moves and dense renumbering**

Inside one `dbQueue.write` transaction:

1. Fetch the moving card or throw `.notFound`.
2. Fetch source and destination IDs ordered by `sortOrder`.
3. Call `KanbanOrdering.move`.
4. Update the card status.
5. Write `sortOrder = offset` for every ID in both results.
6. Update `updatedAt` on the moved card.

Use the same dense-renumber helper after archive, restore, and delete. Restore into the bottom of the retained status column.

- [ ] **Step 6: Implement label and checklist limits**

Count existing children inside the same write transaction before insertion. Throw `.labelLimit` at 10 and `.checklistLimit` at 50. Validate names/titles with Task 1 constants. Reorder checklist items with dense zero-based values.

- [ ] **Step 7: Run repository and migration tests and commit**

```bash
xcodebuild test -project TodoFocusMac.xcodeproj -scheme TodoFocusMac -destination 'platform=macOS' \
  -only-testing:DataTests/KanbanMigrationTests \
  -only-testing:DataTests/KanbanRepositoryTests

git add macos/TodoFocusMac/Sources/Data/Repositories/Kanban* macos/TodoFocusMac/Tests/DataTests/KanbanRepositoryTests.swift
git commit -m "feat(kanban): persist cards and workflow ordering"
```

---

### Task 5: Observable Kanban Store and Confirmed-State Mutations

**Files:**
- Create: `macos/TodoFocusMac/Sources/App/KanbanStore.swift`
- Test: `macos/TodoFocusMac/Tests/CoreTests/KanbanStoreTests.swift`

**Interfaces:**
- Consumes: complete `KanbanRepositoryProtocol` from Tasks 3–4.
- Produces: `KanbanStore` API used by every Kanban view.

- [ ] **Step 1: Write a protocol-backed fake and failing store tests**

```swift
@MainActor
final class KanbanStoreTests: XCTestCase {
    func testLoadSortsProjectsAndSelectsFirst() throws {
        let fake = FakeKanbanRepository(projects: [project("Zeta"), project("Alpha")])
        let store = KanbanStore(repository: fake, now: { Date(timeIntervalSince1970: 1) })
        try store.load()
        XCTAssertEqual(store.projects.map(\.name), ["Alpha", "Zeta"])
        XCTAssertEqual(store.selectedProject?.name, "Alpha")
    }

    func testFailedMoveKeepsLastConfirmedCardsAndShowsError() throws {
        let fake = FakeKanbanRepository(projects: [project("App")], cards: [card("A", status: .backlog)])
        let store = KanbanStore(repository: fake)
        try store.load()
        fake.moveError = KanbanRepositoryError.invalidMove
        store.moveCard(id: "A", to: .ready, destinationIndex: 0)
        XCTAssertEqual(store.cards.first?.status, .backlog)
        XCTAssertNotNil(store.errorMessage)
    }

    func testDeletingSelectedProjectSelectsAlphabeticalFirstRemainingProject() throws {
        let fake = FakeKanbanRepository(projects: [project("Beta"), project("Alpha")])
        let store = KanbanStore(repository: fake)
        try store.load()
        store.selectProject(id: fake.projects.first { $0.name == "Beta" }!.id)
        store.deleteSelectedProject()
        XCTAssertEqual(store.selectedProject?.name, "Alpha")
    }
}
```

The fake implements every protocol method with in-memory arrays and injectable errors; do not weaken the production protocol for tests.

- [ ] **Step 2: Run and verify failure**

Expected: FAIL because `KanbanStore` does not exist.

- [ ] **Step 3: Implement store state and loading**

```swift
@Observable
@MainActor
final class KanbanStore {
    private let repository: KanbanRepositoryProtocol
    private let now: () -> Date
    @ObservationIgnored private var descriptionTask: Task<Void, Never>?
    @ObservationIgnored private var goalTask: Task<Void, Never>?

    var projects: [KanbanProject] = []
    var cards: [KanbanCard] = []
    var selectedProjectID: String?
    var selectedCardID: String?
    var errorMessage: String?
    var showsDataRepairWarning = false
    var canRetryLastLoad = false

    var selectedProject: KanbanProject? { projects.first { $0.id == selectedProjectID } }
    var selectedCard: KanbanCard? { cards.first { $0.id == selectedCardID } }
    var columns: [KanbanColumn] {
        KanbanStatus.allCases.map { status in
            KanbanColumn(status: status, cards: cards.filter { $0.status == status && !$0.isArchived }.sorted { $0.sortOrder < $1.sortOrder })
        }
    }
}
```

`load()` fetches alphabetized projects, preserves a valid selection, otherwise selects the first project, then reloads that board. It throws so unit tests and startup code can assert failures. `loadForDisplay()` catches load errors, sets `errorMessage`, and enables `canRetryLastLoad`; `retryLastLoad()` calls it again. `selectProject(id:)` clears card selection and reloads cards.

- [ ] **Step 4: Implement mutation orchestration**

Expose these exact view-facing methods:

```swift
func createProject(name: String, color: String, goal: String)
func updateSelectedProject(name: String, color: String, goal: String)
func updateSelectedProjectGoalDebounced(_ goal: String)
func deleteSelectedProject()
func createCard(title: String, in status: KanbanStatus)
func updateSelectedCardTitle(_ title: String)
func updateSelectedCardDescriptionDebounced(_ description: String)
func setSelectedCardPriority(_ priority: KanbanPriority)
func setSelectedCardDueDate(_ dueDate: Date?)
func moveCard(id: String, to status: KanbanStatus, destinationIndex: Int)
func archiveSelectedCard()
func restoreCard(id: String)
func deleteSelectedCard()
func addLabel(_ name: String)
func updateLabel(id: String, name: String)
func deleteLabel(id: String)
func addChecklistItem(_ title: String)
func updateChecklistItem(id: String, title: String)
func toggleChecklistItem(id: String, isCompleted: Bool)
func moveChecklistItem(id: String, destinationIndex: Int)
func deleteChecklistItem(id: String)
func clearError()
```

Each method calls the repository, reloads confirmed state on success, and leaves current arrays unchanged on failure. `updateSelectedCardDescriptionDebounced` and `updateSelectedProjectGoalDebounced` use cancellable 300 ms `Task.sleep(for: .milliseconds(300))` jobs; cancellation is not shown as an error. Add `loadForDisplay()` and `retryLastLoad()` as specified above.

- [ ] **Step 5: Run focused tests and commit**

```bash
xcodebuild test -project TodoFocusMac.xcodeproj -scheme TodoFocusMac -destination 'platform=macOS' -only-testing:CoreTests/KanbanStoreTests
git add macos/TodoFocusMac/Sources/App/KanbanStore.swift macos/TodoFocusMac/Tests/CoreTests/KanbanStoreTests.swift macos/TodoFocusMac/TodoFocusMac.xcodeproj
git commit -m "feat(kanban): add project board state store"
```

---

### Task 6: App Construction, Sidebar Navigation, and Root Routing

**Files:**
- Modify: `macos/TodoFocusMac/Sources/App/SelectionState.swift`
- Modify: `macos/TodoFocusMac/Sources/App/AppModel.swift`
- Modify: `macos/TodoFocusMac/Sources/TodoFocusMacApp.swift`
- Modify: `macos/TodoFocusMac/Sources/RootView.swift`
- Modify: `macos/TodoFocusMac/Sources/Features/Sidebar/SidebarView.swift`
- Modify: `macos/TodoFocusMac/Tests/CoreTests/AppSelectionStateTests.swift`
- Modify: `macos/TodoFocusMac/Tests/CoreTests/AppModelTests.swift`

**Interfaces:**
- Consumes: `KanbanStore` from Task 5.
- Produces: `.kanban` navigation and store injection into the future feature shell.

- [ ] **Step 1: Add failing navigation tests**

```swift
func testKanbanHasStableActiveViewIDAndClearsTodoSelection() {
    let model = AppModel()
    model.selectedTodoID = "todo"
    model.selectSidebar(.kanban)
    XCTAssertEqual(model.activeViewID, "kanban")
    XCTAssertNil(model.selectedTodoID)
    XCTAssertEqual(model.selection, .kanban)
}
```

- [ ] **Step 2: Run and verify failure**

Expected: compile failure because `.kanban` is missing.

- [ ] **Step 3: Add the selection and sidebar route**

Add `case kanban` to `SidebarSelection`. Return `.all` from `smartList` because task querying is bypassed for Kanban. Add `case .kanban: return "kanban"` to `AppModel.activeViewID`. Add this row after Daily Review:

```swift
smartRow("Kanban", systemImage: "rectangle.3.group", selection: .kanban)
```

- [ ] **Step 4: Construct and inject the store**

In `TodoFocusMacApp`, add:

```swift
@State private var kanbanStore: KanbanStore?
```

Create `KanbanRepository(dbQueue: manager.dbQueue)` and initialize `KanbanStore`. Pass the unwrapped store to `RootView`. Change the root initializer to accept:

```swift
@Bindable var kanbanStore: KanbanStore
```

Temporarily render a stable placeholder for `.kanban` until Task 7:

```swift
if appModel.selection == .kanban {
    Text("Kanban").frame(maxWidth: .infinity, maxHeight: .infinity)
} else if appModel.selection == .dailyReview {
    DailyReviewView(appModel: appModel, store: store)
} else {
    TaskListView(appModel: appModel, store: store)
}
```

- [ ] **Step 5: Run navigation tests and commit**

```bash
git add macos/TodoFocusMac/Sources/App/SelectionState.swift macos/TodoFocusMac/Sources/App/AppModel.swift macos/TodoFocusMac/Sources/TodoFocusMacApp.swift macos/TodoFocusMac/Sources/RootView.swift macos/TodoFocusMac/Sources/Features/Sidebar/SidebarView.swift macos/TodoFocusMac/Tests/CoreTests/AppSelectionStateTests.swift macos/TodoFocusMac/Tests/CoreTests/AppModelTests.swift
git commit -m "feat(kanban): add project board navigation"
```

---

### Task 7: Kanban Feature Shell and Project Management

**Files:**
- Create: `macos/TodoFocusMac/Sources/Features/Kanban/KanbanView.swift`
- Create: `macos/TodoFocusMac/Tests/CoreTests/KanbanViewBehaviorTests.swift`
- Modify: `macos/TodoFocusMac/Sources/RootView.swift`

**Interfaces:**
- Consumes: `KanbanStore` project methods and the theme-token environment.
- Produces: project switcher, create/edit/delete flows, error banner, empty state, archive-sheet trigger, and board-content slot.

- [ ] **Step 1: Add failing behavior-contract tests**

Define static UI contract values on `KanbanView` so behavior is testable without brittle view-tree inspection:

```swift
func testKanbanViewUsesFixedProjectAndBoardCopy() {
    XCTAssertEqual(KanbanView.title, "Kanban")
    XCTAssertEqual(KanbanView.emptyProjectTitle, "Create your first project")
    XCTAssertEqual(KanbanView.deleteProjectConfirmation, "Delete this project and all of its cards?")
}
```

- [ ] **Step 2: Run and verify failure**

Expected: FAIL because `KanbanView` does not exist.

- [ ] **Step 3: Build the shell**

```swift
struct KanbanView: View {
    static let title = "Kanban"
    static let emptyProjectTitle = "Create your first project"
    static let deleteProjectConfirmation = "Delete this project and all of its cards?"

    @Bindable var store: KanbanStore
    @Environment(\.themeTokens) private var tokens
    @State private var projectForm: ProjectFormMode?
    @State private var showsDeleteProjectConfirmation = false
    @State private var showsArchive = false

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.lg) {
            header
            if let error = store.errorMessage { errorBanner(error) }
            if store.projects.isEmpty { emptyState } else { KanbanBoardView(store: store) }
        }
        .padding(SpacingTokens.xl)
        .task { store.loadForDisplay() }
    }
}
```

The header contains a `Picker` bound to `selectedProjectID`, project color/goal, New Project, Edit Project, Archived Cards, and Delete Project controls. The create sheet collects name, the ten-color palette used by lists, and goal. The edit sheet changes name and color with explicit Save; the header's multiline goal editor calls `updateSelectedProjectGoalDebounced` so goal edits follow the specified 300 ms persistence rule. Disable Save until locally valid. Confirm project deletion using the exact static copy.

- [ ] **Step 4: Replace the RootView placeholder**

```swift
KanbanView(store: kanbanStore)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
```

Do not show `TaskDetailView` while `.kanban` is selected; Task 9 adds the Kanban panel.

- [ ] **Step 5: Run focused tests and commit**

```bash
xcodebuild test -project TodoFocusMac.xcodeproj -scheme TodoFocusMac -destination 'platform=macOS' -only-testing:CoreTests/KanbanViewBehaviorTests
git add macos/TodoFocusMac/Sources/Features/Kanban/KanbanView.swift macos/TodoFocusMac/Sources/RootView.swift macos/TodoFocusMac/Tests/CoreTests/KanbanViewBehaviorTests.swift macos/TodoFocusMac/TodoFocusMac.xcodeproj
git commit -m "feat(kanban): add project management shell"
```

---

### Task 8: Five-Column Board, Card Summaries, and Drag Ordering

**Files:**
- Create: `macos/TodoFocusMac/Sources/Features/Kanban/KanbanBoardView.swift`
- Create: `macos/TodoFocusMac/Sources/Features/Kanban/KanbanColumnView.swift`
- Create: `macos/TodoFocusMac/Sources/Features/Kanban/KanbanCardView.swift`
- Create: `macos/TodoFocusMac/Sources/Features/Kanban/KanbanCardDragPayload.swift`
- Modify: `macos/TodoFocusMac/Tests/CoreTests/KanbanViewBehaviorTests.swift`

**Interfaces:**
- Consumes: `KanbanStore.columns`, `createCard`, `moveCard`, and `selectedCardID`.
- Produces: complete active-board interaction; card selection feeds Task 9.

- [ ] **Step 1: Add failing board-projection tests**

```swift
func testStoreAlwaysProjectsFiveColumnsInWorkflowOrder() throws {
    let store = try loadedStore(cards: [card("A", status: .blocked), card("B", status: .backlog)])
    XCTAssertEqual(store.columns.map(\.status), [.backlog, .ready, .inProgress, .blocked, .done])
    XCTAssertEqual(store.columns.first { $0.status == .blocked }?.cards.map(\.id), ["A"])
}

func testChecklistProgressSummary() {
    let card = cardWithChecklist(completed: 2, total: 3)
    XCTAssertEqual(KanbanCardView.checklistProgress(card), "2/3")
}
```

- [ ] **Step 2: Run and verify failure**

Expected: checklist summary test fails because the view does not exist.

- [ ] **Step 3: Add the transferable payload**

```swift
import CoreTransferable

struct KanbanCardDragPayload: Codable, Transferable {
    let cardID: String
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .data)
    }
}
```

- [ ] **Step 4: Build the board and columns**

`KanbanBoardView` renders `store.columns` in a horizontal `ScrollView` and `HStack(alignment: .top)`. Each `KanbanColumnView` has a 300-point width, title, count, Add Card composer, cards, and bottom drop target. Use:

```swift
.dropDestination(for: KanbanCardDragPayload.self) { payloads, _ in
    guard let payload = payloads.first else { return false }
    store.moveCard(id: payload.cardID, to: column.status, destinationIndex: column.cards.count)
    return true
} isTargeted: { isTargeted = $0 }
```

Use a terracotta stroke/fill while targeted. Keep empty-column Add Card affordance visible.

- [ ] **Step 5: Build card summaries and insertion drop targets**

Cards display title, priority chip, due date, labels, and checklist progress. Add:

```swift
static func checklistProgress(_ card: KanbanCard) -> String? {
    guard !card.checklist.isEmpty else { return nil }
    return "\(card.checklist.filter(\.isCompleted).count)/\(card.checklist.count)"
}
```

Make each card draggable. Its drop destination inserts before its own index:

```swift
store.moveCard(id: payload.cardID, to: card.status, destinationIndex: card.sortOrder)
```

Clicking sets `store.selectedCardID = card.id`. Add accessibility labels containing title, status, priority, due date when present, and checklist progress when present.

- [ ] **Step 6: Run focused tests and commit**

```bash
git add macos/TodoFocusMac/Sources/Features/Kanban macos/TodoFocusMac/Tests/CoreTests/KanbanViewBehaviorTests.swift macos/TodoFocusMac/TodoFocusMac.xcodeproj
git commit -m "feat(kanban): add draggable workflow board"
```

---

### Task 9: Card Detail Panel, Debounced Editing, Labels, and Checklist

**Files:**
- Create: `macos/TodoFocusMac/Sources/Features/Kanban/KanbanCardDetailView.swift`
- Modify: `macos/TodoFocusMac/Sources/RootView.swift`
- Modify: `macos/TodoFocusMac/Tests/CoreTests/KanbanStoreTests.swift`
- Modify: `macos/TodoFocusMac/Tests/CoreTests/KanbanViewBehaviorTests.swift`

**Interfaces:**
- Consumes: Task 5 selected-card mutation API and existing `WindowPersistence` sizing.
- Produces: full edit surface and non-drag status alternative.

- [ ] **Step 1: Add failing selection and non-drag transition tests**

```swift
func testDeletingSelectedCardClearsSelection() throws {
    let store = try loadedStore(cards: [card("A", status: .backlog)])
    store.selectedCardID = "A"
    store.deleteSelectedCard()
    XCTAssertNil(store.selectedCardID)
}

func testEveryStatusIsAvailableWithoutDragging() {
    XCTAssertEqual(KanbanCardDetailView.availableStatuses, KanbanStatus.allCases)
}
```

- [ ] **Step 2: Run and verify failure**

Expected: detail-view status test fails.

- [ ] **Step 3: Implement the detail view**

```swift
struct KanbanCardDetailView: View {
    static let availableStatuses = KanbanStatus.allCases
    @Bindable var store: KanbanStore
    let card: KanbanCard
    let onClose: () -> Void
    @Environment(\.themeTokens) private var tokens
}
```

Use local draft state synchronized when `card.id` changes. Provide:

- title field; save on submit/focus loss
- description editor; call 300 ms debounced store method
- status picker using `moveCard(id:to:destinationIndex:)` with destination index equal to target column count
- priority picker
- optional due-date toggle and date picker
- label list with add/edit/delete and remaining-count feedback
- checklist with add/edit/toggle/reorder/delete and progress
- Archive and Delete actions with confirmation

Apply field limits in text controls and surface repository validation errors through the shared banner.

- [ ] **Step 4: Route the correct detail panel from RootView**

Keep the existing divider and persisted width. When `.kanban` and `kanbanStore.selectedCard != nil`, render `KanbanCardDetailView`; otherwise retain existing `TaskDetailView` behavior. Do not let both panels render simultaneously.

```swift
if appModel.selection == .kanban, let card = kanbanStore.selectedCard {
    KanbanCardDetailView(store: kanbanStore, card: card) { kanbanStore.selectedCardID = nil }
        .frame(width: detailPanelLiveWidth)
} else if let todo = store.selectedTodo {
    TaskDetailView(store: store, launchpadService: launchpadService, todo: todo, onClose: store.clearSelection)
        .frame(width: detailPanelLiveWidth)
}
```

Extract the shared divider into a private `detailDivider(_:)` helper only if needed to avoid duplication; do not refactor unrelated RootView behavior.

- [ ] **Step 5: Run focused tests and commit**

```bash
xcodebuild test -project TodoFocusMac.xcodeproj -scheme TodoFocusMac -destination 'platform=macOS' \
  -only-testing:CoreTests/KanbanStoreTests \
  -only-testing:CoreTests/KanbanViewBehaviorTests

git add macos/TodoFocusMac/Sources/Features/Kanban/KanbanCardDetailView.swift macos/TodoFocusMac/Sources/RootView.swift macos/TodoFocusMac/Tests/CoreTests/KanbanStoreTests.swift macos/TodoFocusMac/Tests/CoreTests/KanbanViewBehaviorTests.swift macos/TodoFocusMac/TodoFocusMac.xcodeproj
git commit -m "feat(kanban): add project card detail editing"
```

---

### Task 10: Archive Browser and Data-Repair/Error UX

**Files:**
- Create: `macos/TodoFocusMac/Sources/Features/Kanban/KanbanArchiveView.swift`
- Modify: `macos/TodoFocusMac/Sources/Features/Kanban/KanbanView.swift`
- Modify: `macos/TodoFocusMac/Sources/App/KanbanStore.swift`
- Modify: `macos/TodoFocusMac/Tests/CoreTests/KanbanStoreTests.swift`
- Modify: `macos/TodoFocusMac/Tests/CoreTests/KanbanViewBehaviorTests.swift`

**Interfaces:**
- Consumes: archive/restore/delete repository methods and repair flag from Task 4.
- Produces: archived-card loading, restoration, permanent deletion, retryable load errors, and non-retryable destructive errors.

- [ ] **Step 1: Add failing archive and repair-warning tests**

```swift
func testRepairFallbackRaisesBanner() throws {
    let fake = FakeKanbanRepository(projects: [project("App")], fetchResult: .init(cards: [], dataRepairRequired: true))
    let store = KanbanStore(repository: fake)
    try store.load()
    XCTAssertTrue(store.showsDataRepairWarning)
}

func testRestoreReturnsCardToRetainedStatusBottom() throws {
    let store = try loadedStore(cards: [archivedCard("A", status: .blocked)])
    store.restoreCard(id: "A")
    XCTAssertEqual(store.cards.first { $0.id == "A" }?.status, .blocked)
}
```

- [ ] **Step 2: Run and verify failure**

Expected: FAIL until archived loading and repair-state propagation are implemented.

- [ ] **Step 3: Extend store archive state**

Add:

```swift
var archivedCards: [KanbanCard] = []
func loadArchivedCards()
func restoreCard(id: String)
func permanentlyDeleteArchivedCard(id: String)
```

`loadArchivedCards()` calls `fetchCards(projectID:includeArchived: true)` and filters to archived cards. Successful restore reloads active and archived arrays. Destructive failures show an error without a Retry action; load failures expose a retry closure.

- [ ] **Step 4: Build archive and repair UI**

The archive sheet lists title, retained status, priority, and archived-card actions. Restore is immediate; permanent delete uses confirmation. The board banner has separate copy:

```swift
static let repairWarning = "Some saved Kanban values were invalid. Affected cards are shown in Backlog with Medium priority."
```

A dismiss action hides the banner for the session. Do not silently rewrite fallback values; changing and saving the card repairs them explicitly. The inline error banner shows Retry only when `store.canRetryLastLoad` is true and calls `store.retryLastLoad()`.

- [ ] **Step 5: Run focused tests and commit**

```bash
git add macos/TodoFocusMac/Sources/Features/Kanban/KanbanArchiveView.swift macos/TodoFocusMac/Sources/Features/Kanban/KanbanView.swift macos/TodoFocusMac/Sources/App/KanbanStore.swift macos/TodoFocusMac/Tests/CoreTests/KanbanStoreTests.swift macos/TodoFocusMac/Tests/CoreTests/KanbanViewBehaviorTests.swift macos/TodoFocusMac/TodoFocusMac.xcodeproj
git commit -m "feat(kanban): add card archive and recovery flows"
```

---

### Task 11: Accessibility, Isolation Regression Tests, and Final Validation

**Files:**
- Modify: `macos/TodoFocusMac/Tests/CoreTests/KanbanViewBehaviorTests.swift`
- Modify: `macos/TodoFocusMac/Tests/CoreTests/TodoAppStoreTests.swift`
- Modify: `macos/TodoFocusMac/Tests/DataTests/KanbanRepositoryTests.swift`
- Modify only as failures require: `macos/TodoFocusMac/Sources/Features/Kanban/*.swift`
- Modify only as failures require: `macos/TodoFocusMac/Sources/App/KanbanStore.swift`

**Interfaces:**
- Consumes: complete feature.
- Produces: verified v1 behavior with no daily-task leakage.

- [ ] **Step 1: Add isolation and accessibility regression tests**

```swift
func testKanbanRowsNeverEnterTodoRepository() throws {
    let manager = try DatabaseManager(databasePath: ":memory:")
    let kanban = KanbanRepository(dbQueue: manager.dbQueue)
    let todos = TodoRepository(dbQueue: manager.dbQueue)
    let project = try kanban.createProject(.init(name: "App", color: "#C46849", goal: "Ship"), now: Date())
    _ = try kanban.createCard(.init(projectID: project.id, title: "Build board", status: .backlog), now: Date())
    XCTAssertTrue(try todos.fetchTodosOrdered().isEmpty)
}

func testCardAccessibilitySummaryIncludesWorkflowContext() {
    let card = cardWithChecklist(completed: 1, total: 2)
    let summary = KanbanCardView.accessibilitySummary(card)
    XCTAssertTrue(summary.contains("Backlog"))
    XCTAssertTrue(summary.contains("Medium"))
    XCTAssertTrue(summary.contains("1 of 2 checklist items complete"))
}
```

- [ ] **Step 2: Run the new tests and fix only concrete failures**

Run:

```bash
cd macos/TodoFocusMac
xcodegen generate
xcodebuild test -project TodoFocusMac.xcodeproj -scheme TodoFocusMac -destination 'platform=macOS' \
  -only-testing:CoreTests/KanbanViewBehaviorTests \
  -only-testing:CoreTests/TodoAppStoreTests \
  -only-testing:DataTests/KanbanRepositoryTests
```

Expected: PASS after adding `KanbanCardView.accessibilitySummary(_:)` and any missing labels/focus behavior. Do not broaden scope.

- [ ] **Step 3: Perform the manual user-flow contract**

Run the app and record evidence for each item:

1. Create two projects with different names, colors, and goals.
2. Confirm alphabetical switching and first-project fallback.
3. Add cards from Backlog and another column.
4. Reorder within one column and move across columns.
5. Restart and confirm project/card/status/order persistence.
6. Edit title, description, priority, due date, labels, and checklist.
7. Move a card to Done and confirm it stays visible.
8. Archive, restore, and permanently delete cards.
9. Delete a project and confirm fallback selection.
10. Use the detail status picker without dragging.
11. Confirm Kanban cards are absent from My Day, All Tasks, search, and Daily Review.
12. Confirm keyboard focus reaches project controls, columns/cards, and detail actions.

- [ ] **Step 4: Run full required verification**

```bash
cd macos/TodoFocusMac
xcodegen generate
xcodebuild test -project TodoFocusMac.xcodeproj -scheme TodoFocusMac -destination 'platform=macOS'
cd ../..
xcodebuild build \
  -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" \
  -scheme "TodoFocusMac" \
  -configuration Release \
  -derivedDataPath "macos/TodoFocusMac/build/DerivedData" \
  -destination "platform=macOS"
git diff --check
git status --short
```

Expected: XcodeGen succeeds; all tests pass with zero failures; Release build prints `** BUILD SUCCEEDED **`; `git diff --check` prints nothing. Any pre-existing unrelated working-tree changes must remain unstaged.

- [ ] **Step 5: Commit final validation fixes**

```bash
git add macos/TodoFocusMac/Sources/Features/Kanban macos/TodoFocusMac/Sources/App/KanbanStore.swift macos/TodoFocusMac/Tests/CoreTests/KanbanViewBehaviorTests.swift macos/TodoFocusMac/Tests/CoreTests/TodoAppStoreTests.swift macos/TodoFocusMac/Tests/DataTests/KanbanRepositoryTests.swift macos/TodoFocusMac/TodoFocusMac.xcodeproj
git commit -m "test(kanban): verify project board user flows"
```

If Step 4 required no source/test changes, skip this empty commit.
