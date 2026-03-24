import SwiftUI

struct SidebarView: View {
    @Bindable var appModel: AppModel
    @Bindable var store: TodoAppStore
    let lists: [TodoList]
    @State private var isAddingList: Bool = false
    @State private var newListName: String = ""
    @State private var newListColor: String = "#6366F1"
    @State private var editingListId: String?
    @State private var editingListName: String = ""
    @State private var editingListColor: String = "#6366F1"

    private let availableColors: [String] = [
        "#EF4444", "#F97316", "#EAB308", "#22C55E", "#06B6D4",
        "#3B82F6", "#8B5CF6", "#EC4899", "#6366F1", "#14B8A6"
    ]

    var body: some View {
        List {
            Section {
                smartRow("My Day", systemImage: "sun.max", selection: .myDay, count: store.myDayCount)
                smartRow("Important", systemImage: "star", selection: .important, count: store.importantCount)
                smartRow("Planned", systemImage: "calendar", selection: .planned, count: store.plannedCount)
                smartRow("All Tasks", systemImage: "tray.full", selection: .all, count: store.todoCount)
            }

            Section {
                ForEach(lists) { list in
                    SidebarListItemView(
                        list: list,
                        isEditing: editingListId == list.id,
                        appModel: appModel,
                        store: store,
                        editingListId: $editingListId,
                        editingListName: $editingListName,
                        editingListColor: $editingListColor
                    )
                }
                .onDelete(perform: deleteLists)

                if isAddingList {
                    addingListRow
                } else {
                    addListButton
                }
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(VisualTokens.bgElevated)
        .animation(MotionTokens.focusEase, value: appModel.selection)
        .animation(.easeInOut(duration: 0.15), value: lists.count)
    }

    private func smartRow(_ title: String, systemImage: String, selection: SidebarSelection, count: Int? = nil) -> some View {
        SidebarRowButton(
            title: title,
            systemImage: systemImage,
            listColor: nil,
            isSelected: appModel.selection == selection,
            count: count,
            action: {
                withAnimation(MotionTokens.focusEase) {
                    appModel.selectSidebar(selection)
                }
            }
        )
    }

    private var addListButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                isAddingList = true
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(VisualTokens.textTertiary)

                Text("Add list")
                    .font(.system(size: 13))
                    .foregroundStyle(VisualTokens.textTertiary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }

    private var addingListRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color(hex: newListColor))
                    .frame(width: 12, height: 12)

                TextField("List name", text: $newListName)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundStyle(VisualTokens.textPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(VisualTokens.bgBase, in: RoundedRectangle(cornerRadius: 6))
                    .overlay {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(VisualTokens.textTertiary.opacity(0.3), lineWidth: 1)
                    }
                    .onSubmit {
                        commitAddList()
                    }

                Button {
                    commitAddList()
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(VisualTokens.accentTerracotta)
                }
                .buttonStyle(.plain)
                .disabled(newListName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isAddingList = false
                        newListName = ""
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10))
                        .foregroundStyle(VisualTokens.textTertiary)
                }
                .buttonStyle(.plain)
            }

            colorPickerRow(selectedColor: $newListColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }

    private func colorPickerRow(selectedColor: Binding<String>) -> some View {
        HStack(spacing: 6) {
            ForEach(availableColors, id: \.self) { colorHex in
                Circle()
                    .fill(Color(hex: colorHex))
                    .frame(width: 16, height: 16)
                    .overlay {
                        if selectedColor.wrappedValue == colorHex {
                            Image(systemName: "checkmark")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            selectedColor.wrappedValue = colorHex
                        }
                    }
            }
        }
    }

    private func commitAddList() {
        let trimmed = newListName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        store.createList(name: trimmed, color: newListColor)
        newListName = ""
        newListColor = "#6366F1"
        withAnimation(.easeInOut(duration: 0.15)) {
            isAddingList = false
        }
    }

    private func deleteLists(at offsets: IndexSet) {
        for index in offsets {
            if index < lists.count {
                store.deleteList(listId: lists[index].id)
            }
        }
    }
}

