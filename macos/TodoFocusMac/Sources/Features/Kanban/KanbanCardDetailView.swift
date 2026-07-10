import SwiftUI

struct KanbanCardDetailView: View {
    @Bindable var store: KanbanStore
    let onClose: () -> Void
    @Environment(\.themeTokens) private var tokens
    @State private var labelName = ""
    @State private var checklistTitle = ""
    @State private var showsDelete = false
    @State private var dueEnabled = false
    @State private var dueDate = Date()

    var body: some View {
        Group {
            if let card = store.selectedCard {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack { Text("Card Details").font(TypographyTokens.displaySmall); Spacer(); Button(action: onClose) { Image(systemName: "xmark") }.accessibilityLabel("Close card details") }
                        TextField("Card title", text: Binding(get: { card.title }, set: { value in store.updateSelectedCardTitle(value) })).font(TypographyTokens.headingLarge).textFieldStyle(.plain)
                        field("Status") { Picker("Status", selection: Binding(get: { card.status }, set: { newStatus in store.moveCard(id: card.id, to: newStatus, destinationIndex: store.columns.first(where: { $0.status == newStatus })?.cards.count ?? 0) })) { ForEach(KanbanStatus.allCases) { Text($0.title).tag($0) } }.labelsHidden() }
                        field("Priority") { Picker("Priority", selection: Binding(get: { card.priority }, set: { value in store.setSelectedCardPriority(value) })) { ForEach(KanbanPriority.allCases) { Text($0.title).tag($0) } }.labelsHidden() }
                        dueDate(card)
                        field("Description") { TextEditor(text: Binding(get: { card.description }, set: { value in store.updateSelectedCardDescriptionDebounced(value) })).frame(minHeight: 110).scrollContentBackground(.hidden).padding(6).background(tokens.bgSubtle, in: RoundedRectangle(cornerRadius: 8)) }
                        labels(card)
                        checklist(card)
                        Divider()
                        HStack { Button("Archive Card") { store.archiveSelectedCard() }; Spacer(); Button("Delete Card", role: .destructive) { showsDelete = true } }
                    }.padding(20)
                }
            }
        }
        .confirmationDialog("Delete this card permanently?", isPresented: $showsDelete) { Button("Delete Card", role: .destructive) { store.deleteSelectedCard() } }
        .onAppear { syncDueDate() }
        .onChange(of: store.selectedCardID) { _, _ in syncDueDate() }
    }

    private func dueDate(_ card: KanbanCard) -> some View {
        field("Due date") {
            HStack {
                Toggle("Set", isOn: $dueEnabled).labelsHidden().onChange(of: dueEnabled) { _, enabled in store.setSelectedCardDueDate(enabled ? dueDate : nil) }
                if dueEnabled { DatePicker("", selection: $dueDate, displayedComponents: .date).labelsHidden().onChange(of: dueDate) { _, value in store.setSelectedCardDueDate(value) } }
            }
        }
    }
    private func labels(_ card: KanbanCard) -> some View {
        field("Labels") {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(card.labels) { label in HStack { Text(label.name); Spacer(); Button { store.deleteLabel(id: label.id) } label: { Image(systemName: "xmark") }.buttonStyle(.plain).accessibilityLabel("Delete label \(label.name)") } }
                HStack { TextField("New label", text: $labelName).onSubmit(addLabel); Button("Add", action: addLabel).disabled(labelName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
            }
        }
    }
    private func checklist(_ card: KanbanCard) -> some View {
        field("Checklist") {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(card.checklist) { item in HStack { Toggle("", isOn: Binding(get: { item.isCompleted }, set: { store.toggleChecklistItem(id: item.id, isCompleted: $0) })).labelsHidden().accessibilityLabel(item.title); Text(item.title).strikethrough(item.isCompleted); Spacer(); Button { store.deleteChecklistItem(id: item.id) } label: { Image(systemName: "trash") }.buttonStyle(.plain).accessibilityLabel("Delete checklist item \(item.title)") } }
                HStack { TextField("New checklist item", text: $checklistTitle).onSubmit(addChecklist); Button("Add", action: addChecklist).disabled(checklistTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
            }
        }
    }
    private func field<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View { VStack(alignment: .leading, spacing: 6) { Text(title).font(TypographyTokens.headingSmall).foregroundStyle(tokens.textSecondary); content() } }
    private func addLabel() { let value = labelName.trimmingCharacters(in: .whitespacesAndNewlines); guard !value.isEmpty else { return }; store.addLabel(value); labelName = "" }
    private func addChecklist() { let value = checklistTitle.trimmingCharacters(in: .whitespacesAndNewlines); guard !value.isEmpty else { return }; store.addChecklistItem(value); checklistTitle = "" }
    private func syncDueDate() { dueEnabled = store.selectedCard?.dueDate != nil; dueDate = store.selectedCard?.dueDate ?? Date() }
}
