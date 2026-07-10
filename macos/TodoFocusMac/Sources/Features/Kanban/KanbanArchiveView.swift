import SwiftUI

struct KanbanArchiveView: View {
    @Bindable var store: KanbanStore
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack { Text("Archived Cards").font(TypographyTokens.displaySmall); Spacer(); Button("Done") { dismiss() } }
            if store.archivedCards.isEmpty { ContentUnavailableView("No Archived Cards", systemImage: "archivebox") }
            else {
                SwiftUI.List {
                    ForEach(store.archivedCards, id: \KanbanCard.id) { (card: KanbanCard) in
                        HStack { VStack(alignment: .leading) { Text(card.title); Text(card.status.title).font(.caption).foregroundStyle(.secondary) }; Spacer(); Button("Restore") { store.restoreCard(id: card.id) }; Button("Delete", role: .destructive) { store.permanentlyDeleteArchivedCard(id: card.id) } }
                    }
                }
            }
        }.padding(24).frame(minWidth: 560, minHeight: 420)
    }
}
