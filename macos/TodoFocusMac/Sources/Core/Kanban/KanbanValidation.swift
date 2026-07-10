import Foundation

enum KanbanValidationError: Error, Equatable {
    case empty(field: String)
    case tooLong(field: String, maximum: Int)
    case invalidColor
    case tooManyLabels
    case tooManyChecklistItems
}

enum KanbanValidation {
    static let projectNameLimit = 100
    static let projectGoalLimit = 500
    static let cardTitleLimit = 200
    static let cardDescriptionLimit = 10_000
    static let labelNameLimit = 40
    static let labelLimit = 10
    static let checklistTitleLimit = 200
    static let checklistLimit = 50

    static func projectName(_ value: String) throws -> String {
        try requiredTrimmed(value, field: "Project name", maximum: projectNameLimit)
    }

    static func projectGoal(_ value: String) throws -> String {
        try requiredTrimmed(value, field: "Project goal", maximum: projectGoalLimit)
    }

    static func cardTitle(_ value: String) throws -> String {
        try requiredTrimmed(value, field: "Card title", maximum: cardTitleLimit)
    }

    static func cardDescription(_ value: String) throws -> String {
        try bounded(value, field: "Card description", maximum: cardDescriptionLimit)
    }

    static func labelName(_ value: String) throws -> String {
        try requiredTrimmed(value, field: "Label name", maximum: labelNameLimit)
    }

    static func checklistTitle(_ value: String) throws -> String {
        try requiredTrimmed(value, field: "Checklist title", maximum: checklistTitleLimit)
    }

    static func color(_ value: String) throws -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.range(of: #"^#[0-9A-Fa-f]{6}$"#, options: .regularExpression) != nil else {
            throw KanbanValidationError.invalidColor
        }
        return trimmed.uppercased()
    }

    static func labelCount(_ count: Int) throws {
        guard count <= labelLimit else {
            throw KanbanValidationError.tooManyLabels
        }
    }

    static func checklistCount(_ count: Int) throws {
        guard count <= checklistLimit else {
            throw KanbanValidationError.tooManyChecklistItems
        }
    }

    private static func requiredTrimmed(_ value: String, field: String, maximum: Int) throws -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw KanbanValidationError.empty(field: field)
        }
        guard trimmed.count <= maximum else {
            throw KanbanValidationError.tooLong(field: field, maximum: maximum)
        }
        return trimmed
    }

    private static func bounded(_ value: String, field: String, maximum: Int) throws -> String {
        guard value.count <= maximum else {
            throw KanbanValidationError.tooLong(field: field, maximum: maximum)
        }
        return value
    }
}
