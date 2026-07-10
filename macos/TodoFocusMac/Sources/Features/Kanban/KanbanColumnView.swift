import SwiftUI

struct KanbanColumnView: View {
    @Bindable var store: KanbanStore
    let column: KanbanColumn
    @Environment(\.themeTokens) private var tokens
    @State private var newTitle = ""
    @State private var isTargeted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack { Text(column.status.title).font(TypographyTokens.headingSmall); Spacer(); Text("\(column.cards.count)").font(TypographyTokens.micro).foregroundStyle(tokens.textTertiary) }
            HStack { TextField("Add card", text: $newTitle).textFieldStyle(.plain).onSubmit(add); Button(action: add) { Image(systemName: "plus") }.disabled(newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
                .padding(8).background(tokens.bgFloating, in: RoundedRectangle(cornerRadius: 8))
            if column.cards.isEmpty { Text("No cards").font(TypographyTokens.caption).foregroundStyle(tokens.textTertiary).frame(maxWidth: .infinity, minHeight: 64) }
            ForEach(column.cards) { card in KanbanCardView(store: store, card: card) }
            Color.clear.frame(height: 32).contentShape(Rectangle()).dropDestination(for: KanbanCardDragPayload.self) { values, _ in guard let value = values.first else { return false }; store.moveCard(id: value.cardID, to: column.status, destinationIndex: column.cards.count); return true } isTargeted: { isTargeted = $0 }
        }
        .padding(14).frame(width: 290, alignment: .topLeading)
        .background(tokens.bgSubtle.opacity(0.7), in: RoundedRectangle(cornerRadius: 12))
        .overlay { RoundedRectangle(cornerRadius: 12).stroke(isTargeted ? tokens.accentTerracotta : tokens.sectionBorder.opacity(0.4), lineWidth: isTargeted ? 2 : 1) }
        .accessibilityElement(children: .contain).accessibilityLabel("\(column.status.title), \(column.cards.count) cards")
    }
    private func add() { let title = newTitle.trimmingCharacters(in: .whitespacesAndNewlines); guard !title.isEmpty else { return }; store.createCard(title: title, in: column.status); newTitle = "" }
}
