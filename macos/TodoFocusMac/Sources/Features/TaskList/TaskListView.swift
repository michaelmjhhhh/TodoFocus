import SwiftUI

struct TaskListView: View {
    @Bindable var appModel: AppModel
    @Bindable var store: TodoAppStore

    var body: some View {
        VStack(spacing: 12) {
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
                }
            }
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
