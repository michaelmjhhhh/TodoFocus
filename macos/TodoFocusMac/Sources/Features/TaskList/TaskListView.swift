import SwiftUI

struct TaskListView: View {
    @Bindable var appModel: AppModel
    @Bindable var store: TodoAppStore
    @Environment(\.themeTokens) private var tokens
    @State private var commandText: String = ""
    @State private var isCompletedCollapsed: Bool = false
    @State private var isCompletedPanelVisible: Bool = true
    @State private var showClearCompletedConfirmation: Bool = false
    @FocusState private var isCommandFocused: Bool

    private var listColorMap: [String: Color] {
        Dictionary(uniqueKeysWithValues: store.lists.compactMap { list in
            guard let color = Color(hex: list.color) as Color? else { return nil }
            return (list.id, color)
        })
    }

    var body: some View {
        VStack(spacing: 12) {
            commandBar

            HStack(spacing: 10) {
                if isOverdueView {
                    Text("Overdue \u{00b7} \(store.formatDebt(store.totalOverdueDebtSeconds)) total debt")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                } else {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                }
                Spacer()
                if !isOverdueView {
                    filterPicker
                }

                Text("\(filteredVisibleTodos.count)")
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(tokens.sectionBackground, in: Capsule())

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isCompletedPanelVisible.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isCompletedPanelVisible ? "eye" : "eye.slash")
                            .font(.system(size: 11))
                        Text("Completed")
                            .font(.caption2.weight(.medium))
                        Text("\(completedTodos.count)")
                            .font(.caption2.weight(.medium))
                    }
                    .foregroundStyle(isCompletedPanelVisible ? tokens.textSecondary : tokens.textTertiary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(tokens.sectionBackground, in: Capsule())
                }
                .buttonStyle(.plain)
                .help(isCompletedPanelVisible ? "Hide completed panel" : "Show completed panel")
            }

