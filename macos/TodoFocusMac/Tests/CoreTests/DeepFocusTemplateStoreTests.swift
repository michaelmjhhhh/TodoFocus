import Foundation
import XCTest
@testable import TodoFocusMac

final class DeepFocusTemplateStoreTests: XCTestCase {
    private func makeDefaults() -> UserDefaults {
        let suiteName = "DeepFocusTemplateStoreTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    func testCreateTemplatePersistsAndReloads() {
        let defaults = makeDefaults()
        let key = "templates-test"
        let store = DeepFocusTemplateStore(defaults: defaults, key: key)

        let created = store.createTemplate(
            name: " Work Sprint ",
            durationMinutes: 45,
            blockedApps: ["com.apple.Safari", "com.apple.Safari", "com.tinyspeck.slackmacgap"]
        )
        XCTAssertEqual(created.name, "Work Sprint")
        XCTAssertEqual(created.durationMinutes, 45)
        XCTAssertEqual(created.blockedApps, ["com.apple.Safari", "com.tinyspeck.slackmacgap"])

        let reloaded = DeepFocusTemplateStore(defaults: defaults, key: key)
        XCTAssertEqual(reloaded.templates.count, 1)
        XCTAssertEqual(reloaded.templates[0].name, "Work Sprint")
        XCTAssertEqual(reloaded.templates[0].durationMinutes, 45)
    }

    func testRenameAndDeleteTemplate() {
        let defaults = makeDefaults()
        let key = "templates-test"
        let store = DeepFocusTemplateStore(defaults: defaults, key: key)
        let created = store.createTemplate(name: "Morning", durationMinutes: 25, blockedApps: [])

        store.renameTemplate(id: created.id, name: "Morning Deep Focus")
        XCTAssertEqual(store.templates.first?.name, "Morning Deep Focus")

        store.deleteTemplate(id: created.id)
        XCTAssertTrue(store.templates.isEmpty)
    }
}
