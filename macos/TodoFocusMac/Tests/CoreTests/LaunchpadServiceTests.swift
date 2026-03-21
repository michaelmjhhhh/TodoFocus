import Foundation
import XCTest
@testable import TodoFocusMac

final class LaunchpadServiceTests: XCTestCase {
    func testLaunchAllProcessesSequentiallyWithMixedResults() {
        let opener = MockLaunchOpener()
        opener.urlResults = [true]
        opener.fileResults = [false]
        opener.appResults = [true]
        let service = LaunchpadService(opener: opener)

        let resources = [
            makeResource(id: "1", type: .url, label: "Docs", value: "https://example.com"),
            makeResource(id: "2", type: .file, label: "File", value: "/Users/me/file.txt"),
            makeResource(id: "3", type: .app, label: "App", value: "/Applications/Notes.app")
        ]

        let summary = service.launchAll(resources)

        XCTAssertEqual(summary.launchedCount, 2)
        XCTAssertEqual(summary.failedCount, 1)
        XCTAssertEqual(summary.rejectedCount, 0)
        XCTAssertEqual(opener.callOrder, ["url:https://example.com", "file:/Users/me/file.txt", "app:/Applications/Notes.app"])
    }

    func testLaunchAllRejectsInvalidWithoutBlockingFollowingItems() {
        let opener = MockLaunchOpener()
        opener.urlResults = [true]
        let service = LaunchpadService(opener: opener)

        let resources = [
            makeResource(id: "bad", type: .url, label: "Bad", value: "javascript:alert(1)"),
            makeResource(id: "good", type: .url, label: "Good", value: "https://example.com")
        ]

        let summary = service.launchAll(resources)

        XCTAssertEqual(summary.launchedCount, 1)
        XCTAssertEqual(summary.failedCount, 0)
        XCTAssertEqual(summary.rejectedCount, 1)
        XCTAssertEqual(summary.results.map(\.status), [.rejected, .launched])
    }

    private func makeResource(id: String, type: LaunchResourceType, label: String, value: String) -> LaunchResource {
        LaunchResource(id: id, type: type, label: label, value: value, createdAt: Date(timeIntervalSince1970: 1_763_520_000))
    }
}

private final class MockLaunchOpener: LaunchOpening {
    var urlResults: [Bool] = []
    var fileResults: [Bool] = []
    var appResults: [Bool] = []
    var callOrder: [String] = []

    func open(url: URL) -> Bool {
        callOrder.append("url:\(url.absoluteString)")
        if urlResults.isEmpty { return false }
        return urlResults.removeFirst()
    }

    func openFile(atPath path: String) -> Bool {
        callOrder.append("file:\(path)")
        if fileResults.isEmpty { return false }
        return fileResults.removeFirst()
    }

    func openApplication(atPath path: String) -> Bool {
        callOrder.append("app:\(path)")
        if appResults.isEmpty { return false }
        return appResults.removeFirst()
    }
}
