import SwiftUI

struct TaskDetailView: View {
    @Bindable var store: TodoAppStore
    let todo: Todo?
    @State private var notesText: String = ""
    @State private var dueDate: Date = Date()

    init(store: TodoAppStore, todo: Todo?) {
        self._store = Bindable(store)
        self.todo = todo
    }

    static func shouldShowDueDateClearButton(dueDate: Date?) -> Bool {
        dueDate != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let todo {
                Text(todo.title)
                    .font(.headline)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        DatePicker(
                            "Due date",
                            selection: Binding(
                                get: { dueDate },
                                set: { newValue in
                                    dueDate = newValue
                                    store.setDueDate(todoId: todo.id, date: newValue)
                                }
                            ),
                            displayedComponents: [.date]
                        )

                        if Self.shouldShowDueDateClearButton(dueDate: todo.dueDate) {
                            Button("Clear") {
                                store.setDueDate(todoId: todo.id, date: nil)
                            }
                            .buttonStyle(.borderless)
                        }
                    }

                    TextEditor(text: $notesText)
                        .frame(minHeight: 100)
                        .overlay {
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        }
                        .onChange(of: notesText) { _, newValue in
                            store.updateNotesDebounced(todoId: todo.id, notes: newValue)
                        }

                    StepsEditorView(todoId: todo.id, store: store)
                }
                .onAppear {
                    notesText = todo.notes
                    dueDate = todo.dueDate ?? Date()
                }
                .onChange(of: todo.id) { _, _ in
                    notesText = todo.notes
                    dueDate = todo.dueDate ?? Date()
                }
                .onChange(of: todo.notes) { _, newValue in
                    if newValue != notesText {
                        notesText = newValue
                    }
                }
                .onChange(of: todo.dueDate) { _, newValue in
                    if let newValue {
                        dueDate = newValue
                    }
                }
            } else {
                Text("Select a task")
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct StepsEditorView: View {
    let todoId: String
    @Bindable var store: TodoAppStore
    @State private var steps: [TodoStep] = []
    @State private var newStepTitle: String = ""

    init(todoId: String, store: TodoAppStore) {
        self.todoId = todoId
        self._store = Bindable(store)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Steps")
                .font(.subheadline.weight(.semibold))

            HStack(spacing: 8) {
                TextField("Add step", text: $newStepTitle)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(addStep)

                Button("Add", action: addStep)
                    .disabled(newStepTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if steps.isEmpty {
                Text("No steps yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(steps) { step in
                    HStack(spacing: 8) {
                        Button {
                            store.toggleStep(stepId: step.id, isCompleted: !step.isCompleted)
                            reloadSteps()
                        } label: {
                            Image(systemName: step.isCompleted ? "checkmark.circle.fill" : "circle")
                        }
                        .buttonStyle(.plain)

                        Text(step.title)
                            .strikethrough(step.isCompleted)

                        Spacer()

                        Button {
                            store.deleteStep(stepId: step.id)
                            reloadSteps()
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .onAppear(perform: reloadSteps)
        .onChange(of: todoId) { _, _ in
            reloadSteps()
        }
    }

    private func addStep() {
        let trimmedTitle = newStepTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            return
        }
        store.addStep(todoId: todoId, title: trimmedTitle)
        newStepTitle = ""
        reloadSteps()
    }

    private func reloadSteps() {
        steps = store.loadSteps(todoId: todoId)
    }
}
