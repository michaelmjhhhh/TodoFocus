import Foundation
import GRDB

extension KanbanRepository {
    func fetchProjects() throws -> [KanbanProject] {
        try dbQueue.read { db in
            try KanbanProjectRecord.fetchAll(db, sql: "SELECT * FROM kanban_project ORDER BY name COLLATE NOCASE ASC").map(\.project)
        }
    }

    func fetchProject(id: String) throws -> KanbanProject? {
        try dbQueue.read { db in try KanbanProjectRecord.fetchOne(db, key: id)?.project }
    }

    func createProject(_ input: CreateKanbanProjectInput, now: Date = Date()) throws -> KanbanProject {
        let record = try KanbanProjectRecord(
            id: UUID().uuidString,
            name: KanbanValidation.projectName(input.name),
            color: KanbanValidation.color(input.color),
            goal: KanbanValidation.projectGoal(input.goal),
            createdAt: now,
            updatedAt: now
        )
        try dbQueue.write { db in try record.insert(db) }
        return record.project
    }

    func updateProject(id: String, input: UpdateKanbanProjectInput, now: Date = Date()) throws {
        let name = try KanbanValidation.projectName(input.name)
        let color = try KanbanValidation.color(input.color)
        let goal = try KanbanValidation.projectGoal(input.goal)
        try dbQueue.write { db in
            guard var record = try KanbanProjectRecord.fetchOne(db, key: id) else { throw KanbanRepositoryError.notFound }
            record.name = name; record.color = color; record.goal = goal; record.updatedAt = now
            try record.update(db)
        }
    }

    func deleteProject(id: String) throws {
        try dbQueue.write { db in
            guard try KanbanProjectRecord.deleteOne(db, key: id) else { throw KanbanRepositoryError.notFound }
        }
    }
}
