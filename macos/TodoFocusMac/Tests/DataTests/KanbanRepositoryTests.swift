import XCTest
@testable import TodoFocusMac

final class KanbanRepositoryTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)
    private func makeRepository() throws -> KanbanRepository { KanbanRepository(dbQueue: try DatabaseManager(databasePath: ":memory:").dbQueue) }
    private func makeProject(_ repo: KanbanRepository) throws -> KanbanProject { try repo.createProject(.init(name: "App", color: "#C46849", goal: "Ship"), now: now) }

    func testProjectCRUDSortsAlphabeticallyAndValidates() throws {
        let repo = try makeRepository()
        let zeta = try repo.createProject(.init(name: "Zeta", color: "#C46849", goal: "Ship Zeta"), now: now)
        let alpha = try repo.createProject(.init(name: " Alpha ", color: "#336699", goal: " Build Alpha "), now: now)
        XCTAssertEqual(try repo.fetchProjects().map(\.id), [alpha.id, zeta.id])
        XCTAssertEqual(alpha.name, "Alpha")
        try repo.updateProject(id: alpha.id, input: .init(name: "Beta", color: "#ABCDEF", goal: "Beta goal"), now: now)
        XCTAssertEqual(try repo.fetchProject(id: alpha.id)?.name, "Beta")
        try repo.deleteProject(id: zeta.id)
        XCTAssertNil(try repo.fetchProject(id: zeta.id))
    }

    func testCreateMoveArchiveRestoreAndDeleteCard() throws {
        let repo = try makeRepository(); let project = try makeProject(repo)
        let a = try repo.createCard(.init(projectID: project.id, title: "A", status: .backlog), now: now)
        let b = try repo.createCard(.init(projectID: project.id, title: "B", status: .backlog), now: now)
        try repo.moveCard(id: b.id, to: .ready, destinationIndex: 0, now: now)
        XCTAssertEqual(try repo.fetchCard(id: b.id)?.card.status, .ready)
        XCTAssertEqual(try repo.fetchCards(projectID: project.id, includeArchived: false).cards.filter { $0.status == .backlog }.map(\.sortOrder), [0])
        try repo.archiveCard(id: b.id, now: now)
        XCTAssertFalse(try repo.fetchCards(projectID: project.id, includeArchived: false).cards.contains { $0.id == b.id })
        try repo.restoreCard(id: b.id, now: now)
        XCTAssertEqual(try repo.fetchCard(id: b.id)?.card.status, .ready)
        try repo.deleteCard(id: a.id)
        XCTAssertNil(try repo.fetchCard(id: a.id))
    }

    func testLabelsAndChecklistPersist() throws {
        let repo = try makeRepository(); let project = try makeProject(repo)
        let card = try repo.createCard(.init(projectID: project.id, title: "Card", status: .backlog), now: now)
        let label = try repo.addLabel(cardID: card.id, name: " UI ")
        XCTAssertEqual(label.name, "UI")
        let item = try repo.addChecklistItem(cardID: card.id, title: " Test it ")
        try repo.setChecklistItemCompleted(id: item.id, isCompleted: true)
        XCTAssertEqual(try repo.fetchCard(id: card.id)?.card.checklist.first?.isCompleted, true)
    }
}
