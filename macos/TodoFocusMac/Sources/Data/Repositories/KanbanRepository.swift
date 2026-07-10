import Foundation
import GRDB

struct CreateKanbanProjectInput { let name: String; let color: String; let goal: String }
struct UpdateKanbanProjectInput { let name: String; let color: String; let goal: String }
struct CreateKanbanCardInput { let projectID: String; let title: String; let status: KanbanStatus }
struct UpdateKanbanCardInput {
    var title: String?
    var description: String?
    var priority: KanbanPriority?
    var dueDate: Date??
}
struct KanbanCardFetchResult { let cards: [KanbanCard]; let dataRepairRequired: Bool }

enum KanbanRepositoryError: Error, Equatable {
    case notFound, invalidProject, invalidCard, labelLimit, checklistLimit, invalidMove
}

protocol KanbanRepositoryProtocol {
    func fetchProjects() throws -> [KanbanProject]
    func fetchProject(id: String) throws -> KanbanProject?
    func createProject(_ input: CreateKanbanProjectInput, now: Date) throws -> KanbanProject
    func updateProject(id: String, input: UpdateKanbanProjectInput, now: Date) throws
    func deleteProject(id: String) throws
    func fetchCards(projectID: String, includeArchived: Bool) throws -> KanbanCardFetchResult
    func fetchCard(id: String) throws -> (card: KanbanCard, dataRepairRequired: Bool)?
    func createCard(_ input: CreateKanbanCardInput, now: Date) throws -> KanbanCard
    func updateCard(id: String, input: UpdateKanbanCardInput, now: Date) throws
    func moveCard(id: String, to status: KanbanStatus, destinationIndex: Int, now: Date) throws
    func archiveCard(id: String, now: Date) throws
    func restoreCard(id: String, now: Date) throws
    func deleteCard(id: String) throws
    func addLabel(cardID: String, name: String) throws -> KanbanCardLabel
    func updateLabel(id: String, name: String) throws
    func deleteLabel(id: String) throws
    func addChecklistItem(cardID: String, title: String) throws -> KanbanChecklistItem
    func updateChecklistItem(id: String, title: String) throws
    func setChecklistItemCompleted(id: String, isCompleted: Bool) throws
    func moveChecklistItem(id: String, destinationIndex: Int) throws
    func deleteChecklistItem(id: String) throws
}

struct KanbanRepository: KanbanRepositoryProtocol {
    let dbQueue: DatabaseQueue
    init(dbQueue: DatabaseQueue) { self.dbQueue = dbQueue }
}
