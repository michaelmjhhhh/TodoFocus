import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct LaunchResourceEditorView: View {
    @Bindable var store: TodoAppStore
    let todo: Todo
    let launchpadService: LaunchpadService
    @Environment(\.themeTokens) private var tokens

    @State private var draft: [LaunchResource] = []
    @State private var labelText: String = ""
    @State private var valueText: String = ""
    @State private var selectedType: LaunchResourceType = .url
    @State private var statusText: String?
    @State private var isAdding: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerRow

            if isAdding {
                addResourceForm
            } else if draft.isEmpty {
                emptyState
            } else {
                resourceList
            }
        }
        .onAppear {
            draft = parseLaunchResources(raw: todo.launchResourcesRaw)
        }
        .onChange(of: todo.launchResourcesRaw) { _, newValue in
            draft = parseLaunchResources(raw: newValue)
        }
    }

    private var headerRow: some View {
        HStack {
            Text("Launchpad")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tokens.mutedText)

            Spacer()

            if !draft.isEmpty {
                Button {
                    launchAll()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "rocket.fill")
                            .font(.system(size: 11))
                        Text("Launch All")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(tokens.accentTerracotta, in: Capsule())
                }
                .buttonStyle(.plain)
            }

            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    isAdding = true
                }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(tokens.accentTerracotta)
                    .frame(width: 30, height: 30)
                    .background(tokens.bgFloating.opacity(0.9), in: Circle())
                    .overlay {
                        Circle()
                            .stroke(tokens.sectionBorder.opacity(0.9), lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .disabled(draft.count >= 12)
            .opacity(draft.count >= 12 ? 0.5 : 1)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "link")
                .font(.system(size: 24))
                .foregroundStyle(tokens.textTertiary)

            Text("No resources yet")
                .font(.caption)
                .foregroundStyle(tokens.textTertiary)

            Text("Add URLs, files, or apps to launch from this task")
                .font(.caption2)
                .foregroundStyle(tokens.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private var addResourceForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                ForEach(LaunchResourceType.allCases) { type in
                    typeButton(type)
                }
            }

            TextField("Label", text: $labelText)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(tokens.inputSurface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(tokens.inputBorder, lineWidth: 1)
                }

            TextField(typePlaceholder, text: $valueText)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(tokens.inputSurface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(tokens.inputBorder, lineWidth: 1)
                }

            if selectedType != .url {
                Button("Choose \(selectedType == .file ? "File" : "App")") {
                    if selectedType == .file {
                        pickFile()
                    } else {
                        pickApp()
                    }
                }
                .buttonStyle(.plain)
                .font(.caption.weight(.semibold))
                .foregroundStyle(tokens.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(tokens.bgFloating.opacity(0.8), in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(tokens.sectionBorder.opacity(0.9), lineWidth: 1)
                }
            }

            HStack(spacing: 8) {
                Button("Cancel") {
                    cancelAdd()
                }
                .buttonStyle(.plain)
                .font(.caption.weight(.semibold))
                .foregroundStyle(tokens.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(tokens.bgFloating.opacity(0.8), in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(tokens.sectionBorder.opacity(0.9), lineWidth: 1)
                }

                Spacer()

                Button("Add") {
                    NSApp.keyWindow?.makeFirstResponder(nil)
                    addDraftResource()
                }
                .buttonStyle(.plain)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 7)
                .background(tokens.accentTerracotta, in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(tokens.accentTerracotta.opacity(0.65), lineWidth: 1)
                }
                .disabled(isAddDisabled)
            }

            if let statusText {
                Text(statusText)
                    .font(.caption2)
                    .foregroundStyle(tokens.textTertiary)
                    .lineLimit(2)
            }
        }
        .padding(14)
        .background(tokens.bgFloating.opacity(0.46), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(tokens.sectionBorder.opacity(0.92), lineWidth: 1)
        }
    }

    private func typeButton(_ type: LaunchResourceType) -> some View {
        Button {
            selectedType = type
        } label: {
            HStack(spacing: 4) {
                Image(systemName: type.icon)
                    .font(.system(size: 11))
                Text(type.label)
                    .font(.caption2.weight(.medium))
            }
            .foregroundStyle(selectedType == type ? .white : tokens.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(selectedType == type ? tokens.accentTerracotta : tokens.bgFloating.opacity(0.86), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(
                        selectedType == type ? tokens.accentTerracotta.opacity(0.65) : tokens.sectionBorder.opacity(0.9),
                        lineWidth: 1
                    )
            }
        }
        .buttonStyle(.plain)
    }

    private var resourceList: some View {
        VStack(spacing: 4) {
            ForEach(draft) { item in
                resourceRow(item)
            }
        }
    }

    private func resourceRow(_ item: LaunchResource) -> some View {
        HStack(spacing: 10) {
            Image(systemName: item.type.icon)
                .font(.system(size: 12))
                .foregroundStyle(resourceTypeColor(item.type))
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 1) {
                Text(item.label)
                    .font(.system(size: 13))
                    .foregroundStyle(tokens.textPrimary)
                    .lineLimit(1)

                Text(item.displayValue)
                    .font(.caption2)
                    .foregroundStyle(tokens.textTertiary)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                launchSingle(item)
            } label: {
                Image(systemName: "play.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(tokens.textTertiary)
                    .frame(width: 24, height: 24)
                    .background(tokens.bgFloating, in: Circle())
            }
            .buttonStyle(.plain)

            Button {
                withAnimation {
                    draft.removeAll { $0.id == item.id }
                    saveDraft()
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10))
                    .foregroundStyle(tokens.textTertiary)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(tokens.bgFloating.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
    }

    private var typePlaceholder: String {
        switch selectedType {
        case .url: return "https://..."
        case .file: return "/path/to/file"
        case .app: return "/path/to/app.app"
        }
    }

    private func cancelAdd() {
        labelText = ""
        valueText = ""
        selectedType = .url
        withAnimation {
            isAdding = false
        }
    }

    private func addDraftResource() {
        let trimmedLabel = labelText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedValue = valueText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedLabel.isEmpty, !trimmedValue.isEmpty else {
            statusText = "Label and value are required"
            return
        }

        let candidate = LaunchResource(
            id: UUID().uuidString,
            type: selectedType,
            label: trimmedLabel,
            value: trimmedValue,
            createdAt: Date()
        )
        guard case let .success(valid) = validateLaunchResource(candidate) else {
            statusText = invalidMessage(for: selectedType)
            return
        }
        guard draft.count < 12 else {
            statusText = "Max 12 resources"
            return
        }

        withAnimation {
            draft.append(valid)
        }
        if saveDraft() {
            cancelAdd()
        } else {
            withAnimation {
                draft.removeAll { $0.id == valid.id }
            }
        }
    }

    @discardableResult
    private func saveDraft() -> Bool {
        let result = store.saveLaunchResources(todoId: todo.id, items: draft)
        switch result {
        case .success:
            if !draft.isEmpty {
                statusText = "\(draft.count) resource\(draft.count == 1 ? "" : "s")"
            }
            return true
        case .failure(.launchResourcesTooLarge):
            statusText = "Payload too large"
            return false
        case .failure:
            statusText = "Save failed"
            return false
        }
    }

    private var isAddDisabled: Bool {
        labelText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || valueText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func invalidMessage(for type: LaunchResourceType) -> String {
        switch type {
        case .url:
            return "Invalid URL (must start with http/https)"
        case .file:
            return "Invalid file path (must be absolute)"
        case .app:
            return "Invalid app path (.app) or unsupported deep link"
        }
    }

    private func launchAll() {
        let summary = launchpadService.launchAll(draft)
        statusText = launchStatusText(summary)
    }

    private func launchSingle(_ item: LaunchResource) {
        let summary = launchpadService.launchAll([item])
        statusText = launchStatusText(summary)
    }

    private func pickFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            valueText = url.path
            if labelText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                labelText = url.lastPathComponent
            }
        }
    }

    private func pickApp() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.application]

        if panel.runModal() == .OK, let url = panel.url {
            valueText = url.path
            if labelText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                labelText = url.deletingPathExtension().lastPathComponent
            }
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

    private func resourceTypeColor(_ type: LaunchResourceType) -> Color {
        switch type {
        case .url: return tokens.accentBlue
        case .file: return tokens.accentAmber
        case .app: return tokens.accentViolet
        }
    }
}

extension LaunchResourceType: CaseIterable, Identifiable {
    public static var allCases: [LaunchResourceType] {
        [.url, .file, .app]
    }

    var id: String { rawValue }
}

extension LaunchResourceType {
    var label: String {
        switch self {
        case .url: return "URL"
        case .file: return "File"
        case .app: return "App"
        }
    }

    var icon: String {
        switch self {
        case .url: return "link"
        case .file: return "doc"
        case .app: return "app.badge"
        }
    }
}

extension LaunchResource {
    var displayValue: String {
        if value.count > 40 {
            return String(value.prefix(40)) + "..."
        }
        return value
    }
}
