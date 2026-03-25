import Foundation
import GRDB

enum ExportError: Error, LocalizedError {
    case unsupportedVersion

    var errorDescription: String? {
        switch self {
        case .unsupportedVersion:
            return "Unsupported export file version"
        }
    }
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
                    notes: record.notes ?? "",
                    listId: record.listId,
                    focusTimeSeconds: record.focusTimeSeconds,
                    steps: steps,
                    launchResources: resources.map { ExportLaunchResource(type: $0.type.rawValue, value: $0.value, label: $0.label) }
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

    func importFromJSON(_ data: Data) throws {
        let importData = try ExportData.decode(from: data)

        guard importData.version == "1.0" else {
            throw ExportError.unsupportedVersion
        }

        try dbQueue.write { db in
            try db.execute(sql: "DELETE FROM step")
            try db.execute(sql: "DELETE FROM todo")
            try db.execute(sql: "DELETE FROM list")

            for list in importData.lists {
                let record = ListRecord(
                    id: list.id,
                    name: list.name,
                    color: list.color,
                    sortOrder: list.sortOrder,
                    createdAt: Date(),
                    updatedAt: Date()
                )
                try record.insert(db)
            }

            for todo in importData.todos {
                var record = TodoRecord(
                    id: todo.id,
                    title: todo.title,
                    isCompleted: todo.isCompleted,
                    isImportant: todo.isImportant,
                    isMyDay: todo.isMyDay,
                    recurrence: nil,
                    recurrenceInterval: 1,
                    lastCompletedAt: nil,
                    notes: todo.notes,
                    launchResources: "[]",
                    dueDate: todo.dueDate,
                    sortOrder: 0,
                    createdAt: Date(),
                    updatedAt: Date(),
                    listId: todo.listId,
                    focusTimeSeconds: todo.focusTimeSeconds ?? 0
                )
                try record.insert(db)

                for step in todo.steps {
                    let stepRecord = StepRecord(
                        id: step.id,
                        title: step.title,
                        isCompleted: step.isCompleted,
                        sortOrder: step.sortOrder,
                        todoId: todo.id
                    )
                    try stepRecord.insert(db)
                }

                if !todo.launchResources.isEmpty {
                    let resources = todo.launchResources.map { er in
                        LaunchResource(
                            id: UUID().uuidString,
                            type: LaunchResourceType(rawValue: er.type) ?? .url,
                            label: er.label,
                            value: er.value,
                            createdAt: Date()
                        )
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

    private func decodeLaunchResources(_ raw: String?) throws -> [LaunchResource] {
        guard let raw, !raw.isEmpty else { return [] }
        return try JSONDecoder().decode([LaunchResource].self, from: Data(raw.utf8))
    }
}
