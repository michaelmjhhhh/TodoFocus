import SwiftUI

struct TaskDetailView: View {
    @Bindable var store: TodoAppStore
    let launchpadService: LaunchpadService
    let todo: Todo?
    let onClose: () -> Void
    @Environment(\.themeTokens) private var tokens
    @State private var notesText: String = ""
    @State private var dueDate: Date = Date()
    @State private var titleText: String = ""
    @State private var titleValidationMessage: String?
    @FocusState private var isTitleFocused: Bool
    @FocusState private var isNotesFocused: Bool
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
                        if todo.focusTimeSeconds > 0 {
                            focusTimeSection(todo: todo)
                        }
                        notesSection(todo: todo)
                        stepsSection(todo: todo)
                        launchpadSection(todo: todo)
                    }
                    .padding(.horizontal, SpacingTokens.lg)
                    .padding(.vertical, SpacingTokens.lg)
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
                .overlay(alignment: .top) {
                    LinearGradient(
                        colors: [
                            tokens.sectionBorder.opacity(0.45),
                            tokens.sectionBorder.opacity(0.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: SpacingTokens.md)
                    .padding(.horizontal, SpacingTokens.lg)
                    .allowsHitTesting(false)
                }
            } else {
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(tokens.panelBackground)
        .animation(MotionTokens.panelSpring, value: todo?.id)
        .animation(MotionTokens.focusEase, value: isTitleFocused)
        .animation(MotionTokens.validationEase, value: titleValidationMessage != nil)
        .sheet(isPresented: $showDeepFocusSheet) {
            DeepFocusSetupSheet(
                selectedApps: $selectedBlockedApps,
                onStart: { duration, passphrase in
                    if let focusTaskId = todo?.id {
                        store.startDeepFocus(blockedApps: Array(selectedBlockedApps), duration: duration, focusTaskId: focusTaskId, passphrase: passphrase)
                    }
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
        .onDisappear {
            store.deepFocusService.onEndFocusSession = nil
        }
    }

    private func header(todo: Todo) -> some View {
        let hasValidationError = titleValidationMessage != nil
        let titleStrokeColor: Color = {
            if hasValidationError {
                return tokens.danger.opacity(0.70)
            }
            if isTitleFocused {
                return tokens.inputBorderFocused
            }
            return Color.clear
        }()
        let titleStrokeWidth: CGFloat = (hasValidationError || isTitleFocused) ? 1.2 : 0
        let titleGlowOpacity: Double = (isTitleFocused && !hasValidationError) ? 0.52 : 0

        return VStack(alignment: .leading, spacing: SpacingTokens.sm) {
            HStack(spacing: SpacingTokens.sm) {
                VStack(alignment: .leading, spacing: SpacingTokens.sm) {
                    TextField("Task title", text: $titleText)
                        .textFieldStyle(.plain)
                        .font(TypographyTokens.displaySmall)
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
                            .font(TypographyTokens.caption)
                            .foregroundStyle(tokens.danger.opacity(0.92))
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(.horizontal, SpacingTokens.md)
                .padding(.vertical, SpacingTokens.sm)
                .background(
                    RoundedRectangle(cornerRadius: RadiusTokens.md)
                        .fill(isTitleFocused ? tokens.inputSurface : Color.clear)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: RadiusTokens.md)
                        .stroke(titleStrokeColor, lineWidth: titleStrokeWidth)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: RadiusTokens.md)
                        .stroke(tokens.inputGlow.opacity(titleGlowOpacity), lineWidth: 4)
                        .blur(radius: 0.7)
                }
                .shadow(color: hasValidationError ? tokens.danger.opacity(0.16) : .clear, radius: 6)
                .animation(MotionTokens.focusEase, value: isTitleFocused)
                .animation(MotionTokens.validationEase, value: hasValidationError)
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: SpacingTokens.md) {
                    Button {
                        showDeepFocusSheet = true
                    } label: {
                        HStack(spacing: SpacingTokens.sm) {
                            Image(systemName: "flame.fill")
                            Text(store.deepFocusService.isActive ? "Focus Running" : "Deep Focus")
                                .font(TypographyTokens.headingSmall)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, SpacingTokens.md)
                        .padding(.vertical, SpacingTokens.sm)
                        .background(
                            store.deepFocusService.isActive
                                ? tokens.textTertiary
                                : tokens.accentTerracotta,
                            in: Capsule()
                        )
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut("f", modifiers: [.command, .shift])
                    .disabled(store.deepFocusService.isActive)

                    Button {
                        commitTitle(todoId: todo.id)
                        onClose()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(tokens.mutedText)
                    .accessibilityLabel("Close detail")
                    .help("Close detail")
                }
                .padding(.horizontal, SpacingTokens.sm)
                .padding(.vertical, SpacingTokens.xs)
                .background(
                    RoundedRectangle(cornerRadius: RadiusTokens.md, style: .continuous)
                        .fill(isTitleFocused ? tokens.inputSurface : Color.clear)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: RadiusTokens.md, style: .continuous)
                        .stroke(titleStrokeColor, lineWidth: titleStrokeWidth)
                }
                .animation(MotionTokens.focusEase, value: isTitleFocused)
            }
        }
        .padding(.horizontal, SpacingTokens.lg)
        .padding(.top, SpacingTokens.xl - SpacingTokens.xs)
        .padding(.bottom, SpacingTokens.md)
        .background(tokens.sectionBackground)
        .overlay(alignment: .bottom) {
            LinearGradient(
                colors: [
                    tokens.sectionBorder.opacity(0.0),
                    tokens.sectionBorder.opacity(0.75)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 8)
            .allowsHitTesting(false)
        }
    }

    private func dateSection(todo: Todo) -> some View {
        InlineDatePicker(
            title: "Schedule",
            date: Binding(
                get: { dueDate },
                set: { newValue in
                    dueDate = newValue
                    try? store.setDueDate(todoId: todo.id, date: newValue)
                }
            ),
            dueDate: todo.dueDate,
            onClear: {
                dueDate = Date()
                try? store.setDueDate(todoId: todo.id, date: nil)
            }
        )
    }

    private func focusTimeSection(todo: Todo) -> some View {
        VStack(alignment: .leading, spacing: SpacingTokens.sm) {
            Text("Focus Time")
                .font(TypographyTokens.micro)
                .textCase(.uppercase)
                .tracking(1.5)
                .foregroundStyle(tokens.textTertiary)

            HStack(spacing: SpacingTokens.sm) {
                Image(systemName: "clock.fill")
                    .foregroundStyle(tokens.accentTerracotta)
                    .font(TypographyTokens.bodyLarge)

                Spacer()

                Text(store.formatFocusTime(todo.focusTimeSeconds))
                    .font(TypographyTokens.headingLarge)
                    .foregroundStyle(tokens.textPrimary)
            }
            .padding(.horizontal, SpacingTokens.lg)
            .padding(.vertical, SpacingTokens.md)
            .background(tokens.bgElevated, in: RoundedRectangle(cornerRadius: RadiusTokens.sm))
        }
    }

    private func notesSection(todo: Todo) -> some View {
        VStack(alignment: .leading, spacing: SpacingTokens.sm) {
            Text("Notes")
                .font(TypographyTokens.micro)
                .textCase(.uppercase)
                .tracking(1.5)
                .foregroundStyle(tokens.textTertiary)

            ZStack(alignment: .topLeading) {
                if notesText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Capture thoughts, context, and follow-ups...")
                        .font(TypographyTokens.bodyLarge)
                        .foregroundStyle(tokens.textTertiary.opacity(0.7))
                        .padding(.horizontal, SpacingTokens.lg)
                        .padding(.vertical, SpacingTokens.lg)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $notesText)
                    .focused($isNotesFocused)
                    .font(TypographyTokens.bodyLarge)
                    .frame(height: 140)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, SpacingTokens.lg)
                    .padding(.vertical, SpacingTokens.md)
                    .foregroundStyle(tokens.textPrimary)
                    .onChange(of: notesText) { _, newValue in
                        store.updateNotesDebounced(todoId: todo.id, notes: newValue)
                    }
            }
            .background(
                isNotesFocused ? tokens.inputSurface : tokens.bgFloating.opacity(0.3),
                in: RoundedRectangle(cornerRadius: RadiusTokens.md, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: RadiusTokens.md, style: .continuous)
                    .stroke(
                        isNotesFocused ? tokens.inputBorderFocused : tokens.sectionBorder.opacity(0.4),
                        lineWidth: isNotesFocused ? 1.2 : 0.5
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: RadiusTokens.md, style: .continuous)
                    .stroke(tokens.inputGlow.opacity(isNotesFocused ? 0.52 : 0), lineWidth: 4)
                    .blur(radius: 0.7)
            }
            .clipShape(RoundedRectangle(cornerRadius: RadiusTokens.md, style: .continuous))
            .animation(MotionTokens.focusEase, value: isNotesFocused)
        }
    }

    private func stepsSection(todo: Todo) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Steps")
                .font(TypographyTokens.micro)
                .textCase(.uppercase)
                .tracking(1.5)
                .foregroundStyle(tokens.textTertiary)

            StepsEditorView(todoId: todo.id, store: store)
        }
    }

    private func launchpadSection(todo: Todo) -> some View {
        LaunchResourceEditorView(
            store: store,
            todo: todo,
            launchpadService: launchpadService
        )
    }

    private var deepFocusActiveBar: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(tokens.accentTerracotta.opacity(0.2))
                    .frame(width: 32, height: 32)
                Image(systemName: "flame.fill")
                    .foregroundColor(tokens.accentTerracotta)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Deep Focus Active")
                    .font(TypographyTokens.headingSmall)
                    .foregroundColor(tokens.textPrimary)
                Text("Blocking \(store.deepFocusService.blockedApps.count) apps")
                    .font(TypographyTokens.caption)
                    .foregroundColor(tokens.textSecondary)
                Text("Unlock from the top Hard Focus bar")
                    .font(TypographyTokens.micro)
                    .foregroundColor(tokens.textSecondary.opacity(0.9))
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(tokens.accentTerracotta.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(tokens.accentTerracotta.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func commitTitle(todoId: String) {
        let currentTitle = todo?.title ?? ""
        if titleText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            titleValidationMessage = "Title cannot be empty"
            titleText = currentTitle
            return
        }

        if titleText == currentTitle {
            titleValidationMessage = nil
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
    @Environment(\.themeTokens) private var tokens

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
        VStack(alignment: .leading, spacing: SpacingTokens.sm) {
            Text(title)
                .font(TypographyTokens.micro)
                .textCase(.uppercase)
                .tracking(1.5)
                .foregroundStyle(tokens.textTertiary)

            HStack(spacing: SpacingTokens.sm) {
                Button {
                    isPickerPresented = true
                } label: {
                    HStack(spacing: SpacingTokens.sm) {
                        Image(systemName: "calendar")
                            .foregroundStyle(tokens.accentTerracotta)
                        Text(formattedDate)
                            .font(TypographyTokens.bodySmall)
                            .foregroundStyle(tokens.textPrimary)
                    }
                    .padding(.horizontal, SpacingTokens.md)
                    .padding(.vertical, SpacingTokens.sm)
                    .background(tokens.bgFloating, in: RoundedRectangle(cornerRadius: RadiusTokens.sm))
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
                        .padding(SpacingTokens.md)
                        .onChange(of: date) { _, newValue in
                            isPickerPresented = false
                        }

                        if dueDate != nil {
                            Divider()
                                .padding(.horizontal, SpacingTokens.sm)
                            Button("Clear date") {
                                onClear()
                                isPickerPresented = false
                            }
                            .buttonStyle(.plain)
                            .font(TypographyTokens.bodySmall)
                            .foregroundStyle(tokens.danger)
                            .padding(SpacingTokens.md)
                        }
                    }
                    .background(tokens.bgElevated)
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
    @State private var stepErrorMessage: String?
    @Environment(\.themeTokens) private var tokens

    init(todoId: String, store: TodoAppStore) {
        self.todoId = todoId
        self._store = Bindable(store)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 0) {
                TextField("Add a step", text: $newStepTitle)
                    .textFieldStyle(.plain)
                    .font(TypographyTokens.bodySmall)
                    .padding(.horizontal, SpacingTokens.md)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(tokens.textPrimary)
                    .onSubmit(addStep)

                Button("Add") {
                    addStep()
                }
                .buttonStyle(.plain)
                .font(TypographyTokens.caption)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .foregroundStyle(newStepTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? tokens.textTertiary : tokens.accentTerracotta)
                .disabled(newStepTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .background(tokens.bgFloating.opacity(0.5), in: RoundedRectangle(cornerRadius: RadiusTokens.md))
            .overlay {
                RoundedRectangle(cornerRadius: RadiusTokens.md)
                    .stroke(tokens.sectionBorder.opacity(0.4), lineWidth: 0.5)
            }
            .clipShape(RoundedRectangle(cornerRadius: RadiusTokens.md))

            if let stepErrorMessage {
                Text(stepErrorMessage)
                    .font(TypographyTokens.caption)
                    .foregroundStyle(tokens.danger)
            }

            if steps.isEmpty {
                Text("No steps yet")
                    .font(TypographyTokens.caption)
                    .foregroundStyle(tokens.textTertiary)
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
                    .font(TypographyTokens.bodyLarge)
                    .frame(width: 24, height: 24)
                    .foregroundStyle(step.isCompleted ? tokens.success : tokens.accentTerracotta.opacity(0.6))
            }
            .buttonStyle(.plain)

            Text(step.title)
                .font(TypographyTokens.bodySmall)
                .lineLimit(2)
                .foregroundStyle(step.isCompleted ? tokens.textTertiary : tokens.textPrimary)
                .strikethrough(step.isCompleted)
                .opacity(step.isCompleted ? 0.5 : 1)

            Spacer()

            Button {
                store.deleteStep(stepId: step.id)
                reloadSteps()
            } label: {
                Image(systemName: "trash")
                    .font(TypographyTokens.caption)
                    .foregroundStyle(tokens.textTertiary)
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delete step")
            .help("Delete step")
        }
        .padding(.vertical, SpacingTokens.sm)
        .padding(.horizontal, SpacingTokens.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tokens.bgFloating.opacity(0.4), in: RoundedRectangle(cornerRadius: RadiusTokens.sm))
    }

    private func addStep() {
        let trimmedTitle = newStepTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            return
        }
        do {
            try store.addStep(todoId: todoId, title: trimmedTitle)
            newStepTitle = ""
            stepErrorMessage = nil
            reloadSteps()
        } catch {
            stepErrorMessage = "Failed to add step. Please try again."
        }
    }

    private func reloadSteps() {
        steps = store.loadSteps(todoId: todoId)
    }
}

struct DeepFocusSetupSheet: View {
    @Binding var selectedApps: Set<String>
    let onStart: (TimeInterval?, String) -> Void
    let onCancel: () -> Void
    @State private var customApps: [(name: String, bundleId: String)] = []
    @State private var isTimedMode: Bool = true
    @State private var minutes: Int = 25
    @State private var passphrase: String = ""
    @State private var templateStore = DeepFocusTemplateStore()
    @State private var isCreatingTemplate: Bool = false
    @State private var newTemplateName: String = ""
    @State private var renamingTemplateID: String?
    @State private var renameTemplateName: String = ""
    @FocusState private var isPassphraseFocused: Bool
    @Environment(\.themeTokens) private var tokens

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

    private func getBundleIdentifier(from appURL: URL) -> String? {
        if let bundle = Bundle(url: appURL),
           let bundleId = bundle.bundleIdentifier {
            return bundleId
        }
        return appURL.deletingPathExtension().lastPathComponent
    }

    private func addCustomApp() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.message = "Select an app to block"

        if panel.runModal() == .OK, let url = panel.url {
            if let bundleId = getBundleIdentifier(from: url) {
                let name = url.deletingPathExtension().lastPathComponent
                if !customApps.contains(where: { $0.bundleId == bundleId }) && !availableApps.contains(where: { $0.bundleId == bundleId }) {
                    customApps.append((name: name, bundleId: bundleId))
                }
            }
        }
    }

    private func addMissingCustomApps(for bundleIDs: [String]) {
        let known = Set((availableApps + customApps).map(\.bundleId))
        for bundleID in bundleIDs where !known.contains(bundleID) {
            let fallbackName = bundleID.components(separatedBy: ".").last?.capitalized ?? bundleID
            customApps.append((name: fallbackName, bundleId: bundleID))
        }
    }

    private func applyTemplate(_ template: DeepFocusSessionTemplate) {
        selectedApps = Set(template.blockedApps)
        addMissingCustomApps(for: template.blockedApps)
        if let duration = template.durationMinutes {
            isTimedMode = true
            minutes = max(1, min(480, duration))
        } else {
            isTimedMode = false
        }
    }

    private func startFromTemplate(_ template: DeepFocusSessionTemplate) {
        let trimmed = passphrase.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            isPassphraseFocused = true
            return
        }
        applyTemplate(template)
        let duration = template.durationMinutes.map { TimeInterval($0 * 60) }
        onStart(duration, trimmed)
    }

    private func saveCurrentAsTemplate() {
        let trimmed = newTemplateName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = templateStore.createTemplate(
            name: trimmed,
            durationMinutes: isTimedMode ? minutes : nil,
            blockedApps: Array(selectedApps)
        )
        newTemplateName = ""
        isCreatingTemplate = false
    }

    private var templateSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Templates")
                    .font(TypographyTokens.micro)
                    .textCase(.uppercase)
                    .tracking(1.5)
                    .foregroundStyle(tokens.textTertiary)
                Spacer()
                Button {
                    isCreatingTemplate.toggle()
                    if !isCreatingTemplate {
                        newTemplateName = ""
                    }
                } label: {
                    Label("Save Current", systemImage: "plus")
                        .font(TypographyTokens.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(tokens.accentTerracotta)
            }

            if isCreatingTemplate {
                HStack(spacing: 8) {
                    TextField("Template name", text: $newTemplateName)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(tokens.bgFloating, in: RoundedRectangle(cornerRadius: 10))
                        .overlay {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(tokens.sectionBorder, lineWidth: 1)
                        }

                    Button("Save") { saveCurrentAsTemplate() }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(tokens.accentTerracotta, in: RoundedRectangle(cornerRadius: 8))
                        .foregroundStyle(.white)

                    Button("Cancel") {
                        isCreatingTemplate = false
                        newTemplateName = ""
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(tokens.textSecondary)
                }
            }

            if let renamingTemplateID {
                HStack(spacing: 8) {
                    TextField("Rename template", text: $renameTemplateName)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(tokens.bgFloating, in: RoundedRectangle(cornerRadius: 10))
                        .overlay {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(tokens.sectionBorder, lineWidth: 1)
                        }
                    Button("Apply") {
                        templateStore.renameTemplate(id: renamingTemplateID, name: renameTemplateName)
                        self.renamingTemplateID = nil
                        renameTemplateName = ""
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(tokens.accentTerracotta)
                    Button("Cancel") {
                        self.renamingTemplateID = nil
                        renameTemplateName = ""
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(tokens.textSecondary)
                }
            }

            if templateStore.templates.isEmpty {
                Text("No templates yet")
                    .font(TypographyTokens.caption)
                    .foregroundStyle(tokens.textSecondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(templateStore.templates) { template in
                            HStack(spacing: 6) {
                                Button {
                                    applyTemplate(template)
                                } label: {
                                    Text(template.name)
                                        .font(TypographyTokens.caption)
                                        .lineLimit(1)
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(tokens.textPrimary)

                                Button {
                                    startFromTemplate(template)
                                } label: {
                                    Image(systemName: "play.fill")
                                        .font(TypographyTokens.micro)
                                        .frame(width: 28, height: 28)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(tokens.accentTerracotta)
                                .help("Start with this template")
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(tokens.bgFloating, in: Capsule())
                            .overlay {
                                Capsule()
                                    .stroke(tokens.sectionBorder, lineWidth: 1)
                            }
                            .contextMenu {
                                Button("Rename") {
                                    renamingTemplateID = template.id
                                    renameTemplateName = template.name
                                }
                                Button("Delete", role: .destructive) {
                                    templateStore.deleteTemplate(id: template.id)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }

    var body: some View {
            VStack(spacing: 20) {
            Text("Start Hard Focus")
                .font(TypographyTokens.displaySmall)
                .padding(.top, 20)

            // Timer Mode Picker
            VStack(spacing: 12) {
                Picker("Focus Mode", selection: $isTimedMode) {
                    Text("Timed").tag(true)
                    Text("Infinite").tag(false)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)

                if isTimedMode {
                    VStack(spacing: 16) {
                        // Duration display with stepper
                        HStack(spacing: 16) {
                            Button {
                                minutes = max(1, minutes - 5)
                            } label: {
                                Image(systemName: "minus")
                                    .font(TypographyTokens.caption)
                                    .frame(width: 28, height: 28)
                                    .background(tokens.bgSubtle)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(minutes > 1 ? tokens.textPrimary : tokens.textTertiary)

                            VStack(spacing: 2) {
                                Text("\(minutes)")
                                    .font(TypographyTokens.displayLarge)
                                    .foregroundStyle(tokens.textPrimary)
                                    .monospacedDigit()
                                Text("minutes")
                                    .font(TypographyTokens.micro)
                                    .foregroundStyle(tokens.textSecondary)
                            }
                            .frame(minWidth: 80)

                            Button {
                                if minutes < 480 {
                                    minutes += 5
                                }
                            } label: {
                                Image(systemName: "plus")
                                    .font(TypographyTokens.caption)
                                    .frame(width: 28, height: 28)
                                    .background(tokens.bgSubtle)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(minutes < 480 ? tokens.textPrimary : tokens.textTertiary)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(tokens.bgFloating.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(tokens.textTertiary.opacity(0.15), lineWidth: 1)
                        )

                        // Quick preset chips
                        HStack(spacing: 8) {
                            ForEach([25, 45, 60, 90], id: \.self) { preset in
                                Button {
                                    minutes = preset
                                } label: {
                                    Text("\(preset)m")
                                        .font(TypographyTokens.caption)
                                        .foregroundStyle(minutes == preset ? .white : tokens.textSecondary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            minutes == preset
                                                ? tokens.accentTerracotta
                                                : tokens.bgFloating,
                                            in: Capsule()
                                        )
                                        .overlay(
                                            Capsule()
                                                .stroke(
                                                    minutes == preset
                                                        ? Color.clear
                                                        : tokens.textTertiary.opacity(0.2),
                                                    lineWidth: 1
                                                )
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                } else {
                    Text("Session runs until you manually end it")
                        .font(TypographyTokens.caption)
                        .foregroundStyle(tokens.textSecondary)
                        .padding(.horizontal, 20)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isTimedMode)

            templateSection

            VStack(alignment: .leading, spacing: SpacingTokens.md) {
                Text("Blocked Apps")
                    .font(TypographyTokens.micro)
                    .textCase(.uppercase)
                    .tracking(1.5)
                    .foregroundStyle(tokens.textTertiary)
                    .padding(.horizontal, 20)

                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(availableApps, id: \.bundleId) { app in
                            appRow(name: app.name, bundleId: app.bundleId)
                        }

                        if !customApps.isEmpty {
                            Rectangle()
                                .fill(tokens.sectionBorder.opacity(0.3))
                                .frame(height: 0.5)
                                .padding(.vertical, SpacingTokens.xs)
                                .padding(.horizontal, SpacingTokens.md)

                            ForEach(customApps, id: \.bundleId) { app in
                                appRow(name: app.name, bundleId: app.bundleId)
                                    .contextMenu {
                                        Button("Remove") {
                                            customApps.removeAll { $0.bundleId == app.bundleId }
                                            selectedApps.remove(app.bundleId)
                                        }
                                    }
                            }
                        }

                        Button {
                            addCustomApp()
                        } label: {
                            HStack(spacing: SpacingTokens.sm) {
                                Image(systemName: "plus")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(tokens.accentTerracotta)
                                    .frame(width: 18, height: 18)
                                    .background(tokens.accentTerracotta.opacity(0.12), in: Circle())
                                Text("Add Custom App")
                                    .font(TypographyTokens.caption)
                                    .foregroundStyle(tokens.textSecondary)
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.vertical, SpacingTokens.sm)
                        .padding(.horizontal, SpacingTokens.md)
                    }
                    .padding(.vertical, SpacingTokens.xs)
                }
                .frame(maxHeight: 280)
                .background(tokens.bgFloating.opacity(0.35), in: RoundedRectangle(cornerRadius: RadiusTokens.md))
                .overlay {
                    RoundedRectangle(cornerRadius: RadiusTokens.md)
                        .stroke(tokens.sectionBorder.opacity(0.3), lineWidth: 0.5)
                }
                .padding(.horizontal, 20)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Unlock Passphrase")
                    .font(TypographyTokens.micro)
                    .textCase(.uppercase)
                    .tracking(1.5)
                    .foregroundStyle(tokens.textTertiary)
                SecureField("Enter a passphrase to unlock later", text: $passphrase)
                    .textFieldStyle(.plain)
                    .focused($isPassphraseFocused)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .foregroundStyle(tokens.textPrimary)
                    .background(tokens.bgFloating, in: RoundedRectangle(cornerRadius: 10))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                isPassphraseFocused
                                    ? tokens.accentTerracotta.opacity(0.6)
                                    : tokens.sectionBorder,
                                lineWidth: isPassphraseFocused ? 1.25 : 1
                            )
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(tokens.accentTerracotta.opacity(isPassphraseFocused ? 0.14 : 0), lineWidth: 4)
                            .blur(radius: 0.6)
                    }
                    .shadow(color: isPassphraseFocused ? tokens.accentTerracotta.opacity(0.08) : .clear, radius: 8, y: 1)
                    .animation(MotionTokens.focusEase, value: isPassphraseFocused)
            }
            .padding(.horizontal, 20)

            HStack(spacing: SpacingTokens.md) {
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.plain)
                .font(TypographyTokens.bodySmall)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(tokens.bgFloating, in: RoundedRectangle(cornerRadius: RadiusTokens.sm))
                .overlay {
                    RoundedRectangle(cornerRadius: RadiusTokens.sm)
                        .stroke(tokens.sectionBorder.opacity(0.4), lineWidth: 0.5)
                }
                .foregroundStyle(tokens.textPrimary)

                Button {
                    let trimmed = passphrase.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    let duration: TimeInterval? = isTimedMode ? TimeInterval(minutes * 60) : nil
                    onStart(duration, trimmed)
                } label: {
                    Text("Start")
                        .font(TypographyTokens.headingSmall)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(tokens.accentTerracotta, in: RoundedRectangle(cornerRadius: RadiusTokens.sm))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(width: 300)
        .background(tokens.panelBackground)
    }

    private func appRow(name: String, bundleId: String) -> some View {
        let isSelected = selectedApps.contains(bundleId)
        return HStack(spacing: SpacingTokens.md) {
            ZStack {
                Circle()
                    .stroke(isSelected ? tokens.accentTerracotta : tokens.textTertiary.opacity(0.5), lineWidth: 1)
                    .frame(width: 18, height: 18)

                if isSelected {
                    Circle()
                        .fill(tokens.accentTerracotta)
                        .frame(width: 18, height: 18)

                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .animation(MotionTokens.checkboxSpring, value: isSelected)

            Text(name)
                .font(TypographyTokens.bodySmall)
                .foregroundStyle(isSelected ? tokens.textPrimary : tokens.textSecondary)

            Spacer()
        }
        .padding(.vertical, SpacingTokens.sm)
        .padding(.horizontal, SpacingTokens.md)
        .contentShape(Rectangle())
        .onTapGesture {
            if isSelected {
                selectedApps.remove(bundleId)
            } else {
                selectedApps.insert(bundleId)
            }
        }
    }
}
