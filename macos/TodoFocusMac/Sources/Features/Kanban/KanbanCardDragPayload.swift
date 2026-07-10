import CoreTransferable
import UniformTypeIdentifiers

struct KanbanCardDragPayload: Codable, Transferable {
    let cardID: String
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .data)
    }
}
