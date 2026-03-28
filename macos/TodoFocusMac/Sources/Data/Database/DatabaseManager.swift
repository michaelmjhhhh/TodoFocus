import Foundation
import GRDB

final class DatabaseManager {
    let dbQueue: DatabaseQueue
    let path: String

    init(databasePath: String? = nil) throws {
        var config = Configuration()
        config.foreignKeysEnabled = true

        let path = databasePath ?? Self.defaultDatabasePath()
        self.path = path
        let dir = URL(fileURLWithPath: path).deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        dbQueue = try DatabaseQueue(path: path, configuration: config)
        try Migrations.makeMigrator().migrate(dbQueue)
    }

    private static func defaultDatabasePath() -> String {
        let fm = FileManager.default
        let containerURL = fm.containerURL(forSecurityApplicationGroupIdentifier: "group.com.todofocus")
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support/todofocus")
        return containerURL.appendingPathComponent("todofocus.db").path
    }

    func clearAllTables() throws {
        try dbQueue.write { db in
            try db.execute(sql: "DELETE FROM step")
            try db.execute(sql: "DELETE FROM todo")
            try db.execute(sql: "DELETE FROM list")
        }
    }
}
