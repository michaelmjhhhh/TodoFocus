import Foundation
import Observation

@Observable
@MainActor
final class KanbanStore {
    private let repository: any KanbanRepositoryProtocol
    private let now: () -> Date
    @ObservationIgnored private var descriptionTask: Task<Void, Never>?
    @ObservationIgnored private var goalTask: Task<Void, Never>?

    var projects: [KanbanProject] = []
    var cards: [KanbanCard] = []
    var archivedCards: [KanbanCard] = []
    var selectedProjectID: String?
    var selectedCardID: String?
    var errorMessage: String?
    var showsDataRepairWarning = false
    var canRetryLastLoad = false

    init(repository: any KanbanRepositoryProtocol, now: @escaping () -> Date = Date.init) {
        self.repository = repository; self.now = now
    }

    var selectedProject: KanbanProject? { projects.first { $0.id == selectedProjectID } }
    var selectedCard: KanbanCard? { cards.first { $0.id == selectedCardID } }
    var columns: [KanbanColumn] {
        KanbanStatus.allCases.map { status in
            KanbanColumn(status: status, cards: cards.filter { !$0.isArchived && $0.status == status }.sorted { $0.sortOrder < $1.sortOrder })
        }
    }

    func load() throws {
        projects = try repository.fetchProjects()
        if !projects.contains(where: { $0.id == selectedProjectID }) { selectedProjectID = projects.first?.id }
        try reloadCards()
        errorMessage = nil; canRetryLastLoad = false
    }
    func loadForDisplay() { do { try load() } catch { show(error, retryable: true) } }
    func retryLastLoad() { loadForDisplay() }

    func selectProject(id: String) {
        guard projects.contains(where: { $0.id == id }) else { return }
        selectedProjectID = id; selectedCardID = nil
        do { try reloadCards() } catch { show(error, retryable: true) }
    }

