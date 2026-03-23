import Foundation
import GRDB

enum Migrations {
    static func makeMigrator() -> DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1_create_list_todo_step") { db in
            try db.create(table: "list") { t in
                t.column("id", .text).primaryKey()
                t.column("name", .text).notNull()
                t.column("color", .text).notNull().defaults(to: "#6366F1")
                t.column("sortOrder", .integer).notNull().defaults(to: 0)
                t.column("createdAt", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
                t.column("updatedAt", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
            }

            try db.create(table: "todo") { t in
                t.column("id", .text).primaryKey()
                t.column("title", .text).notNull()
                t.column("isCompleted", .boolean).notNull().defaults(to: false)
                t.column("isImportant", .boolean).notNull().defaults(to: false)
                t.column("isMyDay", .boolean).notNull().defaults(to: false)
                t.column("recurrence", .text)
                t.column("recurrenceInterval", .integer).notNull().defaults(to: 1)
                t.column("lastCompletedAt", .datetime)
                t.column("notes", .text).notNull().defaults(to: "")
                t.column("launchResources", .text).notNull().defaults(to: "[]")
                t.column("dueDate", .datetime)
                t.column("sortOrder", .integer).notNull().defaults(to: 0)
                t.column("createdAt", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
                t.column("updatedAt", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
                t.column("listId", .text).references("list", onDelete: .cascade)
            }

            try db.create(table: "step") { t in
                t.column("id", .text).primaryKey()
                t.column("title", .text).notNull()
                t.column("isCompleted", .boolean).notNull().defaults(to: false)
                t.column("sortOrder", .integer).notNull().defaults(to: 0)
                t.column("todoId", .text).notNull().references("todo", onDelete: .cascade)
            }

            try db.create(index: "idx_list_sortOrder", on: "list", columns: ["sortOrder"])
            try db.create(index: "idx_todo_listId", on: "todo", columns: ["listId"])
            try db.create(index: "idx_todo_completed_sort_created", on: "todo", columns: ["isCompleted", "sortOrder", "createdAt"])
            try db.create(index: "idx_step_todo_sort", on: "step", columns: ["todoId", "sortOrder"])
        }

        migrator.registerMigration("v2_add_focus_time") { db in
            try db.execute(sql: "ALTER TABLE todo ADD COLUMN focusTimeSeconds INTEGER NOT NULL DEFAULT 0")
        }

        return migrator
    }
}
