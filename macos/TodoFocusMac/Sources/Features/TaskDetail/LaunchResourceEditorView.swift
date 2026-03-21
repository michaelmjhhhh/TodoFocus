import SwiftUI

struct LaunchResourceEditorView: View {
    @Bindable var store: TodoAppStore
    let todo: Todo
    let launchpadService: LaunchpadService

    @State private var draft: [LaunchResource] = []
    @State private var labelText: String = ""
    @State private var valueText: String = ""
    @State private var selectedType: LaunchResourceType = .url
    @State private var statusText: String?

    init(store: TodoAppStore, todo: Todo, launchpadService: LaunchpadService) {
        self._store = Bindable(store)
        self.todo = todo
        self.launchpadService = launchpadService
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Launch Resources")
                .font(.subheadline.weight(.semibold))

            Picker("Type", selection: $selectedType) {
                Text("URL").tag(LaunchResourceType.url)
                Text("File").tag(LaunchResourceType.file)
                Text("App").tag(LaunchResourceType.app)
            }
            .pickerStyle(.segmented)

            TextField("Label", text: $labelText)
                .textFieldStyle(.roundedBorder)
            TextField("Value", text: $valueText)
                .textFieldStyle(.roundedBorder)

            HStack {
                Button("Add") {
                    addDraftResource()
                }
                .disabled(draft.count >= 12)

                Button("Save") {
                    saveDraft()
                }

                Button("Launch All") {
                    let summary = launchpadService.launchAll(draft)
                    statusText = launchStatusText(summary)
                }
                .disabled(draft.isEmpty)
            }

            if draft.isEmpty {
                Text("No resources")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(draft) { item in
                    HStack {
                        Text(item.label)
                        Spacer()
                        Text(item.type.rawValue)
                            .foregroundStyle(.secondary)
                        Button("Remove") {
                            draft.removeAll(where: { $0.id == item.id })
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }

            if let statusText {
                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear {
            draft = parseLaunchResources(raw: todo.launchResourcesRaw)
        }
        .onChange(of: todo.launchResourcesRaw) { _, newValue in
            draft = parseLaunchResources(raw: newValue)
        }
    }

    private func addDraftResource() {
        let candidate = LaunchResource(
            id: UUID().uuidString,
            type: selectedType,
            label: labelText,
            value: valueText,
            createdAt: Date()
        )
        guard case let .success(valid) = validateLaunchResource(candidate) else {
            statusText = "Invalid resource"
            return
        }
        guard draft.count < 12 else {
            statusText = "Max 12 resources"
            return
        }

        draft.append(valid)
        labelText = ""
        valueText = ""
        statusText = nil
    }

    private func saveDraft() {
        let result = store.saveLaunchResources(todoId: todo.id, items: draft)
        switch result {
        case .success:
            statusText = draft.isEmpty ? "Cleared" : "Saved \(draft.count)"
        case .failure(.launchResourcesTooLarge):
            statusText = "Payload too large"
        case .failure:
            statusText = "Save failed"
        }
    }

    private func launchStatusText(_ summary: LaunchSummary) -> String {
        if summary.results.isEmpty {
            return "No resources"
        }
        if summary.failedCount == 0, summary.rejectedCount == 0 {
            return "Launched \(summary.launchedCount)"
        }
        return "Launched \(summary.launchedCount). \(summary.failedCount + summary.rejectedCount) failed"
    }
}
