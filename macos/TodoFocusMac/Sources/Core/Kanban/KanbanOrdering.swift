import Foundation

enum KanbanOrdering {
    struct Result: Equatable {
        let source: [String]
        let destination: [String]
    }

    static func move(cardID: String, from source: [String], to destination: [String], destinationIndex: Int) -> Result {
        let sourceWithoutCard = source.filter { $0 != cardID }
        let destinationWithoutCard = destination == source ? sourceWithoutCard : destination.filter { $0 != cardID }
        let clampedIndex = max(0, min(destinationIndex, destinationWithoutCard.count))
        let updatedDestination = insert(cardID, into: destinationWithoutCard, at: clampedIndex)

        if destination == source {
            return .init(source: updatedDestination, destination: updatedDestination)
        }

        return .init(source: sourceWithoutCard, destination: updatedDestination)
    }

    private static func insert(_ cardID: String, into cards: [String], at index: Int) -> [String] {
        var updated = cards
        updated.insert(cardID, at: index)
        return updated
    }
}
