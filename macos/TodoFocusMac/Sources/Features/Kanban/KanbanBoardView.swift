import SwiftUI

struct KanbanBoardView: View {
    @Bindable var store: KanbanStore
    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: SpacingTokens.md) {
                ForEach(store.columns) { KanbanColumnView(store: store, column: $0) }
            }.padding(.vertical, 4)
        }.scrollIndicators(.visible)
    }
}
