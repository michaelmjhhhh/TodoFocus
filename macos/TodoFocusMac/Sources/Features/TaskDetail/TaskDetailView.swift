import SwiftUI

struct TaskDetailView: View {
    @Bindable var store: TodoAppStore
    let launchpadService: LaunchpadService
    let todo: Todo?
    let onClose: () -> Void
    @State private var notesText: String = ""
    @State private var dueDate: Date = Date()

    init(store: TodoAppStore, launchpadService: LaunchpadService, todo: Todo?, onClose: @escaping () -> Void) {
        self._store = Bindable(store)
        self.launchpadService = launchpadService
        self.todo = todo
        self.onClose = onClose
    }

    static func shouldShowDueDateClearButton(dueDate: Date?) -> Bool {
        dueDate != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            if let todo {
                header(todo: todo)

                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        section("Schedule") {
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
                                        dueDate = Date()
                                        store.setDueDate(todoId: todo.id, date: nil)
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundStyle(VisualTokens.mutedText)
                                }
                            }
                        }

                        section("Notes") {
                            TextEditor(text: $notesText)
                                .frame(minHeight: 120)
                                .scrollContentBackground(.hidden)
                                .padding(8)
                                .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(VisualTokens.sectionBorder, lineWidth: 1)
                                }
                                .onChange(of: notesText) { _, newValue in
                                    store.updateNotesDebounced(todoId: todo.id, notes: newValue)
                                }
                        }

                        section("Steps") {
                            StepsEditorView(todoId: todo.id, store: store)
                        }

                        section("Launchpad") {
                            LaunchResourceEditorView(
                                store: store,
                                todo: todo,
                                launchpadService: launchpadService
                            )
                        }
                    }
                    .padding(12)
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
                        dueDate = newValue ?? Date()
                    }
                }
            } else {
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(VisualTokens.panelBackground)
        .animation(.spring(response: 0.26, dampingFraction: 0.88), value: todo?.id)
    }

    private func header(todo: Todo) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(todo.title)
                    .font(.headline.weight(.semibold))
                    .lineLimit(2)
                Spacer()
                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.plain)
                .foregroundStyle(VisualTokens.mutedText)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(VisualTokens.sectionBackground)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(VisualTokens.sectionBorder)
                .frame(height: 1)
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(VisualTokens.mutedText)
            content()
        }
        .padding(10)
        .background(VisualTokens.sectionBackground, in: RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(VisualTokens.sectionBorder, lineWidth: 1)
        }
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
