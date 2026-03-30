import Foundation

enum ExportFormatVersion {
    static let v1_0 = "1.0"
    static let v1_1 = "1.1"
    static let v1_2 = "1.2"
    static let current = v1_2

    static func isSupported(_ version: String) -> Bool {
        version == v1_0 || version == v1_1 || version == v1_2
    }
}

struct ExportData: Codable {
    let version: String
    let exportedAt: Date
    let meta: ExportMeta?
    let lists: [ExportList]
    let todos: [ExportTodo]
}

struct ExportMeta: Codable {
    let appVersion: String?
    let platform: String?
    let importHints: [String]?
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
    let recurrence: String?
    let recurrenceInterval: Int
    let sortOrder: Int
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
