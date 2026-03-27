import XCTest
@testable import TodoFocusMac

final class AgentHeartbeatRecordTests: XCTestCase {
    func testHeartbeatRecordDefaultAgentId() {
        let record = AgentHeartbeatRecord(
            agentId: "primary",
            lastHeartbeat: Date(),
            currentSessionId: nil
        )
        XCTAssertEqual(record.agentId, "primary")
        XCTAssertNil(record.currentSessionId)
    }

    func testHeartbeatRecordWithSessionId() {
        let record = AgentHeartbeatRecord(
            agentId: "primary",
            lastHeartbeat: Date(),
            currentSessionId: "session-123"
        )
        XCTAssertEqual(record.currentSessionId, "session-123")
    }
}