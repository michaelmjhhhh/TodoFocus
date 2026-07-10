import Foundation

struct KanbanPersisted<Value: Equatable>: Equatable {
    let value: Value
    let usedFallback: Bool
}

enum KanbanStatus: String, CaseIterable, Codable, Identifiable {
    case backlog
    case ready
    case inProgress
    case blocked
    case done

    var id: String { rawValue }

    var title: String {
        switch self {
        case .backlog:
            "Backlog"
        case .ready:
            "Ready"
        case .inProgress:
            "In Progress"
        case .blocked:
            "Blocked"
        case .done:
            "Done"
        }
    }

    static func persisted(_ raw: String) -> KanbanPersisted<KanbanStatus> {
        guard let value = Self(rawValue: raw) else {
            return .init(value: .backlog, usedFallback: true)
        }
        return .init(value: value, usedFallback: false)
    }
}

enum KanbanPriority: String, CaseIterable, Codable, Identifiable {
    case low
    case medium
    case high
    case urgent

    var id: String { rawValue }

    var title: String { rawValue.capitalized }

    static func persisted(_ raw: String) -> KanbanPersisted<KanbanPriority> {
        guard let value = Self(rawValue: raw) else {
            return .init(value: .medium, usedFallback: true)
        }
        return .init(value: value, usedFallback: false)
    }
}

struct KanbanProject: Identifiable, Equatable {
    let id: String
    var name: String
    var color: String
    var goal: String
    var createdAt: Date
    var updatedAt: Date
}

struct KanbanCardLabel: Identifiable, Equatable {
    let id: String
    let cardID: String
    var name: String
    var sortOrder: Int
}

struct KanbanChecklistItem: Identifiable, Equatable {
    let id: String
    let cardID: String
    var title: String
    var isCompleted: Bool
    var sortOrder: Int
}

struct KanbanCard: Identifiable, Equatable {
    let id: String
    let projectID: String
    var title: String
    var description: String
    var status: KanbanStatus
    var priority: KanbanPriority
    var dueDate: Date?
    var sortOrder: Int
    var isArchived: Bool
    var labels: [KanbanCardLabel]
    var checklist: [KanbanChecklistItem]
    var createdAt: Date
    var updatedAt: Date
}

struct KanbanColumn: Identifiable, Equatable {
    let status: KanbanStatus
    let cards: [KanbanCard]

    var id: KanbanStatus { status }
}
