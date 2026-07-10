import Foundation
import GRDB

extension KanbanRepository {
    func fetchCards(projectID: String, includeArchived: Bool) throws -> KanbanCardFetchResult {
        try dbQueue.read { db in
            let sql = "SELECT * FROM kanban_card WHERE projectId = ?" + (includeArchived ? "" : " AND isArchived = 0") + " ORDER BY status, sortOrder"
            let records = try KanbanCardRecord.fetchAll(db, sql: sql, arguments: [projectID])
            return try aggregate(records, db: db)
        }
    }

    func fetchCard(id: String) throws -> (card: KanbanCard, dataRepairRequired: Bool)? {
        try dbQueue.read { db in
            guard let record = try KanbanCardRecord.fetchOne(db, key: id) else { return nil }
            let result = try aggregate([record], db: db)
            guard let card = result.cards.first else { return nil }
            return (card, result.dataRepairRequired)
        }
    }

    func createCard(_ input: CreateKanbanCardInput, now: Date = Date()) throws -> KanbanCard {
        let title = try KanbanValidation.cardTitle(input.title)
        let record = try dbQueue.write { db -> KanbanCardRecord in
            guard try KanbanProjectRecord.fetchOne(db, key: input.projectID) != nil else { throw KanbanRepositoryError.notFound }
            let next = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM kanban_card WHERE projectId = ? AND status = ? AND isArchived = 0", arguments: [input.projectID, input.status.rawValue]) ?? 0
            let row = KanbanCardRecord(id: UUID().uuidString, projectId: input.projectID, title: title, description: "", status: input.status.rawValue, priority: KanbanPriority.medium.rawValue, dueDate: nil, sortOrder: next, isArchived: false, createdAt: now, updatedAt: now)
            try row.insert(db); return row
        }
        return record.card(labels: [], checklist: []).card
    }

    func updateCard(id: String, input: UpdateKanbanCardInput, now: Date = Date()) throws {
        try dbQueue.write { db in
            guard var row = try KanbanCardRecord.fetchOne(db, key: id) else { throw KanbanRepositoryError.notFound }
            if let title = input.title { row.title = try KanbanValidation.cardTitle(title) }
            if let description = input.description { row.description = try KanbanValidation.cardDescription(description) }
            if let priority = input.priority { row.priority = priority.rawValue }
            if let dueDate = input.dueDate { row.dueDate = dueDate }
            row.updatedAt = now; try row.update(db)
        }
    }

    func moveCard(id: String, to status: KanbanStatus, destinationIndex: Int, now: Date = Date()) throws {
        try dbQueue.write { db in
            guard var row = try KanbanCardRecord.fetchOne(db, key: id), !row.isArchived else { throw KanbanRepositoryError.notFound }
            let sourceStatus = row.status
            let source = try String.fetchAll(db, sql: "SELECT id FROM kanban_card WHERE projectId = ? AND status = ? AND isArchived = 0 ORDER BY sortOrder", arguments: [row.projectId, sourceStatus])
            let destination = sourceStatus == status.rawValue ? source : try String.fetchAll(db, sql: "SELECT id FROM kanban_card WHERE projectId = ? AND status = ? AND isArchived = 0 ORDER BY sortOrder", arguments: [row.projectId, status.rawValue])
            let moved = KanbanOrdering.move(cardID: id, from: source, to: destination, destinationIndex: destinationIndex)
            row.status = status.rawValue; row.updatedAt = now; try row.update(db)
            try renumber(moved.source, db: db)
            if sourceStatus != status.rawValue { try renumber(moved.destination, db: db) }
        }
    }

    func archiveCard(id: String, now: Date = Date()) throws { try setArchived(id: id, archived: true, now: now) }
    func restoreCard(id: String, now: Date = Date()) throws { try setArchived(id: id, archived: false, now: now) }

    func deleteCard(id: String) throws {
        try dbQueue.write { db in
            guard let row = try KanbanCardRecord.fetchOne(db, key: id) else { throw KanbanRepositoryError.notFound }
            _ = try KanbanCardRecord.deleteOne(db, key: id)
            let ids = try String.fetchAll(db, sql: "SELECT id FROM kanban_card WHERE projectId = ? AND status = ? AND isArchived = 0 ORDER BY sortOrder", arguments: [row.projectId, row.status])
            try renumber(ids, db: db)
        }
    }

    private func setArchived(id: String, archived: Bool, now: Date) throws {
        try dbQueue.write { db in
            guard var row = try KanbanCardRecord.fetchOne(db, key: id) else { throw KanbanRepositoryError.notFound }
            row.isArchived = archived; row.updatedAt = now
            if !archived {
                row.sortOrder = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM kanban_card WHERE projectId = ? AND status = ? AND isArchived = 0", arguments: [row.projectId, row.status]) ?? 0
            }
            try row.update(db)
            let ids = try String.fetchAll(db, sql: "SELECT id FROM kanban_card WHERE projectId = ? AND status = ? AND isArchived = 0 ORDER BY sortOrder", arguments: [row.projectId, row.status])
            try renumber(ids, db: db)
        }
    }

    private func aggregate(_ records: [KanbanCardRecord], db: Database) throws -> KanbanCardFetchResult {
        let ids = records.map(\.id)
        guard !ids.isEmpty else { return .init(cards: [], dataRepairRequired: false) }
        let labels = try KanbanCardLabelRecord.filter(ids.contains(Column("cardId"))).fetchAll(db)
        let items = try KanbanChecklistItemRecord.filter(ids.contains(Column("cardId"))).fetchAll(db)
        var repaired = false
        let cards = records.map { row in
            let mapped = row.card(labels: labels.filter { $0.cardId == row.id }, checklist: items.filter { $0.cardId == row.id })
            repaired = repaired || mapped.usedFallback; return mapped.card
        }
        return .init(cards: cards, dataRepairRequired: repaired)
    }

    private func renumber(_ ids: [String], db: Database) throws {
        for (index, id) in ids.enumerated() { try db.execute(sql: "UPDATE kanban_card SET sortOrder = ? WHERE id = ?", arguments: [index, id]) }
    }
}
