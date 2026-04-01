import SwiftUI

struct TaskListView: View {
    @Bindable var appModel: AppModel
    @Bindable var store: TodoAppStore
    @Environment(\.themeTokens) private var tokens
    @State private var commandText: String = ""
    @State private var isCompletedCollapsed: Bool = false
    @State private var isCompletedPanelVisible: Bool = true
    @State private var showClearCompletedConfirmation: Bool = false
    @State private var filteredTodosCache: [Todo] = []
    @State private var activeTodosCache: [Todo] = []
    @State private var completedTodosCache: [Todo] = []
    @State private var listColorCache: [String: Color] = [:]
    @FocusState private var isCommandFocused: Bool

    var body: some View {
        VStack(spacing: 12) {
            commandBar
            if let errorMessage = store.mutationErrorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(tokens.danger)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(tokens.textSecondary)
                        .lineLimit(2)
                    Spacer(minLength: 6)
                    Button("Dismiss") {
                        store.clearMutationError()
                    }
                    .buttonStyle(.plain)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(tokens.accentTerracotta)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(tokens.sectionBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(tokens.sectionBorder, lineWidth: 1)
                }
            }

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

                Text("\(filteredTodosCache.count)")
                    .font(.caption.weight(.semibold))
                    .monospacedDigit()
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .foregroundStyle(tokens.textSecondary)
                    .background(tokens.bgFloating.opacity(0.85), in: Capsule())
                    .overlay {
                        Capsule()
                            .stroke(tokens.sectionBorder.opacity(0.9), lineWidth: 1)
                    }

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isCompletedPanelVisible.toggle()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: isCompletedPanelVisible ? "eye" : "eye.slash")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(isCompletedPanelVisible ? tokens.accentTerracotta : tokens.textTertiary)
                            .frame(width: 20, height: 20)
                            .background(tokens.bgFloating.opacity(0.95), in: Circle())
                        Text("Completed")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(isCompletedPanelVisible ? tokens.textSecondary : tokens.textTertiary)
                        Text("\(completedTodosCache.count)")
                            .font(.caption.weight(.semibold))
                            .monospacedDigit()
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .foregroundStyle(isCompletedPanelVisible ? tokens.textPrimary : tokens.textSecondary)
                            .background(tokens.bgFloating.opacity(0.95), in: Capsule())
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(tokens.bgFloating.opacity(isCompletedPanelVisible ? 0.82 : 0.66), in: Capsule())
                    .overlay {
                        Capsule()
                            .stroke(
                                isCompletedPanelVisible
                                    ? tokens.accentTerracotta.opacity(0.28)
                                    : tokens.sectionBorder.opacity(0.92),
                                lineWidth: 1
                            )
                    }
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
            .background(tokens.sectionBackground, in: RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(tokens.sectionBorder, lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.14), radius: 8, y: 3)

            if isOverdueView && activeTodosCache.isEmpty {
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
                    todoColumn(title: "Active", todos: activeTodosCache)
                        .frame(maxWidth: .infinity)

                    if isCompletedPanelVisible {
                        completedColumn(todos: completedTodosCache)
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
        .animation(MotionTokens.interactiveSpring, value: filteredTodosCache.count)
        .animation(MotionTokens.focusEase, value: appModel.timeFilter)
        .onAppear {
            recalculateCaches()
            rebuildListColorCache()
        }
        .onChange(of: commandText) { _, _ in
            recalculateCaches()
        }
        .onChange(of: store.todos) { _, _ in
            recalculateCaches()
        }
        .onChange(of: appModel.selection) { _, _ in
            recalculateCaches()
        }
        .onChange(of: appModel.timeFilter) { _, _ in
            recalculateCaches()
        }
        .onChange(of: store.lists) { _, _ in
            rebuildListColorCache()
        }
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
                    .foregroundStyle(isCommandFocused ? tokens.accentTerracotta : tokens.mutedText)

                TextField("Search tasks (⌘K)", text: $commandText)
                    .textFieldStyle(.plain)
                    .focused($isCommandFocused)

                if !commandText.isEmpty {
                    Button {
                        commandText = ""
                        isCommandFocused = true
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(tokens.textTertiary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear search")
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(tokens.inputSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isCommandFocused ? tokens.inputBorderFocused : tokens.inputBorder, lineWidth: isCommandFocused ? 1.2 : 1)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(tokens.inputGlow.opacity(isCommandFocused ? 0.52 : 0), lineWidth: 4)
                    .blur(radius: 0.7)
            }
            .shadow(color: Color.black.opacity(0.10), radius: 5, y: 2)
            .shadow(color: isCommandFocused ? tokens.inputGlow : .clear, radius: 8, y: 1)
            .animation(MotionTokens.focusEase, value: isCommandFocused)
            .animation(MotionTokens.focusEase, value: commandText.isEmpty)
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
        case .dailyReview:
            return "Daily Review"
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

    private func recalculateCaches() {
        let filtered = store.filteredVisibleTodos(searchQuery: commandText)
        filteredTodosCache = filtered
        activeTodosCache = Self.activeTodos(filtered, isOverdueView: isOverdueView)
        completedTodosCache = filtered.filter(\.isCompleted)
    }

    private func rebuildListColorCache() {
        listColorCache = Dictionary(uniqueKeysWithValues: store.lists.compactMap { list in
            guard let color = Color(hex: list.color) as Color? else { return nil }
            return (list.id, color)
        })
    }

    private static func activeTodos(_ todos: [Todo], isOverdueView: Bool) -> [Todo] {
        var todos = todos.filter { !$0.isCompleted }
        if isOverdueView {
            todos.sort { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
        }
        return todos
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

    private func completedColumn(todos: [Todo]) -> some View {
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

                Text("\(todos.count)")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(tokens.textTertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(tokens.bgFloating, in: Capsule())

                Spacer()

                if !isCompletedCollapsed && !todos.isEmpty {
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

            if !isCompletedCollapsed {
                ScrollView {
                    LazyVStack(spacing: 4) {
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
        }
        .padding(10)
        .background(tokens.sectionBackground, in: RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(tokens.sectionBorder, lineWidth: 1)
        }
    }

    private var filterPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(TimeFilter.allCases) { filter in
                    Button {
                        withAnimation(MotionTokens.focusEase) {
                            appModel.timeFilter = filter
                        }
                    } label: {
                        Text(filter.label)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(appModel.timeFilter == filter ? tokens.textPrimary : tokens.textTertiary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                appModel.timeFilter == filter ? tokens.bgFloating.opacity(0.92) : Color.clear,
                                in: Capsule()
                            )
                            .overlay {
                                Capsule()
                                    .stroke(
                                        appModel.timeFilter == filter
                                            ? tokens.inputBorderFocused.opacity(0.65)
                                            : tokens.sectionBorder.opacity(0.0),
                                        lineWidth: 1
                                    )
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
        }
        .background(tokens.bgElevated.opacity(0.78), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(tokens.sectionBorder.opacity(0.9), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.10), radius: 6, y: 2)
        .fixedSize(horizontal: false, vertical: true)
    }

    private func colorForList(listId: String?) -> Color? {
        guard let listId else { return nil }
        return listColorCache[listId]
    }
}
