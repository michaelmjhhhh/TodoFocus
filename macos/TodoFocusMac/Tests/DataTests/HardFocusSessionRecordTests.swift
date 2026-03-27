import XCTest
@testable import TodoFocusMac

final class HardFocusSessionRecordTests: XCTestCase {
    func testSessionRecordMapsAllFields() {
        let now = Date()
        let plannedEnd = now.addingTimeInterval(3600)
        let record = HardFocusSessionRecord(
            sessionId: "test-id",
            mode: "hard",
            status: "active",
            startTime: now,
            plannedEndTime: plannedEnd,
            actualEndTime: nil,
            unlockPhraseHash: "argon2hash",
            blockedApps: #"["com.apple.Safari"]"#,
            focusTaskId: nil,
            graceSeconds: 300,
            createdAt: now
        )

        XCTAssertEqual(record.sessionId, "test-id")
        XCTAssertEqual(record.mode, "hard")
        XCTAssertEqual(record.status, "active")
        XCTAssertEqual(record.startTime.timeIntervalSince1970, now.timeIntervalSince1970, accuracy: 1)
        XCTAssertEqual(record.plannedEndTime.timeIntervalSince1970, plannedEnd.timeIntervalSince1970, accuracy: 1)
        XCTAssertNil(record.actualEndTime)
        XCTAssertEqual(record.unlockPhraseHash, "argon2hash")
        XCTAssertEqual(record.blockedApps, #"["com.apple.Safari"]"#)
        XCTAssertNil(record.focusTaskId)
        XCTAssertEqual(record.graceSeconds, 300)
        XCTAssertEqual(record.createdAt.timeIntervalSince1970, now.timeIntervalSince1970, accuracy: 1)
    }

    func testBlockedAppsDecodeToBundleIds() {
        let record = HardFocusSessionRecord(
            sessionId: "test-id",
            mode: "hard",
            status: "active",
            startTime: Date(),
            plannedEndTime: Date().addingTimeInterval(3600),
            actualEndTime: nil,
            unlockPhraseHash: "argon2hash",
            blockedApps: #"["com.google.Chrome","com.hnc.Discord"]"#,
            focusTaskId: nil,
            graceSeconds: 300,
            createdAt: Date()
        )

        let bundleIds = record.blockedAppsBundleIds
        XCTAssertEqual(bundleIds.count, 2)
        XCTAssertTrue(bundleIds.contains("com.google.Chrome"))
    }
}
