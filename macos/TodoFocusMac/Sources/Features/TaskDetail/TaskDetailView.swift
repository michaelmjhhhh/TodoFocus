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
    @State private var showDeepFocusSheet = false
    @State private var showFocusReport = false
    @State private var focusReport: DeepFocusReport?
    @State private var selectedBlockedApps: Set<String> = []

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

                if store.deepFocusService.isActive {
                    deepFocusActiveBar
                }

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        dateSection(todo: todo)
                        notesSection(todo: todo)
                        stepsSection(todo: todo)
                        launchpadSection(todo: todo)
                    }
                    .padding(16)
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
        .sheet(isPresented: $showDeepFocusSheet) {
            DeepFocusSetupSheet(
                selectedApps: $selectedBlockedApps,
                onStart: {
                    store.startDeepFocus(blockedApps: Array(selectedBlockedApps))
                    showDeepFocusSheet = false
                },
                onCancel: {
                    showDeepFocusSheet = false
                }
            )
        }
        .sheet(isPresented: $showFocusReport) {
            if let report = focusReport {
                DeepFocusReportView(report: report) {
                    showFocusReport = false
                    focusReport = nil
                }
            }
        }
        .onAppear {
            store.deepFocusService.onEndFocusSession = { report in
                if let report = report {
                    self.focusReport = report
                    self.showFocusReport = true
                }
            }
        }
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
                    showDeepFocusSheet = true
                } label: {
                    Image(systemName: "flame")
                }
                .buttonStyle(.plain)
                .foregroundStyle(VisualTokens.accentTerracotta)

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
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(VisualTokens.sectionBorder)
                .frame(height: 1)
        }
    }

    private func dateSection(todo: Todo) -> some View {
        InlineDatePicker(
            title: "Schedule",
            date: Binding(
                get: { dueDate },
                set: { newValue in
                    dueDate = newValue
                    store.setDueDate(todoId: todo.id, date: newValue)
                }
            ),
            dueDate: todo.dueDate,
            onClear: {
                dueDate = Date()
                store.setDueDate(todoId: todo.id, date: nil)
            }
        )
    }

    private func notesSection(todo: Todo) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(VisualTokens.mutedText)

            TextEditor(text: $notesText)
                .frame(minHeight: 100)
                .scrollContentBackground(.hidden)
                .padding(10)
                .background(VisualTokens.bgFloating, in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(VisualTokens.textPrimary)
                .onChange(of: notesText) { _, newValue in
                    store.updateNotesDebounced(todoId: todo.id, notes: newValue)
                }
        }
    }

    private func stepsSection(todo: Todo) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Steps")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(VisualTokens.mutedText)

            StepsEditorView(todoId: todo.id, store: store)
        }
    }

    private func launchpadSection(todo: Todo) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Launchpad")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(VisualTokens.mutedText)

            Text(Self.launchpadHintTitle)
                .font(.caption)
                .foregroundStyle(VisualTokens.textSecondary)

            LaunchResourceEditorView(
                store: store,
                todo: todo,
                launchpadService: launchpadService
            )
        }
    }

    private var deepFocusActiveBar: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(VisualTokens.accentTerracotta.opacity(0.2))
                    .frame(width: 32, height: 32)
                Image(systemName: "flame.fill")
                    .foregroundColor(VisualTokens.accentTerracotta)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Deep Focus Active")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(VisualTokens.textPrimary)
                Text("Blocking \(store.deepFocusService.blockedApps.count) apps")
                    .font(.caption)
                    .foregroundColor(VisualTokens.textSecondary)
            }
            
            Spacer()
            
            Button {
                if let report = store.endDeepFocus() {
                    focusReport = report
                    showFocusReport = true
                }
            } label: {
                Text("End Focus")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(VisualTokens.accentTerracotta, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(VisualTokens.accentTerracotta.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(VisualTokens.accentTerracotta.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
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

struct InlineDatePicker: View {
    let title: String
    @Binding var date: Date
    let dueDate: Date?
    let onClear: () -> Void
    @State private var isPickerPresented = false

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        if let dueDate, Calendar.current.isDateInToday(dueDate) {
            return "Today"
        } else if let dueDate, Calendar.current.isDateInTomorrow(dueDate) {
            return "Tomorrow"
        }
        return formatter.string(from: dueDate ?? date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(VisualTokens.mutedText)

            HStack(spacing: 8) {
                Button {
                    isPickerPresented = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .foregroundStyle(VisualTokens.accentTerracotta)
                        Text(formattedDate)
                            .foregroundStyle(VisualTokens.textPrimary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(VisualTokens.bgFloating, in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .popover(isPresented: $isPickerPresented, arrowEdge: .top) {
                    VStack(spacing: 0) {
                        DatePicker(
                            "",
                            selection: $date,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.graphical)
                        .padding(12)
                        .onChange(of: date) { _, newValue in
                            isPickerPresented = false
                        }

                        if dueDate != nil {
                            Divider()
                                .padding(.horizontal, 8)
                            Button("Clear date") {
                                onClear()
                                isPickerPresented = false
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(VisualTokens.danger)
                            .padding(12)
                        }
                    }
                    .background(VisualTokens.bgElevated)
                }

                Spacer()
            }
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
            HStack(spacing: 8) {
                TextField("Add a step", text: $newStepTitle)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(VisualTokens.bgFloating, in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(VisualTokens.textPrimary)
                    .onSubmit(addStep)

                Button("Add") {
                    addStep()
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(VisualTokens.accentTerracotta, in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(.white)
                .opacity(newStepTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
                .disabled(newStepTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if steps.isEmpty {
                Text("No steps yet")
                    .font(.caption)
                    .foregroundStyle(VisualTokens.textTertiary)
                    .padding(.top, 4)
            } else {
                VStack(spacing: 4) {
                    ForEach(steps) { step in
                        stepRow(step: step)
                    }
                }
            }
        }
        .onAppear(perform: reloadSteps)
        .onChange(of: todoId) { _, _ in
            reloadSteps()
        }
    }

    private func stepRow(step: TodoStep) -> some View {
        HStack(spacing: 10) {
            Button {
                store.toggleStep(stepId: step.id, isCompleted: !step.isCompleted)
                reloadSteps()
            } label: {
                Image(systemName: step.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(step.isCompleted ? VisualTokens.success : VisualTokens.textTertiary)
            }
            .buttonStyle(.plain)

            Text(step.title)
                .foregroundStyle(step.isCompleted ? VisualTokens.textTertiary : VisualTokens.textPrimary)
                .strikethrough(step.isCompleted)

            Spacer()

            Button {
                store.deleteStep(stepId: step.id)
                reloadSteps()
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(VisualTokens.textTertiary)
                    .font(.caption)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(VisualTokens.bgFloating.opacity(0.5), in: RoundedRectangle(cornerRadius: 6))
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

struct DeepFocusSetupSheet: View {
    @Binding var selectedApps: Set<String>
    let onStart: () -> Void
    let onCancel: () -> Void

    private let availableApps: [(name: String, bundleId: String)] = [
        ("Messages", "com.apple.MobileSMS"),
        ("Safari", "com.apple.Safari"),
        ("Chrome", "com.google.Chrome"),
        ("Mail", "com.apple.mail"),
        ("Twitter/X", "com.twitter.twitter-mac"),
        ("Slack", "com.tinyspeck.slackmacgap"),
        ("Discord", "com.hnc.Discord"),
        ("Spotify", "com.spotify.client")
    ]

    var body: some View {
        VStack(spacing: 20) {
            Text("Start Deep Focus")
                .font(.headline)
                .padding(.top, 20)

            Text("Select apps to block during focus session")
                .font(.subheadline)
                .foregroundStyle(VisualTokens.textSecondary)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(availableApps, id: \.bundleId) { app in
                    HStack {
                        Image(systemName: selectedApps.contains(app.bundleId) ? "checkmark.square.fill" : "square")
                            .foregroundStyle(selectedApps.contains(app.bundleId) ? VisualTokens.accentTerracotta : VisualTokens.textTertiary)
                            .onTapGesture {
                                if selectedApps.contains(app.bundleId) {
                                    selectedApps.remove(app.bundleId)
                                } else {
                                    selectedApps.insert(app.bundleId)
                                }
                            }

                        Text(app.name)
                            .foregroundStyle(VisualTokens.textPrimary)

                        Spacer()
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selectedApps.contains(app.bundleId) {
                            selectedApps.remove(app.bundleId)
                        } else {
                            selectedApps.insert(app.bundleId)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)

            HStack(spacing: 12) {
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(VisualTokens.bgFloating, in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(VisualTokens.textPrimary)

                Button("Start") {
                    onStart()
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(VisualTokens.accentTerracotta, in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(.white)
            }
            .padding(.bottom, 20)
        }
        .frame(width: 300)
        .background(VisualTokens.panelBackground)
    }
}
