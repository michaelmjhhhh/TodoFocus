import Foundation
import GRDB

enum ExportError: Error, LocalizedError {
    case unsupportedVersion
    case invalidImportData([String])
    case backupFailed(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedVersion:
            return "Unsupported export file version"
        case .invalidImportData(let errors):
            return errors.joined(separator: "\n")
        case .backupFailed(let message):
            return message
        }
    }
}

enum ImportMode: String, CaseIterable, Identifiable {
    case replace
    case merge

    var id: String { rawValue }

    var title: String {
        switch self {
        case .replace: return "Replace existing data"
        case .merge: return "Merge into existing data"
        }
    }
}

struct ImportEntityCounts {
    var lists: Int = 0
    var todos: Int = 0
    var steps: Int = 0
    var launchResources: Int = 0
}

struct ImportPreflightResult {
    let version: String
    let counts: ImportEntityCounts
    let warnings: [String]
    let blockingErrors: [String]
}

struct ImportExecutionReport {
    let mode: ImportMode
    var created: ImportEntityCounts
    var updated: ImportEntityCounts
    var skipped: ImportEntityCounts
    var errors: [String]
    var backupFilePath: String?
}

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
            try TodoRecord.fetchAll(db).map { record -> ExportTodo in
                let steps = try StepRecord
                    .filter(Column("todoId") == record.id)
                    .order(Column("sortOrder").asc)
                    .fetchAll(db)
                    .map { step in
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
                    notes: record.notes,
                    listId: record.listId,
                    focusTimeSeconds: record.focusTimeSeconds,
                    recurrence: record.recurrence,
                    recurrenceInterval: record.recurrenceInterval,
                    sortOrder: record.sortOrder,
                    steps: steps,
                    launchResources: resources.map { ExportLaunchResource(type: $0.type.rawValue, value: $0.value, label: $0.label) }
                )
            }
        }

        let exportData = ExportData(
            version: ExportFormatVersion.current,
            exportedAt: Date(),
            meta: ExportMeta(
                appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                platform: "macOS",
                importHints: ["supportsModes:replace,merge", "backupBeforeReplace:true"]
            ),
            lists: lists,
            todos: todos
        )

        return try exportData.encode()
    }

    func preflightImportJSON(_ data: Data) throws -> ImportPreflightResult {
        let importData = try ExportData.decode(from: data)
        var warnings: [String] = []
        var blockingErrors: [String] = []

        if !ExportFormatVersion.isSupported(importData.version) {
            blockingErrors.append("Unsupported export file version: \(importData.version)")
        }

        let listIDs = Set(importData.lists.map(\.id))
        if listIDs.count != importData.lists.count {
            blockingErrors.append("Duplicate list IDs detected in import file")
        }

        let todoIDs = Set(importData.todos.map(\.id))
        if todoIDs.count != importData.todos.count {
            blockingErrors.append("Duplicate todo IDs detected in import file")
        }

        let stepIDs = Set(importData.todos.flatMap(\.steps).map(\.id))
        let rawStepCount = importData.todos.reduce(0) { $0 + $1.steps.count }
        if stepIDs.count != rawStepCount {
            blockingErrors.append("Duplicate step IDs detected in import file")
        }

        if importData.lists.isEmpty && importData.todos.isEmpty {
            warnings.append("Import file contains no lists or todos")
        }

        let launchResourceCount = importData.todos.reduce(0) { $0 + $1.launchResources.count }
        let counts = ImportEntityCounts(
            lists: importData.lists.count,
            todos: importData.todos.count,
            steps: rawStepCount,
            launchResources: launchResourceCount
        )

        return ImportPreflightResult(
            version: importData.version,
            counts: counts,
            warnings: warnings,
            blockingErrors: blockingErrors
        )
    }

    func executeImportJSON(_ data: Data, mode: ImportMode) throws -> ImportExecutionReport {
        let preflight = try preflightImportJSON(data)
        if !preflight.blockingErrors.isEmpty {
            throw ExportError.invalidImportData(preflight.blockingErrors)
        }

        let importData = try ExportData.decode(from: data)
        var report = ImportExecutionReport(
            mode: mode,
            created: .init(),
            updated: .init(),
            skipped: .init(),
            errors: [],
            backupFilePath: nil
        )

        if mode == .replace {
            report.backupFilePath = try createBackupSnapshot()
        }

        try dbQueue.write { db in
            if mode == .replace {
                try db.execute(sql: "DELETE FROM step")
                try db.execute(sql: "DELETE FROM todo")
                try db.execute(sql: "DELETE FROM list")
            }

            for list in importData.lists {
                if mode == .merge, var existing = try ListRecord.fetchOne(db, key: list.id) {
                    existing.name = list.name
                    existing.color = list.color
                    existing.sortOrder = list.sortOrder
                    existing.updatedAt = Date()
                    try existing.update(db)
                    report.updated.lists += 1
                } else {
                    let record = ListRecord(
                        id: list.id,
                        name: list.name,
                        color: list.color,
                        sortOrder: list.sortOrder,
                        createdAt: Date(),
                        updatedAt: Date()
                    )
                    try record.insert(db)
                    report.created.lists += 1
                }
            }

            for todo in importData.todos {
                let now = Date()
                let existingTodo = (mode == .merge) ? try TodoRecord.fetchOne(db, key: todo.id) : nil
                let createdAt = existingTodo?.createdAt ?? now
                var record = TodoRecord(
                    id: todo.id,
                    title: todo.title,
                    isCompleted: todo.isCompleted,
                    isImportant: todo.isImportant,
                    isMyDay: todo.isMyDay,
                    recurrence: todo.recurrence,
                    recurrenceInterval: max(1, todo.recurrenceInterval),
                    lastCompletedAt: existingTodo?.lastCompletedAt,
                    notes: todo.notes,
                    launchResources: "[]",
                    dueDate: todo.dueDate,
                    sortOrder: todo.sortOrder,
                    createdAt: createdAt,
                    updatedAt: now,
                    listId: todo.listId,
                    focusTimeSeconds: todo.focusTimeSeconds ?? 0
                )

                if existingTodo != nil {
                    try record.update(db)
                    report.updated.todos += 1
                } else {
                    try record.insert(db)
                    report.created.todos += 1
                }

                for step in todo.steps {
                    let stepRecord = StepRecord(
                        id: step.id,
                        title: step.title,
                        isCompleted: step.isCompleted,
                        sortOrder: step.sortOrder,
                        todoId: todo.id
                    )
                    if mode == .merge, try StepRecord.fetchOne(db, key: step.id) != nil {
                        try stepRecord.update(db)
                        report.updated.steps += 1
                    } else {
                        try stepRecord.insert(db)
                        report.created.steps += 1
                    }
                }

                let validResources = todo.launchResources.compactMap { er -> LaunchResource? in
                    guard let type = LaunchResourceType(rawValue: er.type) else {
                        report.skipped.launchResources += 1
                        report.errors.append("Unsupported launch resource type '\(er.type)' for todo \(todo.id)")
                        return nil
                    }
                    return LaunchResource(
                        id: UUID().uuidString,
                        type: type,
                        label: er.label,
                        value: er.value,
                        createdAt: Date()
                    )
                }
                let encoded = try JSONEncoder().encode(validResources)
                try db.execute(
                    sql: "UPDATE todo SET launchResources = ? WHERE id = ?",
                    arguments: [String(data: encoded, encoding: .utf8), todo.id]
                )
                if existingTodo != nil {
                    report.updated.launchResources += validResources.count
                } else {
                    report.created.launchResources += validResources.count
                }
            }
        }

        return report
    }

    func importFromJSON(_ data: Data) throws {
        _ = try executeImportJSON(data, mode: .replace)
    }

    private func decodeLaunchResources(_ raw: String?) throws -> [LaunchResource] {
        guard let raw, !raw.isEmpty else { return [] }
        return try JSONDecoder().decode([LaunchResource].self, from: Data(raw.utf8))
    }

    private func createBackupSnapshot() throws -> String {
        let backupData: Data
        do {
            backupData = try exportToJSON()
        } catch {
            throw ExportError.backupFailed("Failed to create backup snapshot before replace import")
        }

        let fm = FileManager.default
        let base = URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent("Library/Application Support/todofocus/backups", isDirectory: true)
        try fm.createDirectory(at: base, withIntermediateDirectories: true)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let filename = "todofocus-backup-\(formatter.string(from: Date())).json"
        let path = base.appendingPathComponent(filename)
        do {
            try backupData.write(to: path, options: .atomic)
            return path.path
        } catch {
            throw ExportError.backupFailed("Failed to write backup snapshot before replace import")
        }
    }
}