    func createProject(name: String, color: String, goal: String) {
        mutate { selectedProjectID = try repository.createProject(.init(name: name, color: color, goal: goal), now: now()).id; try reloadAll() }
    }
    func updateSelectedProject(name: String, color: String, goal: String) {
        guard let id = selectedProjectID else { return }
        mutate { try repository.updateProject(id: id, input: .init(name: name, color: color, goal: goal), now: now()); try reloadAll() }
    }
    func updateSelectedProjectGoalDebounced(_ goal: String) {
        guard let project = selectedProject else { return }
        goalTask?.cancel(); let id = project.id; let name = project.name; let color = project.color
        goalTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(300)); guard !Task.isCancelled, let self else { return }
            mutate { try repository.updateProject(id: id, input: .init(name: name, color: color, goal: goal), now: now()); try reloadAll() }
        }
    }
    func deleteSelectedProject() {
        guard let id = selectedProjectID else { return }
        mutate { try repository.deleteProject(id: id); selectedProjectID = nil; selectedCardID = nil; try reloadAll() }
    }

    func createCard(title: String, in status: KanbanStatus) {
        guard let projectID = selectedProjectID else { return }
        mutate { _ = try repository.createCard(.init(projectID: projectID, title: title, status: status), now: now()); try reloadCards() }
    }
    func updateSelectedCardTitle(_ title: String) { updateSelectedCard(.init(title: title)) }
    func updateSelectedCardDescriptionDebounced(_ value: String) {
        guard let id = selectedCardID else { return }; descriptionTask?.cancel()
        descriptionTask = Task { [weak self] in try? await Task.sleep(for: .milliseconds(300)); guard !Task.isCancelled, let self else { return }; updateCard(id: id, .init(description: value)) }
    }
    func setSelectedCardPriority(_ value: KanbanPriority) { updateSelectedCard(.init(priority: value)) }
    func setSelectedCardDueDate(_ value: Date?) { var input = UpdateKanbanCardInput(); input.dueDate = .some(value); updateSelectedCard(input) }
    func moveCard(id: String, to status: KanbanStatus, destinationIndex: Int) { mutate { try repository.moveCard(id: id, to: status, destinationIndex: destinationIndex, now: now()); try reloadCards() } }
    func archiveSelectedCard() { guard let id = selectedCardID else { return }; mutate { try repository.archiveCard(id: id, now: now()); selectedCardID = nil; try reloadCards() } }
    func restoreCard(id: String) { mutate { try repository.restoreCard(id: id, now: now()); try reloadCards(); try loadArchivedCardsThrowing() } }
    func deleteSelectedCard() { guard let id = selectedCardID else { return }; mutate { try repository.deleteCard(id: id); selectedCardID = nil; try reloadCards() } }
    func permanentlyDeleteArchivedCard(id: String) { mutate { try repository.deleteCard(id: id); try loadArchivedCardsThrowing() } }
    func loadArchivedCards() { do { try loadArchivedCardsThrowing() } catch { show(error, retryable: true) } }

    func addLabel(_ name: String) { withCard { _ = try repository.addLabel(cardID: $0, name: name) } }
    func updateLabel(id: String, name: String) { mutateAndRefreshCard { try repository.updateLabel(id: id, name: name) } }
    func deleteLabel(id: String) { mutateAndRefreshCard { try repository.deleteLabel(id: id) } }
    func addChecklistItem(_ title: String) { withCard { _ = try repository.addChecklistItem(cardID: $0, title: title) } }
    func updateChecklistItem(id: String, title: String) { mutateAndRefreshCard { try repository.updateChecklistItem(id: id, title: title) } }
    func toggleChecklistItem(id: String, isCompleted: Bool) { mutateAndRefreshCard { try repository.setChecklistItemCompleted(id: id, isCompleted: isCompleted) } }
    func moveChecklistItem(id: String, destinationIndex: Int) { mutateAndRefreshCard { try repository.moveChecklistItem(id: id, destinationIndex: destinationIndex) } }
    func deleteChecklistItem(id: String) { mutateAndRefreshCard { try repository.deleteChecklistItem(id: id) } }
    func clearError() { errorMessage = nil; canRetryLastLoad = false }

    private func updateSelectedCard(_ input: UpdateKanbanCardInput) { guard let id = selectedCardID else { return }; updateCard(id: id, input) }
    private func updateCard(id: String, _ input: UpdateKanbanCardInput) { mutate { try repository.updateCard(id: id, input: input, now: now()); try reloadCards() } }
    private func withCard(_ action: (String) throws -> Void) { guard let id = selectedCardID else { return }; mutateAndRefreshCard { try action(id) } }
    private func mutateAndRefreshCard(_ action: () throws -> Void) { mutate { try action(); try reloadCards() } }
    private func mutate(_ action: () throws -> Void) { do { try action(); errorMessage = nil } catch { show(error, retryable: false) } }
    private func show(_ error: Error, retryable: Bool) { errorMessage = error.localizedDescription; canRetryLastLoad = retryable }
    private func reloadAll() throws { projects = try repository.fetchProjects(); if !projects.contains(where: { $0.id == selectedProjectID }) { selectedProjectID = projects.first?.id }; try reloadCards() }
    private func reloadCards() throws {
        guard let id = selectedProjectID else { cards = []; return }
        let result = try repository.fetchCards(projectID: id, includeArchived: false); cards = result.cards; showsDataRepairWarning = showsDataRepairWarning || result.dataRepairRequired
        if !cards.contains(where: { $0.id == selectedCardID }) { selectedCardID = nil }
    }
    private func loadArchivedCardsThrowing() throws {
        guard let id = selectedProjectID else { archivedCards = []; return }
        let result = try repository.fetchCards(projectID: id, includeArchived: true); archivedCards = result.cards.filter(\.isArchived); showsDataRepairWarning = showsDataRepairWarning || result.dataRepairRequired
    }
}

private extension UpdateKanbanCardInput {
    init(title: String? = nil, description: String? = nil, priority: KanbanPriority? = nil) {
        self.init(); self.title = title; self.description = description; self.priority = priority
    }
}
