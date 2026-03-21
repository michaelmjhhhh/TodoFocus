import SwiftUI

struct TaskListView: View {
    @Bindable var appModel: AppModel
    @Bindable var store: TodoAppStore
    @State private var commandText: String = ""
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

                Text("\(store.visibleTodos.count)")
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(VisualTokens.sectionBackground, in: Capsule())
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

            List(selection: selectedTodoBinding) {
                ForEach(store.visibleTodos) { todo in
                    TodoRowView(
                        todo: todo,
                        onToggleComplete: {
                            try? store.toggleComplete(todoId: todo.id)
                        },
                        onToggleImportant: {
                            try? store.toggleImportant(todoId: todo.id)
                        },
                        onDeletePlaceholder: nil
                    )
                    .tag(todo.id)
                    .listRowInsets(EdgeInsets(top: 5, leading: 8, bottom: 5, trailing: 8))
                    .listRowBackground(Color.clear)
                }
            }
            .scrollContentBackground(.hidden)
            .listStyle(.plain)
        }
        .padding(16)
        .foregroundStyle(.primary)
        .animation(.spring(response: 0.24, dampingFraction: 0.86), value: store.visibleTodos.count)
        .animation(.easeInOut(duration: 0.18), value: appModel.timeFilter)
    }

    private var commandBar: some View {
        HStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(VisualTokens.mutedText)

                TextField("Search tasks or press ⌘K", text: $commandText)
                    .textFieldStyle(.plain)
                    .focused($isCommandFocused)

                Text("⌘K")
                    .font(.caption2.monospaced())
                    .foregroundStyle(VisualTokens.mutedText)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 5))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(VisualTokens.sectionBackground, in: RoundedRectangle(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(VisualTokens.sectionBorder, lineWidth: 1)
            }

            Button("New Task", systemImage: "plus") {
                do {
                    let created = try store.quickAdd(
                        title: "New Task",
                        planned: appModel.selection == .planned,
                        isImportant: appModel.selection == .important,
                        isMyDay: appModel.selection == .myDay,
                        list: selectedList
                    )
                    store.selectTodo(todoId: created.id)
                } catch {
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            Button("New List", systemImage: "list.bullet") {
                store.createList(name: nextListName())
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
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

    private var selectedTodoBinding: Binding<String?> {
        Binding(
            get: { appModel.selectedTodoID },
            set: { value in
                if let value {
                    store.selectTodo(todoId: value)
                } else {
                    store.clearSelection()
                }
            }
        )
    }

    private var selectedList: TodoList? {
        if case let .customList(listID) = appModel.selection {
            return store.lists.first(where: { $0.id == listID })
        }
        return nil
    }

    private func nextListName() -> String {
        let existing = Set(store.lists.map { $0.name.lowercased() })
        if !existing.contains("new list") {
            return "New List"
        }

        var index = 2
        while existing.contains("new list \(index)") {
            index += 1
        }
        return "New List \(index)"
    }
}
