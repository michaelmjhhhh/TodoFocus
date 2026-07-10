import SwiftUI

struct KanbanCardView: View {
    @Bindable var store: KanbanStore
    let card: KanbanCard
    @Environment(\.themeTokens) private var tokens
    @State private var isTargeted = false

    var body: some View {
        Button { store.selectedCardID = card.id } label: {
            VStack(alignment: .leading, spacing: 8) {
                Text(card.title).font(TypographyTokens.bodyLarge).foregroundStyle(tokens.textPrimary)
                HStack {
                    Text(card.priority.title).font(TypographyTokens.micro).foregroundStyle(priorityColor)
                    if let due = card.dueDate { Text(due.formatted(date: .abbreviated, time: .omitted)).font(TypographyTokens.micro) }
                    Spacer()
                    if let progress = Self.checklistProgress(card) { Label(progress, systemImage: "checklist").font(TypographyTokens.micro) }
                }
                if !card.labels.isEmpty {
                    HStack { ForEach(card.labels.prefix(3)) { Text($0.name).font(TypographyTokens.micro).padding(.horizontal, 6).padding(.vertical, 2).background(tokens.bgSubtle, in: Capsule()) } }
                }
            }
            .padding(12).frame(maxWidth: .infinity, alignment: .leading)
            .background(tokens.bgFloating, in: RoundedRectangle(cornerRadius: 9))
            .overlay { RoundedRectangle(cornerRadius: 9).stroke(isTargeted ? tokens.accentTerracotta : tokens.sectionBorder.opacity(0.35)) }
        }
        .buttonStyle(.plain)
        .draggable(KanbanCardDragPayload(cardID: card.id))
        .dropDestination(for: KanbanCardDragPayload.self) { values, _ in
            guard let value = values.first else { return false }
            store.moveCard(id: value.cardID, to: card.status, destinationIndex: card.sortOrder)
            return true
        } isTargeted: { isTargeted = $0 }
        .contextMenu {
            Menu("Move to") { ForEach(KanbanStatus.allCases) { status in Button(status.title) { store.moveCard(id: card.id, to: status, destinationIndex: store.columns.first(where: { $0.status == status })?.cards.count ?? 0) } } }
            Button("Archive") { store.archiveCard(id: card.id) }
            Button("Delete", role: .destructive) { store.deleteCard(id: card.id) }
        }
        .accessibilityLabel(Self.accessibilitySummary(card))
    }

    private var priorityColor: Color {
        switch card.priority { case .low: return tokens.textTertiary; case .medium: return tokens.textSecondary; case .high: return .orange; case .urgent: return tokens.danger }
    }
    static func checklistProgress(_ card: KanbanCard) -> String? {
        guard !card.checklist.isEmpty else { return nil }
        return "\(card.checklist.filter(\.isCompleted).count)/\(card.checklist.count)"
    }

    static func accessibilitySummary(_ card: KanbanCard) -> String {
        var parts = [card.title, card.status.title, "\(card.priority.title) priority"]
        if !card.checklist.isEmpty {
            parts.append("\(card.checklist.filter(\.isCompleted).count) of \(card.checklist.count) checklist items complete")
        }
        return parts.joined(separator: ", ")
    }
}
