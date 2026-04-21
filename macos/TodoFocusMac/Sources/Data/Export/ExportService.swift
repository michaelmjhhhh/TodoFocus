import Foundation
import GRDB

enum ExportError: Error, LocalizedError {
    case unsupportedVersion
    case invalidImportData([String])
    case backupFailed(String)
    case invalidStoredLaunchResources(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedVersion:
            return "Unsupported export file version"
        case .invalidImportData(let errors):
            return errors.joined(separator: "\n")
        case .backupFailed(let message):
            return message
        case .invalidStoredLaunchResources(let todoID):
            return "Stored launch resources for todo \(todoID) are invalid"
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

    func exportToJSON(strictLaunchResourceValidation: Bool = true) throws -> Data {
        let snapshot = try dbQueue.read { db -> (lists: [ExportList], todos: [ExportTodo]) in
            let listRecords = try ListRecord.fetchAll(db)
            let todoRecords = try TodoRecord.fetchAll(db)
            let stepRecords = try StepRecord
                .order(Column("todoId").asc, Column("sortOrder").asc)
                .fetchAll(db)

            let stepsByTodoID = Dictionary(grouping: stepRecords, by: \.todoId)

            let lists = listRecords.map { record in
                ExportList(
                    id: record.id,
                    name: record.name,
                    color: record.color,
                    sortOrder: record.sortOrder
                )
            }

            let todos = try todoRecords.map { record -> ExportTodo in
                let steps = (stepsByTodoID[record.id] ?? []).map { step in
                    ExportStep(
                        id: step.id,
                        title: step.title,
                        isCompleted: step.isCompleted,
                        sortOrder: step.sortOrder
                    )
                }

                let resources = try decodeLaunchResourcesForExport(
                    record.launchResources,
                    todoID: record.id,
                    strict: strictLaunchResourceValidation
                )
                let portableResources = resources.filter { $0.type == .url }

                return ExportTodo(
                    id: record.id,
                    title: record.title,
                    isCompleted: record.isCompleted,
                    isArchived: record.isArchived,
                    isImportant: record.isImportant,
                    isMyDay: record.isMyDay,
                    dueDate: record.dueDate,
                    notes: record.notes,
                    listId: record.listId,
                    focusTimeSeconds: record.focusTimeSeconds,
                    recurrence: record.recurrence,
                    recurrenceInterval: record.recurrenceInterval,
                    sortOrder: record.sortOrder,
                    createdAt: record.createdAt,
                    updatedAt: record.updatedAt,
                    lastCompletedAt: record.lastCompletedAt,
                    steps: steps,
                    launchResources: portableResources.map { ExportLaunchResource(type: $0.type.rawValue, value: $0.value, label: $0.label) }
                )
            }

            return (lists: lists, todos: todos)
        }

        let exportData = ExportData(
            version: ExportFormatVersion.current,
            exportedAt: Date(),
            meta: ExportMeta(
                appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                platform: "macOS",
                importHints: [
                    "supportsModes:replace,merge",
                    "backupBeforeReplace:true",
                    "portableLaunchResources:urlOnly",
                    "deviceLocalStateExcluded:true"
                ]
            ),
            lists: snapshot.lists,
            todos: snapshot.todos
        )

        return try exportData.encode()
    }

    func preflightImportJSON(_ data: Data, mode: ImportMode = .replace) throws -> ImportPreflightResult {
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

        let importedListIDs = Set(importData.lists.map(\.id))
        let existingListIDs = try dbQueue.read { db -> Set<String> in
            Set(try ListRecord.fetchAll(db).map(\.id))
        }
        for todo in importData.todos {
            guard let listID = todo.listId else { continue }
            if importedListIDs.contains(listID) {
                continue
            }
            if mode == .merge, existingListIDs.contains(listID) {
                continue
            }
            blockingErrors.append("Todo \(todo.id) references missing listId '\(listID)'")
        }

        if importData.lists.isEmpty && importData.todos.isEmpty {
            warnings.append("Import file contains no lists or todos")
        }

        let nonPortableLaunchResourceCount = importData.todos.reduce(0) { partial, todo in
            partial + todo.launchResources.filter { $0.type != LaunchResourceType.url.rawValue }.count
        }
        if nonPortableLaunchResourceCount > 0 {
            warnings.append("Found \(nonPortableLaunchResourceCount) non-portable launch resources (file/app). They will be skipped.")
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
        let preflight = try preflightImportJSON(data, mode: mode)
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
                try db.execute(sql: "DELETE FROM hardfocus_session")
                try db.execute(sql: "DELETE FROM agent_heartbeat")
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
                let createdAt = todo.createdAt ?? existingTodo?.createdAt ?? now
                let updatedAt = todo.updatedAt ?? now
                let record = TodoRecord(
                    id: todo.id,
                    title: todo.title,
                    isCompleted: todo.isCompleted || todo.isArchived,
                    isArchived: todo.isArchived,
                    isImportant: todo.isImportant,
                    isMyDay: todo.isMyDay,
                    recurrence: todo.recurrence,
                    recurrenceInterval: max(1, todo.recurrenceInterval),
                    lastCompletedAt: todo.lastCompletedAt ?? existingTodo?.lastCompletedAt,
                    notes: todo.notes,
                    launchResources: "[]",
                    dueDate: todo.dueDate,
                    sortOrder: todo.sortOrder,
                    createdAt: createdAt,
                    updatedAt: updatedAt,
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
                    if mode == .merge, let existingStep = try StepRecord.fetchOne(db, key: step.id) {
                        if existingStep.todoId != todo.id {
                            report.skipped.steps += 1
                            report.errors.append("Skipped step \(step.id): belongs to another todo (\(existingStep.todoId))")
                            continue
                        }
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
                    guard type == .url else {
                        report.skipped.launchResources += 1
                        return nil
                    }
                    return LaunchResource(
                        id: UUID().uuidString,
                        type: type,
                        label: er.label,
                        value: er.value,
                        createdAt: Date()
                    )
                }.compactMap { candidate -> LaunchResource? in
                    switch validateLaunchResource(candidate) {
                    case .success(let validated):
                        return validated
                    case .failure(let error):
                        report.skipped.launchResources += 1
                        report.errors.append("Invalid URL launch resource for todo \(todo.id): \(launchResourceValidationErrorDescription(error))")
                        return nil
                    }
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

    private func decodeLaunchResourcesForExport(_ raw: String?, todoID: String, strict: Bool) throws -> [LaunchResource] {
        guard let raw else { return [] }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        if !strict {
            return parseLaunchResources(raw: trimmed)
        }

        guard let data = trimmed.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data),
              let array = object as? [Any] else {
            throw ExportError.invalidStoredLaunchResources(todoID)
        }

        let parsed = parseLaunchResources(raw: trimmed)
        if parsed.count != array.count {
            throw ExportError.invalidStoredLaunchResources(todoID)
        }
        return parsed
    }

    private func launchResourceValidationErrorDescription(_ error: LaunchResourceValidationError) -> String {
        switch error {
        case .invalidType:
            return "invalid type"
        case .invalidLabel:
            return "invalid label"
        case .invalidValue:
            return "invalid value"
        case .invalidURL:
            return "invalid URL"
        case .invalidFilePath:
            return "invalid file path"
        case .invalidAppTarget:
            return "invalid app target"
        }
    }

    private func createBackupSnapshot() throws -> String {
        let backupData: Data
        do {
            // Recovery backups should not be blocked by malformed legacy launch-resource payloads.
            backupData = try exportToJSON(strictLaunchResourceValidation: false)
        } catch {
            throw ExportError.backupFailed("Failed to create backup snapshot before replace import")
        }

        let fm = FileManager.default
        let base = URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent("Library/Application Support/todofocus/backups", isDirectory: true)
        try fm.createDirectory(at: base, withIntermediateDirectories: true)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss-SSS"
        let suffix = UUID().uuidString.prefix(8).lowercased()
        let filename = "todofocus-backup-\(formatter.string(from: Date()))-\(suffix).json"
        let path = base.appendingPathComponent(filename)
        do {
            try backupData.write(to: path, options: .atomic)
            return path.path
        } catch {
            throw ExportError.backupFailed("Failed to write backup snapshot before replace import")
        }
    }
}