private struct SidebarRowButton: View {
    let title: String
    let systemImage: String
    let listColor: Color?
    let isSelected: Bool
    let count: Int?
    let action: () -> Void
    @State private var isHovered: Bool = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Capsule()
                    .fill(listColor ?? VisualTokens.accentTerracotta)
                    .frame(width: listColor != nil || isSelected ? 3 : 0, height: listColor != nil || isSelected ? 16 : 0)

                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? VisualTokens.textPrimary : VisualTokens.textSecondary)

                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? VisualTokens.textPrimary : VisualTokens.textSecondary)

                if let count {
                    Text("\(count)")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(isSelected ? VisualTokens.textSecondary : VisualTokens.textTertiary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(VisualTokens.bgFloating.opacity(0.5), in: Capsule())
                }

                Spacer(minLength: 0)

                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(listColor ?? VisualTokens.accentTerracotta)
                    .opacity(isSelected ? 1 : 0)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(isSelected ? VisualTokens.bgFloating : Color.clear, in: RoundedRectangle(cornerRadius: 9))
            .contentShape(RoundedRectangle(cornerRadius: 9))
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.12)) {
                isHovered = hovering
            }
        }
    }
}

private struct SidebarListItemView: View {
    let list: TodoList
    let isEditing: Bool
    let appModel: AppModel
    let store: TodoAppStore
    @Binding var editingListId: String?
    @Binding var editingListName: String
    @Binding var editingListColor: String

    private static let availableColors: [String] = [
        "#EF4444", "#F97316", "#EAB308", "#22C55E", "#06B6D4",
        "#3B82F6", "#8B5CF6", "#EC4899", "#6366F1", "#14B8A6"
    ]

    var body: some View {
        if isEditing {
            listEditRow
        } else {
            listRow
        }
    }

    @ViewBuilder
    private var listRow: some View {
        SidebarRowButton(
            title: list.name,
            systemImage: "list.bullet",
            listColor: Color(hex: list.color),
            isSelected: appModel.selection == .customList(list.id),
            count: store.countForList(list.id),
            action: {
                withAnimation(MotionTokens.focusEase) {
                    appModel.selectSidebar(.customList(list.id))
                }
            }
        )
        .contextMenu {
            Button("Edit color") {
                editingListId = list.id
                editingListName = list.name
                editingListColor = list.color
            }
            Button("Rename") {
                editingListId = list.id
                editingListName = list.name
            }
            Divider()
            Button("Delete", role: .destructive) {
                store.deleteList(listId: list.id)
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                store.deleteList(listId: list.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    @ViewBuilder
    private var listEditRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color(hex: editingListColor))
                    .frame(width: 12, height: 12)

                TextField("List name", text: $editingListName)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundStyle(VisualTokens.textPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(VisualTokens.bgBase, in: RoundedRectangle(cornerRadius: 6))
                    .overlay {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(VisualTokens.textTertiary.opacity(0.3), lineWidth: 1)
                    }
                    .onSubmit {
                        renameList
                    }

                Button {
                    renameList
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(VisualTokens.accentTerracotta)
                }
                .buttonStyle(.plain)

                Button {
                    editingListId = nil
                    editingListName = ""
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10))
                        .foregroundStyle(VisualTokens.textTertiary)
                }
                .buttonStyle(.plain)
            }

            colorPickerRow(selectedColor: $editingListColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }

    private func colorPickerRow(selectedColor: Binding<String>) -> some View {
        HStack(spacing: 6) {
            ForEach(Self.availableColors, id: \.self) { colorHex in
                Circle()
                    .fill(Color(hex: colorHex))
                    .frame(width: 16, height: 16)
                    .overlay {
                        if selectedColor.wrappedValue == colorHex {
                            Image(systemName: "checkmark")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            selectedColor.wrappedValue = colorHex
                        }
                    }
            }
        }
    }

    private var renameList: Void {
        let trimmed = editingListName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            editingListId = nil
            return
        }
        store.renameList(listId: list.id, newName: trimmed, color: editingListColor)
        editingListId = nil
        editingListName = ""
    }
}
