import SwiftUI

struct TaskDetailView: View {
    @Bindable var store: TodoAppStore
    let launchpadService: LaunchpadService
    let todo: Todo?
    let onClose: () -> Void
    @State private var notesText: String = ""
    @State private var dueDate: Date = Date()
    @State private var titleText: String = ""
    @State private var titleValidationMessage: String?
    @FocusState private var isTitleFocused: Bool

    init(store: TodoAppStore, launchpadService: LaunchpadService, todo: Todo?, onClose: @escaping () -> Void) {
        self._store = Bindable(store)
        self.launchpadService = launchpadService
        self.todo = todo
        self.onClose = onClose
    }

    static func shouldShowDueDateClearButton(dueDate: Date?) -> Bool {
        dueDate != nil
    }

    static let launchpadHintTitle: String = "Open everything in one action"
    static let launchpadHintSubtitle: String = "Add URL, file, or app resources, then choose Launch All."

    var body: some View {
        VStack(spacing: 0) {
            if let todo {
                header(todo: todo)

                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
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
                            VStack(alignment: .leading, spacing: 2) {
                                Text(Self.launchpadHintTitle)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.primary)
                                Text(Self.launchpadHintSubtitle)
                                    .font(.caption)
                                    .foregroundStyle(VisualTokens.mutedText)
                            }
                            .padding(.bottom, 4)

                            LaunchResourceEditorView(
                                store: store,
                                todo: todo,
                                launchpadService: launchpadService
                            )
                        }
                    }
                    .padding(12)
                    .onAppear {
                        titleText = todo.title
                        notesText = todo.notes
                        dueDate = todo.dueDate ?? Date()
                    }
                    .onChange(of: todo.id) { _, _ in
                        titleText = todo.title
                        titleValidationMessage = nil
                        isTitleFocused = false
                        notesText = todo.notes
                        dueDate = todo.dueDate ?? Date()
                    }
                    .onChange(of: todo.title) { _, newValue in
                        if !isTitleFocused, newValue != titleText {
                            titleText = newValue
                        }
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
        .animation(MotionTokens.panelSpring, value: todo?.id)
        .animation(MotionTokens.focusEase, value: isTitleFocused)
        .animation(MotionTokens.validationEase, value: titleValidationMessage != nil)
    }

    private func header(todo: Todo) -> some View {
        let hasValidationError = titleValidationMessage != nil
        let titleStrokeColor: Color = {
            if hasValidationError {
                return Color.red.opacity(0.70)
            }
            if isTitleFocused {
                return Color.white.opacity(0.26)
            }
            return VisualTokens.sectionBorder.opacity(0.70)
        }()
        let titleStrokeWidth: CGFloat = (hasValidationError || isTitleFocused) ? 1.2 : 1
        let titleGlowOpacity: Double = (isTitleFocused && !hasValidationError) ? 0.10 : 0

        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 6) {
                    TextField("Task title", text: $titleText)
                        .textFieldStyle(.plain)
                        .font(.headline.weight(.semibold))
                        .focused($isTitleFocused)
                        .onSubmit {
                            commitTitle(todoId: todo.id)
                        }
                        .onChange(of: titleText) { _, _ in
                            if titleValidationMessage != nil {
                                titleValidationMessage = nil
                            }
                        }

                    if let titleValidationMessage {
                        Text(titleValidationMessage)
                            .font(.caption)
                            .foregroundStyle(Color.red.opacity(0.92))
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(isTitleFocused ? 0.11 : 0.05))
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(titleStrokeColor, lineWidth: titleStrokeWidth)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(titleGlowOpacity), lineWidth: 4)
                        .blur(radius: 0.4)
                }
                .shadow(color: hasValidationError ? Color.red.opacity(0.16) : .clear, radius: 6)
                .animation(MotionTokens.focusEase, value: isTitleFocused)
                .animation(MotionTokens.validationEase, value: hasValidationError)
                Spacer()
                Button {
                    commitTitle(todoId: todo.id)
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
        .shadow(color: Color.black.opacity(0.14), radius: 8, y: 3)
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
        .padding(12)
        .background(VisualTokens.sectionBackground, in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(VisualTokens.sectionBorder.opacity(0.92), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.10), radius: 5, y: 2)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private func commitTitle(todoId: String) {
        let currentTitle = todo?.title ?? ""
        if titleText == currentTitle {
            return
        }

        switch store.updateTitle(todoId: todoId, title: titleText) {
        case .success:
            titleValidationMessage = nil
        case .failure(.invalidTitle):
            titleValidationMessage = "Title cannot be empty"
            titleText = currentTitle
        case .failure:
            titleValidationMessage = "Could not save title"
            titleText = currentTitle
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
