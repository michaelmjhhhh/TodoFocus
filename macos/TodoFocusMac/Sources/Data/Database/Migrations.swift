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

        migrator.registerMigration("v3_hardfocus") { db in
            try db.create(table: "hardfocus_session") { t in
                t.column("session_id", .text).primaryKey()
                t.column("mode", .text).notNull()
                t.column("status", .text).notNull().defaults(to: "active")
                t.column("start_time", .datetime).notNull()
                t.column("planned_end_time", .datetime).notNull()
                t.column("actual_end_time", .datetime)
                t.column("unlock_phrase_hash", .text).notNull()
                t.column("blocked_apps", .text).notNull()
                t.column("focus_task_id", .text)
                t.column("grace_seconds", .integer).notNull().defaults(to: 300)
                t.column("created_at", .datetime).notNull()
            }

            try db.create(table: "agent_heartbeat") { t in
                t.column("agent_id", .text).primaryKey().defaults(to: "primary")
                t.column("last_heartbeat", .datetime).notNull()
                t.column("current_session_id", .text)
            }

            try db.create(
                index: "idx_session_active",
                on: "hardfocus_session",
                columns: ["status"],
                condition: Column("status") == "active"
            )
        }

        migrator.registerMigration("v4_add_salt_to_hardfocus") { db in
            try db.execute(sql: "ALTER TABLE hardfocus_session ADD COLUMN unlock_phrase_salt TEXT NOT NULL DEFAULT ''")
        }

        return migrator
    }
}
