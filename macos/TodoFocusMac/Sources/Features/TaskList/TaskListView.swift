import SwiftUI

struct TaskListView: View {
    @Bindable var appModel: AppModel
    @Bindable var store: TodoAppStore
    @State private var commandText: String = ""
    @State private var isCompletedCollapsed: Bool = false
    @State private var isCompletedPanelVisible: Bool = true
    @State private var showClearCompletedConfirmation: Bool = false
    @FocusState private var isCommandFocused: Bool

    var body: some View {
        VStack(spacing: 12) {
            commandBar

            HStack(spacing: 10) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                Spacer()
                filterPicker

                Text("\(filteredVisibleTodos.count)")
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(VisualTokens.sectionBackground, in: Capsule())

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
                    .foregroundStyle(isCompletedPanelVisible ? VisualTokens.textSecondary : VisualTokens.textTertiary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(VisualTokens.sectionBackground, in: Capsule())
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
            .background(VisualTokens.sectionBackground, in: RoundedRectangle(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(VisualTokens.sectionBorder, lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.18), radius: 8, y: 3)

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
                    .foregroundStyle(isCommandFocused ? Color.white.opacity(0.92) : VisualTokens.mutedText)

                TextField("Search tasks", text: $commandText)
                    .textFieldStyle(.plain)
                    .focused($isCommandFocused)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(VisualTokens.sectionBackground, in: RoundedRectangle(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isCommandFocused ? Color.white.opacity(0.28) : VisualTokens.sectionBorder, lineWidth: isCommandFocused ? 1.2 : 1)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(isCommandFocused ? 0.10 : 0), lineWidth: 4)
                    .blur(radius: 0.4)
            }
            .shadow(color: Color.black.opacity(0.14), radius: 6, y: 2)
            .shadow(color: isCommandFocused ? Color.white.opacity(0.10) : .clear, radius: 8)
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

    private var filteredVisibleTodos: [Todo] {
        Self.filterTodos(store.visibleTodos, query: commandText)
    }

    private var activeTodos: [Todo] {
        filteredVisibleTodos.filter { !$0.isCompleted }
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
                    .foregroundStyle(VisualTokens.mutedText)
                Spacer()
                Text("\(todos.count)")
                    .font(.caption2)
                    .foregroundStyle(VisualTokens.mutedText)
            }

            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(todos) { todo in
                        TodoRowView(
                            todo: todo,
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
        .background(VisualTokens.sectionBackground, in: RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(VisualTokens.sectionBorder, lineWidth: 1)
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
                            .foregroundStyle(VisualTokens.textTertiary)

                        Text("Completed")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(VisualTokens.textSecondary)
                    }
                }
                .buttonStyle(.plain)

                Text("\(completedTodos.count)")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(VisualTokens.textTertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(VisualTokens.bgFloating, in: Capsule())

                Spacer()

                if !isCompletedCollapsed && !completedTodos.isEmpty {
                    Button {
                        showClearCompletedConfirmation = true
                    } label: {
                        Text("Clear")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(VisualTokens.accentTerracotta)
                    }
                    .buttonStyle(.plain)
                }
            }

            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(completedTodos) { todo in
                        TodoRowView(
                            todo: todo,
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
        .background(VisualTokens.sectionBackground, in: RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(VisualTokens.sectionBorder, lineWidth: 1)
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
                        .foregroundStyle(appModel.timeFilter == filter ? VisualTokens.textPrimary : VisualTokens.textTertiary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(appModel.timeFilter == filter ? VisualTokens.bgFloating : Color.clear, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(VisualTokens.bgBase.opacity(0.5), in: Capsule())
    }

    private func colorForList(listId: String?) -> Color? {
        guard let listId else { return nil }
        guard let list = store.lists.first(where: { $0.id == listId }) else { return nil }
        return Color(hex: list.color)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        self.init(
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255
        )
    }
}
