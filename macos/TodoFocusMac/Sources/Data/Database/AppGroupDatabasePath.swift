import Foundation

enum AppGroupDatabasePath {
    static func defaultDatabasePath(appGroupIdentifier: String = "group.com.todofocus") -> String {
        let fm = FileManager.default
        let containerURL = fm.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support/todofocus")
        return containerURL.appendingPathComponent("todofocus.db").path
    }
}
