import SwiftUI

struct TaskListView: View {
    @Bindable var appModel: AppModel
    @Bindable var store: TodoAppStore

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                Text(title)
                    .font(.system(size: 19, weight: .semibold, design: .rounded))
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
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())
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
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

            List(selection: selectedTodoBinding) {
                ForEach(store.visibleTodos) { todo in
                    TodoRowView(
                        todo: todo,
                        onToggleComplete: {
                            try? store.toggleComplete(todoId: todo.id)
                        },
                        onToggleImportant: {
                            try? store.toggleImportant(todoId: todo.id)
                        }
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
        .animation(.spring(response: 0.24, dampingFraction: 0.86), value: store.visibleTodos.count)
        .animation(.easeInOut(duration: 0.18), value: appModel.timeFilter)
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
}
