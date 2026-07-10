import XCTest
@testable import TodoFocusMac

final class KanbanModelTests: XCTestCase {
    func testStatusesStayInProductOrder() {
        XCTAssertEqual(KanbanStatus.allCases, [.backlog, .ready, .inProgress, .blocked, .done])
        XCTAssertEqual(KanbanStatus.allCases.map(\.title), ["Backlog", "Ready", "In Progress", "Blocked", "Done"])
    }

    func testInvalidRawValuesUseSpecifiedFallbacks() {
        XCTAssertEqual(KanbanStatus.persisted("unknown").value, .backlog)
        XCTAssertTrue(KanbanStatus.persisted("unknown").usedFallback)
        XCTAssertEqual(KanbanPriority.persisted("unknown").value, .medium)
        XCTAssertTrue(KanbanPriority.persisted("unknown").usedFallback)
    }

    func testValidationTrimsAndEnforcesLimits() throws {
        XCTAssertEqual(try KanbanValidation.projectName("  Apollo  "), "Apollo")
        XCTAssertEqual(try KanbanValidation.projectGoal("  Ship v1  "), "Ship v1")
        XCTAssertThrowsError(try KanbanValidation.projectName(String(repeating: "a", count: 101)))
        XCTAssertThrowsError(try KanbanValidation.cardDescription(String(repeating: "a", count: 10_001)))
        XCTAssertThrowsError(try KanbanValidation.color("terracotta"))
        XCTAssertEqual(try KanbanValidation.color("#C46849"), "#C46849")
    }

    func testValidationConstantsMatchKanbanSpec() {
        XCTAssertEqual(KanbanValidation.projectNameLimit, 100)
        XCTAssertEqual(KanbanValidation.projectGoalLimit, 500)
        XCTAssertEqual(KanbanValidation.cardTitleLimit, 200)
        XCTAssertEqual(KanbanValidation.cardDescriptionLimit, 10_000)
        XCTAssertEqual(KanbanValidation.labelNameLimit, 40)
        XCTAssertEqual(KanbanValidation.labelLimit, 10)
        XCTAssertEqual(KanbanValidation.checklistTitleLimit, 200)
        XCTAssertEqual(KanbanValidation.checklistLimit, 50)
    }
}
