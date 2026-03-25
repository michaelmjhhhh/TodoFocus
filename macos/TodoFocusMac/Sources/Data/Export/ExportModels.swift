import Foundation

struct ExportData: Codable {
    let version: String
    let exportedAt: Date
    let lists: [ExportList]
    let todos: [ExportTodo]
}

struct ExportList: Codable {
    let id: String
    let name: String
    let color: String
    let sortOrder: Int
}

struct ExportTodo: Codable {
    let id: String
    let title: String
    let isCompleted: Bool
    let isImportant: Bool
    let isMyDay: Bool
    let dueDate: Date?
    let notes: String
    let listId: String?
    let focusTimeSeconds: Int?
    let steps: [ExportStep]
    let launchResources: [ExportLaunchResource]
}

struct ExportStep: Codable {
    let id: String
    let title: String
    let isCompleted: Bool
    let sortOrder: Int
}

struct ExportLaunchResource: Codable {
    let type: String
    let value: String
    let label: String
}

extension ExportData {
    static func decode(from data: Data) throws -> ExportData {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(ExportData.self, from: data)
    }

    func encode() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(self)
    }
}
