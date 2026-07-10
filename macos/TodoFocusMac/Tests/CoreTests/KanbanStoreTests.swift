import XCTest
@testable import TodoFocusMac

@MainActor
final class KanbanStoreTests: XCTestCase {
    private func makeStore() throws -> (KanbanStore, KanbanRepository) {
        let manager = try DatabaseManager(databasePath: ":memory:")
        let repository = KanbanRepository(dbQueue: manager.dbQueue)
        return (KanbanStore(repository: repository, now: { Date(timeIntervalSince1970: 1_700_000_000) }), repository)
    }

    func testLoadSelectsFirstProjectAlphabetically() throws {
        let (store, repository) = try makeStore()
        _ = try repository.createProject(.init(name: "Zeta", color: "#C46849", goal: "Z"), now: Date())
        _ = try repository.createProject(.init(name: "Alpha", color: "#336699", goal: "A"), now: Date())
        try store.load()
        XCTAssertEqual(store.projects.map(\.name), ["Alpha", "Zeta"])
        XCTAssertEqual(store.selectedProject?.name, "Alpha")
    }

    func testCreateMoveAndDeleteSelectedCardPublishesConfirmedState() throws {
        let (store, _) = try makeStore()
        store.createProject(name: "App", color: "#C46849", goal: "Ship")
        store.createCard(title: "Build", in: .backlog)
        let id = try XCTUnwrap(store.cards.first?.id)
        store.selectedCardID = id
        store.moveCard(id: id, to: .ready, destinationIndex: 0)
        XCTAssertEqual(store.cards.first?.status, .ready)
        store.deleteSelectedCard()
        XCTAssertTrue(store.cards.isEmpty)
        XCTAssertNil(store.selectedCardID)
    }

    func testArchiveRestoreAndPermanentDeleteRefreshesBothCollections() throws {
        let (store, _) = try makeStore()
        store.createProject(name: "App", color: "#C46849", goal: "Ship")
        store.createCard(title: "Build", in: .done)
        let id = try XCTUnwrap(store.cards.first?.id)

        store.archiveCard(id: id)
        store.loadArchivedCards()
        XCTAssertTrue(store.cards.isEmpty)
        XCTAssertEqual(store.archivedCards.map(\.id), [id])

        store.restoreCard(id: id)
        XCTAssertEqual(store.cards.map(\.id), [id])
        XCTAssertTrue(store.archivedCards.isEmpty)

        store.archiveCard(id: id)
        store.loadArchivedCards()
        store.permanentlyDeleteArchivedCard(id: id)
        XCTAssertTrue(store.archivedCards.isEmpty)
    }

    func testColumnsAlwaysUseFixedWorkflowOrder() throws {
        let (store, _) = try makeStore()
        XCTAssertEqual(store.columns.map(\.status), [.backlog, .ready, .inProgress, .blocked, .done])
    }

    func testDeletingSelectedProjectFallsBackAlphabetically() throws {
        let (store, _) = try makeStore()
        store.createProject(name: "Beta", color: "#C46849", goal: "B")
        store.createProject(name: "Alpha", color: "#336699", goal: "A")
        store.selectProject(id: store.projects.first { $0.name == "Beta" }!.id)
        store.deleteSelectedProject()
        XCTAssertEqual(store.selectedProject?.name, "Alpha")
    }
}
