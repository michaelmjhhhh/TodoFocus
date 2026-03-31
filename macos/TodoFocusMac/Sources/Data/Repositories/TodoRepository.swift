import Foundation
import GRDB

struct AddTodoInput {
    let title: String
    let listID: String?
    let isMyDay: Bool
    let isImportant: Bool
    let planned: Bool
}

struct UpdateTodoInput {
    var title: String?
    var isCompleted: Bool?
    var isImportant: Bool?
    var isMyDay: Bool?
    var recurrence: String??
    var recurrenceInterval: Int?
    var lastCompletedAt: Date??
    var notes: String?
    var launchResources: String??
    var dueDate: Date??
    var listID: String??
    var focusTimeSeconds: Int?
}

enum TodoRepositoryError: Error, Equatable {
    case invalidTitle
    case notFound
    case invalidLaunchResources
    case launchResourcesTooLarge
}

struct TodoRepository {
    private let dbQueue: DatabaseQueue

    init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }

    func addTodo(_ input: AddTodoInput, now: Date = Date()) throws -> TodoRecord {
        let trimmedTitle = input.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            throw TodoRepositoryError.invalidTitle
        }

        let created = try dbQueue.write { db in
            let count = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM todo") ?? 0
            let record = TodoRecord(
                id: UUID().uuidString,
                title: trimmedTitle,
                isCompleted: false,
                isImportant: input.isImportant,
                isMyDay: input.isMyDay,
                recurrence: nil,
                recurrenceInterval: 1,
                lastCompletedAt: nil,
                notes: "",
                launchResources: "[]",
                dueDate: input.planned ? now : nil,
                sortOrder: count,
                createdAt: now,
                updatedAt: now,
                listId: input.listID?.isEmpty == true ? nil : input.listID,
                focusTimeSeconds: 0
            )
            try record.insert(db)
            return record
        }

        return created
    }

    func updateTodo(id: String, input: UpdateTodoInput, now: Date = Date()) throws {
        try dbQueue.write { db in
            guard var current = try TodoRecord.fetchOne(db, key: id) else {
                throw TodoRepositoryError.notFound
            }

            if let title = input.title {
                current.title = title
            }
            if let isCompleted = input.isCompleted {
                current.isCompleted = isCompleted
            }
            if let isImportant = input.isImportant {
                current.isImportant = isImportant
            }
            if let isMyDay = input.isMyDay {
                current.isMyDay = isMyDay
            }
            if let recurrence = input.recurrence {
                current.recurrence = recurrence
                if recurrence == nil {
                    current.recurrenceInterval = 1
                    current.lastCompletedAt = nil
                }
            }
            if let recurrenceInterval = input.recurrenceInterval {
                current.recurrenceInterval = max(1, recurrenceInterval)
            }
            if let lastCompletedAt = input.lastCompletedAt {
                current.lastCompletedAt = lastCompletedAt
            }
            if let notes = input.notes {
                current.notes = notes
            }
            if let launchResources = input.launchResources {
                let serialized = try normalizeLaunchResources(launchResources)
                current.launchResources = serialized
            }
            if let dueDate = input.dueDate {
                current.dueDate = dueDate
            }
            if let listID = input.listID {
                current.listId = (listID?.isEmpty == true) ? nil : listID
            }
            if let focusTimeSeconds = input.focusTimeSeconds {
                current.focusTimeSeconds = focusTimeSeconds
            }

            current.updatedAt = now
            try current.update(db)
        }
    }

    func updateNotes(id: String, notes: String, now: Date = Date()) throws {
        var patch = UpdateTodoInput()
        patch.notes = notes
        try updateTodo(id: id, input: patch, now: now)
    }

    func setDueDate(id: String, dueDate: Date?, now: Date = Date()) throws {
        var patch = UpdateTodoInput()
        patch.dueDate = .some(dueDate)
        try updateTodo(id: id, input: patch, now: now)
    }

    func updateTitle(id: String, title: String, now: Date = Date()) throws {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            throw TodoRepositoryError.invalidTitle
        }

        var patch = UpdateTodoInput()
        patch.title = trimmedTitle
        try updateTodo(id: id, input: patch, now: now)
    }

    func fetchTodosOrdered() throws -> [TodoRecord] {
        try dbQueue.read { db in
            try TodoRecord
                .order(
                    Column("isCompleted").asc,
                    Column("sortOrder").asc,
                    Column("createdAt").desc
                )
                .fetchAll(db)
        }
    }

    func fetchTodo(id: String) throws -> TodoRecord? {
        try dbQueue.read { db in
            try TodoRecord.fetchOne(db, key: id)
        }
    }

    func deleteTodo(id: String) throws {
        try dbQueue.write { db in
            let deleted = try TodoRecord.deleteOne(db, key: id)
            guard deleted else {
                throw TodoRepositoryError.notFound
            }
        }
    }

    func clearCompletedTodos() throws -> Int {
        try dbQueue.write { db in
            try db.execute(sql: "DELETE FROM todo WHERE isCompleted = 1")
            return Int(db.changesCount)
        }
    }

    private func normalizeLaunchResources(_ value: String?) throws -> String {
        guard let value else { return "[]" }
        if value.count > 16_000 {
            throw TodoRepositoryError.launchResourcesTooLarge
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return "[]"
        }

        guard let data = trimmed.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data),
              object is [Any] else {
            throw TodoRepositoryError.invalidLaunchResources
        }

        return trimmed
    }
}
