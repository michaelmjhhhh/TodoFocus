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
        let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        let dir = appSupport.appendingPathComponent("todofocus", isDirectory: true)
        return dir.appendingPathComponent("todofocus.db").path
    }
}
