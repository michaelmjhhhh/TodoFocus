import SwiftUI

struct TaskListView: View {
    @Bindable var appModel: AppModel
    @Bindable var store: TodoAppStore
    @State private var commandText: String = ""
    @State private var isCompletedCollapsed: Bool = false
    @State private var showClearCompletedConfirmation: Bool = false
    @FocusState private var isCommandFocused: Bool

    var body: some View {
        VStack(spacing: 12) {
            commandBar

            HStack(spacing: 10) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                Spacer()
                Picker("Filter", selection: Binding(
                    get: { appModel.timeFilter },
                    set: { appModel.timeFilter = $0 }
                )) {
                    Text("All").tag(TimeFilter.allDates)
                    Text("Overdue").tag(TimeFilter.overdue)
                    Text("Today").tag(TimeFilter.today)
                    Text("Tomorrow").tag(TimeFilter.tomorrow)
                    Text("Next 7").tag(TimeFilter.next7Days)
                    Text("No Date").tag(TimeFilter.noDate)
                }
                .pickerStyle(.menu)

                Text("\(filteredVisibleTodos.count)")
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(VisualTokens.sectionBackground, in: Capsule())

                Circle()
                    .fill(VisualTokens.violetAccent)
                    .frame(width: 7, height: 7)
                Circle()
                    .fill(VisualTokens.cyanAccent)
                    .frame(width: 7, height: 7)
                Circle()
                    .fill(VisualTokens.roseAccent)
                    .frame(width: 7, height: 7)
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
                completedColumn
            }
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
                    .foregroundStyle(VisualTokens.mutedText)

                TextField("Search tasks", text: $commandText)
                    .textFieldStyle(.plain)
                    .focused($isCommandFocused)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(VisualTokens.sectionBackground, in: RoundedRectangle(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(VisualTokens.sectionBorder, lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.14), radius: 6, y: 2)
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
            HStack(spacing: 6) {
                Button {
                    isCompletedCollapsed.toggle()
                } label: {
                    Image(systemName: isCompletedCollapsed ? "chevron.right" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(VisualTokens.mutedText)
                }
                .buttonStyle(.plain)

                Text("Completed")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(VisualTokens.mutedText)

                Spacer()

                if !isCompletedCollapsed {
                    Button("Clear Completed") {
                        showClearCompletedConfirmation = true
                    }
                    .buttonStyle(.borderless)
                    .font(.caption)
                    .disabled(completedTodos.isEmpty)
                }

                Text("\(completedTodos.count)")
                    .font(.caption2)
                    .foregroundStyle(VisualTokens.mutedText)
            }

            if !isCompletedCollapsed {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(completedTodos) { todo in
                            TodoRowView(
                                todo: todo,
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
        .background(VisualTokens.sectionBackground, in: RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(VisualTokens.sectionBorder, lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.12), radius: 6, y: 2)
    }
}
