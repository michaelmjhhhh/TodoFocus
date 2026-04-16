import SwiftUI

struct SidebarView: View {
    @Bindable var appModel: AppModel
    @Bindable var store: TodoAppStore
    let lists: [TodoList]
    let themeStore: ThemeStore
    @Environment(\.themeTokens) private var tokens
    @State private var isAddingList: Bool = false
    @State private var newListName: String = ""
    @State private var newListColor: String = "#6366F1"
    @State private var editingListId: String?
    @State private var editingListName: String = ""
    @State private var editingListColor: String = "#6366F1"

    var body: some View {
        List {
            Section {
                smartRow("Daily Review", systemImage: "checklist", selection: .dailyReview, count: store.todoCount)
                smartRow("My Day", systemImage: "sun.max", selection: .myDay, count: store.myDayCount)
                smartRow("Important", systemImage: "star", selection: .important, count: store.importantCount)
                smartRow("Planned", systemImage: "calendar", selection: .planned, count: store.plannedCount)
                smartRow("Overdue", systemImage: "exclamationmark.triangle", selection: .overdue, count: store.overdueCount)
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
            } footer: {
                HStack {
                    Spacer()
                    themeToggleButton
                    Spacer()
                }
                .padding(.top, 4)
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(tokens.bgElevated)
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
            HStack(spacing: 10) {
                Capsule()
                    .fill(tokens.accentTerracotta)
                    .frame(width: 3, height: 16)
                    .opacity(0)

                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(tokens.textTertiary)
                    .frame(width: 16, alignment: .center)

                Text("Add list")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(tokens.textTertiary)

                Spacer(minLength: 0)

                Color.clear
                    .frame(width: 14, height: 10)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(tokens.bgFloating.opacity(0.28), in: RoundedRectangle(cornerRadius: 9))
            .overlay {
                RoundedRectangle(cornerRadius: 9)
                    .stroke(tokens.sectionBorder.opacity(0.75), lineWidth: 1)
            }
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
                    .foregroundStyle(tokens.textPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(tokens.bgBase, in: RoundedRectangle(cornerRadius: 6))
                    .overlay {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(tokens.textTertiary.opacity(0.3), lineWidth: 1)
                    }
                    .onSubmit {
                        commitAddList()
                    }

                Button {
                    commitAddList()
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(tokens.accentTerracotta)
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
                        .foregroundStyle(tokens.textTertiary)
                }
                .buttonStyle(.plain)
            }

            ColorPickerRow(selectedColor: $newListColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
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

    private var themeIcon: String {
        switch themeStore.theme {
        case .dark: return "moon.fill"
        case .light: return "sun.max.fill"
        case .system: return "circle.lefthalf.filled"
        }
    }

    private var themeTooltip: String {
        switch themeStore.theme {
        case .dark: return "Dark mode — click to switch"
        case .light: return "Light mode — click to switch"
        case .system: return "System mode — click to switch"
        }
    }

    private var themeToggleButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                themeStore.cycleTheme()
            }
        } label: {
            Image(systemName: themeIcon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(tokens.textSecondary)
                .frame(width: 28, height: 28)
                .background(tokens.bgFloating, in: RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(themeTooltip)
        .help(themeTooltip)
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
    @Environment(\.themeTokens) private var tokens

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Capsule()
                    .fill(listColor ?? tokens.accentTerracotta)
                    .frame(width: 3, height: 16)
                    .opacity(listColor != nil || isSelected ? 1 : 0)

                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? tokens.textPrimary : tokens.textSecondary)
                    .frame(width: 16, alignment: .center)

                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? tokens.textPrimary : tokens.textSecondary)

                Spacer(minLength: 0)

                if let count {
                    Text("\(count)")
                        .font(.caption2.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(isSelected ? tokens.textSecondary : tokens.textTertiary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(tokens.bgFloating.opacity(0.58), in: Capsule())
                        .overlay {
                            Capsule()
                                .stroke(tokens.sectionBorder.opacity(0.82), lineWidth: 1)
                        }
                }

                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(listColor ?? tokens.accentTerracotta)
                    .opacity(isSelected ? 1 : 0)
                    .frame(width: 14, alignment: .trailing)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(isSelected ? tokens.bgFloating : Color.clear, in: RoundedRectangle(cornerRadius: 9))
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
    @Environment(\.themeTokens) private var tokens

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
                    .foregroundStyle(tokens.textPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(tokens.bgBase, in: RoundedRectangle(cornerRadius: 6))
                    .overlay {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(tokens.textTertiary.opacity(0.3), lineWidth: 1)
                    }
                    .onSubmit {
                        renameList
                    }

                Button {
                    renameList
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(tokens.accentTerracotta)
                }
                .buttonStyle(.plain)

                Button {
                    editingListId = nil
                    editingListName = ""
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10))
                        .foregroundStyle(tokens.textTertiary)
                }
                .buttonStyle(.plain)
            }

            ColorPickerRow(selectedColor: $editingListColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
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

private struct ColorPickerRow: View {
    @Binding var selectedColor: String
    @Environment(\.themeTokens) private var tokens

    var body: some View {
        HStack(spacing: 6) {
            ForEach(ListColor.all) { listColor in
                Button {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        selectedColor = listColor.id
                    }
                } label: {
                    Circle()
                        .fill(listColor.color)
                        .frame(width: 16, height: 16)
                        .overlay {
                            if selectedColor == listColor.id {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(listColor.name) color")
                .help("\(listColor.name) color")
            }
        }
    }
}
