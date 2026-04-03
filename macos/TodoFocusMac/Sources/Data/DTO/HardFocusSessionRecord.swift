import Foundation
import GRDB

enum HardFocusStatus: String, Codable, DatabaseValueConvertible {
    case active
    case completed
    case interrupted
}

struct HardFocusSessionRecord: Codable, FetchableRecord, PersistableRecord, Equatable, Identifiable {
    var id: String { sessionId }
    static let databaseTableName = "hardfocus_session"
    static let databasePrimaryKey: [String]? = ["session_id"]

    var sessionId: String
    var mode: String
    var status: HardFocusStatus
    var startTime: Date
    var plannedEndTime: Date
    var actualEndTime: Date?
    var unlockPhraseHash: String
    var unlockPhraseSalt: String
    var blockedApps: String
    var focusTaskId: String?
    var graceSeconds: Int
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case mode
        case status
        case startTime = "start_time"
        case plannedEndTime = "planned_end_time"
        case actualEndTime = "actual_end_time"
        case unlockPhraseHash = "unlock_phrase_hash"
        case unlockPhraseSalt = "unlock_phrase_salt"
        case blockedApps = "blocked_apps"
        case focusTaskId = "focus_task_id"
        case graceSeconds = "grace_seconds"
        case createdAt = "created_at"
    }

    var blockedAppsBundleIds: [String] {
        guard let data = blockedApps.data(using: .utf8),
              let ids = try? JSONDecoder().decode([String].self, from: data)
        else { return [] }
        return ids
    }
}
