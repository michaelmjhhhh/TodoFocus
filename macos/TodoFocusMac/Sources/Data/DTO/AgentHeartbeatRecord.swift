import Foundation
import GRDB

struct AgentHeartbeatRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "agent_heartbeat"
    static let databasePrimaryKey: [String]? = ["agent_id"]

    var agentId: String
    var lastHeartbeat: Date
    var currentSessionId: String?

    enum CodingKeys: String, CodingKey {
        case agentId = "agent_id"
        case lastHeartbeat = "last_heartbeat"
        case currentSessionId = "current_session_id"
    }
}
