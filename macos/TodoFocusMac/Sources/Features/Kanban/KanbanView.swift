import SwiftUI

struct KanbanView: View {
    static let title = "Kanban"
    static let emptyProjectTitle = "Create your first project"
    static let deleteProjectConfirmation = "Delete this project and all of its cards?"

    @Bindable var store: KanbanStore
    @Environment(\.themeTokens) private var tokens
    @State private var showsProjectForm = false
    @State private var editsProject = false
    @State private var showsDeleteProject = false
    @State private var showsArchive = false

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.lg) {
            header
            if let message = store.errorMessage { errorBanner(message) }
            if store.showsDataRepairWarning { repairBanner }
            if store.projects.isEmpty { emptyState } else { KanbanBoardView(store: store) }
        }
        .padding(SpacingTokens.xl)
        .background(tokens.appBackground)
        .task { store.loadForDisplay() }
        .sheet(isPresented: $showsProjectForm) { ProjectFormView(store: store, editsExisting: editsProject) }
        .sheet(isPresented: $showsArchive) { KanbanArchiveView(store: store) }
        .confirmationDialog(Self.deleteProjectConfirmation, isPresented: $showsDeleteProject) {
            Button("Delete Project", role: .destructive) { store.deleteSelectedProject() }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.sm) {
            HStack {
                Text(Self.title).font(TypographyTokens.displayLarge).foregroundStyle(tokens.textPrimary)
                if !store.projects.isEmpty {
                    Picker("Project", selection: Binding(get: { store.selectedProjectID ?? "" }, set: { store.selectProject(id: $0) })) {
                        ForEach(store.projects) { Text($0.name).tag($0.id) }
                    }.frame(maxWidth: 240)
                }
                Spacer()
                Button("Archived") { store.loadArchivedCards(); showsArchive = true }
                Button { editsProject = false; showsProjectForm = true } label: { Label("New Project", systemImage: "plus") }
                if store.selectedProject != nil {
                    Button("Edit") { editsProject = true; showsProjectForm = true }
                    Button(role: .destructive) { showsDeleteProject = true } label: { Image(systemName: "trash") }
                }
            }
            if let project = store.selectedProject {
                HStack(spacing: 8) {
                    Circle().fill(Color(hex: project.color)).frame(width: 10, height: 10)
                    Text(project.goal).font(TypographyTokens.bodySmall).foregroundStyle(tokens.textSecondary)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "rectangle.3.group").font(.system(size: 36)).foregroundStyle(tokens.accentTerracotta)
            Text(Self.emptyProjectTitle).font(TypographyTokens.displaySmall)
            Button("New Project") { editsProject = false; showsProjectForm = true }
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorBanner(_ message: String) -> some View {
        HStack { Image(systemName: "exclamationmark.triangle.fill"); Text(message); Spacer(); if store.canRetryLastLoad { Button("Retry") { store.retryLastLoad() } }; Button("Dismiss") { store.clearError() } }
            .font(TypographyTokens.caption).foregroundStyle(tokens.danger).padding(10).background(tokens.bgSubtle, in: RoundedRectangle(cornerRadius: 8))
    }

    private var repairBanner: some View {
        HStack { Text("Some saved Kanban values were invalid. Affected cards are shown in Backlog with Medium priority."); Spacer(); Button("Dismiss") { store.showsDataRepairWarning = false } }
            .font(TypographyTokens.caption).padding(10).background(tokens.bgSubtle, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct ProjectFormView: View {
    @Bindable var store: KanbanStore
    let editsExisting: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var color = "#C46849"
    @State private var goal = ""
    private let colors = ["#EF4444", "#F97316", "#EAB308", "#22C55E", "#06B6D4", "#3B82F6", "#8B5CF6", "#EC4899", "#C46849", "#14B8A6"]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(editsExisting ? "Edit Project" : "New Project").font(TypographyTokens.displaySmall)
            TextField("Name", text: $name).textFieldStyle(.roundedBorder)
            TextField("Goal", text: $goal, axis: .vertical).lineLimit(3...6).textFieldStyle(.roundedBorder)
            HStack { ForEach(colors, id: \.self) { value in Button { color = value } label: { Circle().fill(Color(hex: value)).frame(width: 22, height: 22).overlay { if color == value { Image(systemName: "checkmark").font(.caption2).foregroundStyle(.white) } } }.buttonStyle(.plain) } }
            HStack { Spacer(); Button("Cancel") { dismiss() }; Button("Save") { if editsExisting { store.updateSelectedProject(name: name, color: color, goal: goal) } else { store.createProject(name: name, color: color, goal: goal) }; dismiss() }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || goal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
        }.padding(24).frame(width: 460).onAppear { if editsExisting, let project = store.selectedProject { name = project.name; color = project.color; goal = project.goal } }
    }
}