            QuickAddView { title in
                do {
                    try store.quickAdd(
                        title: title,
                        planned: appModel.selection == .planned,
                        isImportant: appModel.selection == .important,
                        isMyDay: appModel.selection == .myDay,
                        list: selectedList
                    )
                } catch {
                }
            }
            .padding(10)
            .background(tokens.sectionBackground, in: RoundedRectangle(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(tokens.sectionBorder, lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.18), radius: 8, y: 3)

            if isOverdueView && activeTodos.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 40))
                        .foregroundStyle(tokens.textTertiary)
                    Text("No overdue tasks")
                        .font(.body.weight(.medium))
                        .foregroundStyle(tokens.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                Spacer()
            } else {
                HStack(spacing: 12) {
                    todoColumn(title: "Active", todos: activeTodos)
                        .frame(maxWidth: .infinity)

                    if isCompletedPanelVisible {
                        completedColumn
                            .frame(width: 260)
                            .transition(.opacity.combined(with: .move(edge: .trailing)))
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: isCompletedPanelVisible)
            }
        }
        .shortcutHintBar(
            needsAccessibilityPermission: appModel.quickCaptureService.needsAccessibilityPermission,
            onRequestPermission: {
                appModel.quickCaptureService.requestAccessibilityPermission()
            }
        )
        .padding(16)
        .foregroundStyle(.primary)
        .animation(MotionTokens.interactiveSpring, value: filteredVisibleTodos.count)
        .animation(MotionTokens.focusEase, value: appModel.timeFilter)
        .alert("Clear completed tasks?", isPresented: $showClearCompletedConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                try? store.clearCompletedTodos()
            }
        } message: {
            Text("This permanently deletes all completed tasks in the current view.")
        }
    }

    private var commandBar: some View {
        HStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(isCommandFocused ? tokens.textPrimary : tokens.mutedText)

                TextField("Search tasks (⌘K)", text: $commandText)
                    .textFieldStyle(.plain)
                    .focused($isCommandFocused)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(tokens.sectionBackground, in: RoundedRectangle(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isCommandFocused ? tokens.textPrimary.opacity(0.3) : tokens.sectionBorder, lineWidth: isCommandFocused ? 1.2 : 1)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(tokens.textPrimary.opacity(isCommandFocused ? 0.08 : 0), lineWidth: 4)
                    .blur(radius: 0.4)
            }
            .shadow(color: Color.black.opacity(0.14), radius: 6, y: 2)
            .shadow(color: isCommandFocused ? tokens.textPrimary.opacity(0.08) : .clear, radius: 8)
            .animation(MotionTokens.focusEase, value: isCommandFocused)
        }
        .background {
            Button("") {
                isCommandFocused = true
            }
            .keyboardShortcut("k", modifiers: [.command])
            .opacity(0)
            .allowsHitTesting(false)
        }
    }

    private var title: String {
        switch appModel.selection {
        case .myDay:
            return "My Day"
        case .important:
            return "Important"
        case .planned:
            return "Planned"
        case .overdue:
            return "Overdue"
        case .all:
            return "All Tasks"
        case let .customList(id):
            return store.lists.first(where: { $0.id == id })?.name ?? "List"
        }
    }

    private var selectedList: TodoList? {
        if case let .customList(listID) = appModel.selection {
            return store.lists.first(where: { $0.id == listID })
        }
        return nil
    }

    private var isOverdueView: Bool {
        appModel.selection == .overdue
    }

    private var filteredVisibleTodos: [Todo] {
        Self.filterTodos(store.visibleTodos, query: commandText)
    }

    private var activeTodos: [Todo] {
        var todos = filteredVisibleTodos.filter { !$0.isCompleted }
        if isOverdueView {
            todos.sort { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
        }
        return todos
    }

    private var completedTodos: [Todo] {
        filteredVisibleTodos.filter(\.isCompleted)
    }

    static func filterTodos(_ todos: [Todo], query: String) -> [Todo] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            return todos
        }

        return todos.filter {
            $0.title.localizedCaseInsensitiveContains(trimmedQuery) ||
            $0.notes.localizedCaseInsensitiveContains(trimmedQuery)
        }
    }

    private func todoColumn(title: String, todos: [Todo]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(tokens.mutedText)
                Spacer()
                Text("\(todos.count)")
                    .font(.caption2)
                    .foregroundStyle(tokens.mutedText)
            }

            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(todos) { todo in
                        TodoRowView(
                            todo: todo,
                            store: store,
                            listColor: colorForList(listId: todo.listId),
                            isSelected: appModel.selectedTodoID == todo.id,
                            onSelect: {
                                store.selectTodo(todoId: todo.id)
                            },
                            onToggleComplete: {
                                try? store.toggleComplete(todoId: todo.id)
                            },
                            onToggleImportant: {
                                try? store.toggleImportant(todoId: todo.id)
                            },
                            onDelete: {
                                try? store.deleteTodo(todoId: todo.id)
                            }
                        )
                    }
                }
                .padding(2)
            }
        }
        .padding(10)
        .background(tokens.sectionBackground, in: RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(tokens.sectionBorder, lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.12), radius: 6, y: 2)
    }

    private var completedColumn: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isCompletedCollapsed.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isCompletedCollapsed ? "chevron.right" : "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(tokens.textTertiary)

                        Text("Completed")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(tokens.textSecondary)
                    }
                }
                .buttonStyle(.plain)

                Text("\(completedTodos.count)")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(tokens.textTertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(tokens.bgFloating, in: Capsule())

                Spacer()

                if !isCompletedCollapsed && !completedTodos.isEmpty {
                    Button {
                        showClearCompletedConfirmation = true
                    } label: {
                        Text("Clear")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(tokens.accentTerracotta)
                    }
                    .buttonStyle(.plain)
                }
            }

            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(completedTodos) { todo in
                        TodoRowView(
                            todo: todo,
                            store: store,
                            listColor: colorForList(listId: todo.listId),
                            isSelected: appModel.selectedTodoID == todo.id,
                            onSelect: {
                                store.selectTodo(todoId: todo.id)
                            },
                            onToggleComplete: {
                                try? store.toggleComplete(todoId: todo.id)
                            },
                            onToggleImportant: {
                                try? store.toggleImportant(todoId: todo.id)
                            },
                            onDelete: {
                                try? store.deleteTodo(todoId: todo.id)
                            }
                        )
                    }
                }
                .padding(2)
            }
            .opacity(isCompletedCollapsed ? 0 : 1)
            .clipped()
        }
        .padding(10)
        .background(tokens.sectionBackground, in: RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(tokens.sectionBorder, lineWidth: 1)
        }
    }

    private var filterPicker: some View {
        HStack(spacing: 2) {
            ForEach(TimeFilter.allCases) { filter in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        appModel.timeFilter = filter
                    }
                } label: {
                    Text(filter.label)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(appModel.timeFilter == filter ? tokens.textPrimary : tokens.textTertiary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(appModel.timeFilter == filter ? tokens.bgFloating : Color.clear, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(tokens.bgBase.opacity(0.5), in: Capsule())
    }

    private func colorForList(listId: String?) -> Color? {
        guard let listId else { return nil }
        return listColorMap[listId]
    }
}

