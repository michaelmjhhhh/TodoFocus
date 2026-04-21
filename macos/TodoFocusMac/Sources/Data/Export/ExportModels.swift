import Foundation

enum ExportFormatVersion {
    static let v1_0 = "1.0"
    static let v1_1 = "1.1"
    static let v1_2 = "1.2"
    static let v1_3 = "1.3"
    static let v1_4 = "1.4"
    static let current = v1_4

    static func isSupported(_ version: String) -> Bool {
        version == v1_0 || version == v1_1 || version == v1_2 || version == v1_3 || version == v1_4
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
    let isArchived: Bool
    let isImportant: Bool
    let isMyDay: Bool
    let dueDate: Date?
    let notes: String
    let listId: String?
    let focusTimeSeconds: Int?
    let recurrence: String?
    let recurrenceInterval: Int
    let sortOrder: Int
    let createdAt: Date?
    let updatedAt: Date?
    let lastCompletedAt: Date?
    let steps: [ExportStep]
    let launchResources: [ExportLaunchResource]
}

extension ExportTodo {
    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case isCompleted
        case isArchived
        case isImportant
        case isMyDay
        case dueDate
        case notes
        case listId
        case focusTimeSeconds
        case recurrence
        case recurrenceInterval
        case sortOrder
        case createdAt
        case updatedAt
        case lastCompletedAt
        case steps
        case launchResources
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        isArchived = try container.decodeIfPresent(Bool.self, forKey: .isArchived) ?? false
        isImportant = try container.decode(Bool.self, forKey: .isImportant)
        isMyDay = try container.decode(Bool.self, forKey: .isMyDay)
        dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate)
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        listId = try container.decodeIfPresent(String.self, forKey: .listId)
        focusTimeSeconds = try container.decodeIfPresent(Int.self, forKey: .focusTimeSeconds)
        recurrence = try container.decodeIfPresent(String.self, forKey: .recurrence)
        recurrenceInterval = max(1, try container.decodeIfPresent(Int.self, forKey: .recurrenceInterval) ?? 1)
        sortOrder = try container.decodeIfPresent(Int.self, forKey: .sortOrder) ?? 0
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
        lastCompletedAt = try container.decodeIfPresent(Date.self, forKey: .lastCompletedAt)
        steps = try container.decodeIfPresent([ExportStep].self, forKey: .steps) ?? []
        launchResources = try container.decodeIfPresent([ExportLaunchResource].self, forKey: .launchResources) ?? []
    }
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
