import Foundation
import GRDB

extension KanbanRepository {
    func addLabel(cardID: String, name: String) throws -> KanbanCardLabel {
        let value = try KanbanValidation.labelName(name)
        return try dbQueue.write { db in
            guard try KanbanCardRecord.fetchOne(db, key: cardID) != nil else { throw KanbanRepositoryError.notFound }
            let count = try KanbanCardLabelRecord.filter(Column("cardId") == cardID).fetchCount(db)
            guard count < KanbanValidation.labelLimit else { throw KanbanRepositoryError.labelLimit }
            let row = KanbanCardLabelRecord(id: UUID().uuidString, cardId: cardID, name: value, sortOrder: count)
            try row.insert(db); return row.label
        }
    }

    func updateLabel(id: String, name: String) throws {
        let value = try KanbanValidation.labelName(name)
        try dbQueue.write { db in guard var row = try KanbanCardLabelRecord.fetchOne(db, key: id) else { throw KanbanRepositoryError.notFound }; row.name = value; try row.update(db) }
    }
    func deleteLabel(id: String) throws { try dbQueue.write { db in guard try KanbanCardLabelRecord.deleteOne(db, key: id) else { throw KanbanRepositoryError.notFound } } }

    func addChecklistItem(cardID: String, title: String) throws -> KanbanChecklistItem {
        let value = try KanbanValidation.checklistTitle(title)
        return try dbQueue.write { db in
            guard try KanbanCardRecord.fetchOne(db, key: cardID) != nil else { throw KanbanRepositoryError.notFound }
            let count = try KanbanChecklistItemRecord.filter(Column("cardId") == cardID).fetchCount(db)
            guard count < KanbanValidation.checklistLimit else { throw KanbanRepositoryError.checklistLimit }
            let row = KanbanChecklistItemRecord(id: UUID().uuidString, cardId: cardID, title: value, isCompleted: false, sortOrder: count)
            try row.insert(db); return row.item
        }
    }
    func updateChecklistItem(id: String, title: String) throws {
        let value = try KanbanValidation.checklistTitle(title)
        try dbQueue.write { db in guard var row = try KanbanChecklistItemRecord.fetchOne(db, key: id) else { throw KanbanRepositoryError.notFound }; row.title = value; try row.update(db) }
    }
    func setChecklistItemCompleted(id: String, isCompleted: Bool) throws {
        try dbQueue.write { db in guard var row = try KanbanChecklistItemRecord.fetchOne(db, key: id) else { throw KanbanRepositoryError.notFound }; row.isCompleted = isCompleted; try row.update(db) }
    }
    func moveChecklistItem(id: String, destinationIndex: Int) throws {
        try dbQueue.write { db in
            guard let row = try KanbanChecklistItemRecord.fetchOne(db, key: id) else { throw KanbanRepositoryError.notFound }
            let ids = try String.fetchAll(db, sql: "SELECT id FROM kanban_checklist_item WHERE cardId = ? ORDER BY sortOrder", arguments: [row.cardId])
            let moved = KanbanOrdering.move(cardID: id, from: ids, to: ids, destinationIndex: destinationIndex).destination
            for (index, itemID) in moved.enumerated() { try db.execute(sql: "UPDATE kanban_checklist_item SET sortOrder = ? WHERE id = ?", arguments: [index, itemID]) }
        }
    }
    func deleteChecklistItem(id: String) throws {
        try dbQueue.write { db in
            guard let row = try KanbanChecklistItemRecord.fetchOne(db, key: id) else { throw KanbanRepositoryError.notFound }
            _ = try KanbanChecklistItemRecord.deleteOne(db, key: id)
            let ids = try String.fetchAll(db, sql: "SELECT id FROM kanban_checklist_item WHERE cardId = ? ORDER BY sortOrder", arguments: [row.cardId])
            for (index, itemID) in ids.enumerated() { try db.execute(sql: "UPDATE kanban_checklist_item SET sortOrder = ? WHERE id = ?", arguments: [index, itemID]) }
        }
    }
}
