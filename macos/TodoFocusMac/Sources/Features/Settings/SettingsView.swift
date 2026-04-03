import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct SettingsView: View {
    let databasePath: String
    let themeStore: ThemeStore
    @State private var selectedImportMode: ImportMode = .replace
    @State private var exportError: String?
    @State private var importError: String?
    @State private var importSuccessMessage: String = "Your data has been imported successfully."
    @State private var showExportSuccess = false
    @State private var showImportSuccess = false
    @State private var showExportError = false
    @State private var showImportError = false
    @State private var showImportConfirmation = false
    @State private var pendingImportData: Data?
    @State private var pendingImportPreflight: ImportPreflightResult?

    var body: some View {
        TabView {
            GeneralSettingsView(
                databasePath: databasePath,
                themeStore: themeStore,
                selectedImportMode: $selectedImportMode,
                onExport: performExport,
                onImport: performImport,
                onConfirmImport: executePendingImport,
                showExportSuccess: $showExportSuccess,
                showImportSuccess: $showImportSuccess,
                showExportError: $showExportError,
                showImportError: $showImportError,
                showImportConfirmation: $showImportConfirmation,
                exportError: $exportError,
                importError: $importError,
                importSuccessMessage: $importSuccessMessage,
                pendingImportPreflight: $pendingImportPreflight
            )
            .tabItem {
                Label("General", systemImage: "gear")
            }
        }
        .frame(maxWidth: 520, maxHeight: 430)
    }

    private func performExport() {
        guard let manager = try? DatabaseManager() else {
            exportError = "Unable to access database"
            showExportError = true
            return
        }

        let service = ExportService(dbQueue: manager.dbQueue)

        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType.json]
        panel.nameFieldStringValue = "TodoFocus-export.json"
        panel.canCreateDirectories = true

        panel.begin { response in
            if response == .OK, let url = panel.url {
                do {
                    let data = try service.exportToJSON()
                    try data.write(to: url)
                    showExportSuccess = true
                } catch {
                    exportError = error.localizedDescription
                    showExportError = true
                }
            }
        }
    }

    private func performImport() {
        guard let manager = try? DatabaseManager() else {
            importError = "Unable to access database"
            showImportError = true
            return
        }

        let service = ExportService(dbQueue: manager.dbQueue)

        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType.json]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false

        panel.begin { response in
            if response == .OK, let url = panel.url {
                do {
                    let data = try Data(contentsOf: url)
                    let preflight = try service.preflightImportJSON(data, mode: selectedImportMode)
                    if !preflight.blockingErrors.isEmpty {
                        importError = preflight.blockingErrors.joined(separator: "\n")
                        showImportError = true
                        return
                    }
                    pendingImportData = data
                    pendingImportPreflight = preflight
                    showImportConfirmation = true
                } catch {
                    importError = error.localizedDescription
                    showImportError = true
                }
            }
        }
    }

    private func executePendingImport() {
        guard let data = pendingImportData else { return }
        guard let manager = try? DatabaseManager() else {
            importError = "Unable to access database"
            showImportError = true
            return
        }

        let service = ExportService(dbQueue: manager.dbQueue)
        do {
            let report = try service.executeImportJSON(data, mode: selectedImportMode)
            var lines: [String] = []
            lines.append("Created — Lists: \(report.created.lists), Todos: \(report.created.todos), Steps: \(report.created.steps)")
            lines.append("Updated — Lists: \(report.updated.lists), Todos: \(report.updated.todos), Steps: \(report.updated.steps)")
            if report.skipped.launchResources > 0 {
                lines.append("Skipped non-portable launch resources (file/app): \(report.skipped.launchResources)")
            }
            if let backup = report.backupFilePath {
                lines.append("Backup saved to: \(backup)")
            }
            importSuccessMessage = lines.joined(separator: "\n")
            showImportSuccess = true
            pendingImportData = nil
            pendingImportPreflight = nil
        } catch {
            importError = error.localizedDescription
            showImportError = true
        }
    }
}

struct GeneralSettingsView: View {
    let databasePath: String
    @Bindable var themeStore: ThemeStore
    @Binding var selectedImportMode: ImportMode
    let onExport: () -> Void
    let onImport: () -> Void
    let onConfirmImport: () -> Void
    @Binding var showExportSuccess: Bool
    @Binding var showImportSuccess: Bool
    @Binding var showExportError: Bool
    @Binding var showImportError: Bool
    @Binding var showImportConfirmation: Bool
    @Binding var exportError: String?
    @Binding var importError: String?
    @Binding var importSuccessMessage: String
    @Binding var pendingImportPreflight: ImportPreflightResult?
    @Environment(\.themeTokens) private var tokens

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                settingsCard(title: "Appearance", icon: "paintbrush") {
                    Picker("Theme", selection: $themeStore.theme) {
                        Text("Dark").tag(ThemeStore.Theme.dark)
                        Text("Light").tag(ThemeStore.Theme.light)
                        Text("System").tag(ThemeStore.Theme.system)
                    }
                    .pickerStyle(.segmented)
                }

                settingsCard(title: "Data Import & Export", icon: "arrow.left.arrow.right.circle") {
                    Text("Portable transfer: lists, tasks, steps, and URL launch resources.")
                        .font(tokens.uiLabel(12, weight: .regular))
                        .foregroundStyle(tokens.textSecondary)
                    Text("Reminder: file and app launch resources are device-local and are intentionally skipped during import/export.")
                        .font(tokens.uiLabel(12, weight: .regular))
                        .foregroundStyle(tokens.warning)
                        .padding(.bottom, 4)

                    Picker("Import Mode", selection: $selectedImportMode) {
                        ForEach(ImportMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)

                    HStack(spacing: 10) {
                        Button("Export Data") {
                            onExport()
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(tokens.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(tokens.accentTerracotta.opacity(0.94), in: Capsule())

                        Button("Import Data") {
                            onImport()
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(tokens.accentSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(tokens.bgFloating.opacity(0.9), in: Capsule())
                        .overlay {
                            Capsule()
                                .stroke(tokens.sectionBorder, lineWidth: 1)
                        }
                    }
                }

                settingsCard(title: "Database", icon: "internaldrive") {
                    Text(URL(fileURLWithPath: databasePath).lastPathComponent)
                        .font(.subheadline)
                        .foregroundStyle(tokens.textPrimary)
                    Text(databasePath)
                        .font(.caption)
                        .lineLimit(2)
                        .truncationMode(.middle)
                        .foregroundStyle(tokens.textTertiary)
                }
            }
            .padding(16)
        }
        .background(tokens.bgBase)
        .alert("Export Successful", isPresented: $showExportSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Portable data has been exported successfully.")
        }
        .alert("Export Failed", isPresented: $showExportError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(exportError ?? "An unknown error occurred.")
        }
        .alert("Import Successful", isPresented: $showImportSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importSuccessMessage)
        }
        .alert("Import Failed", isPresented: $showImportError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importError ?? "An unknown error occurred.")
        }
        .confirmationDialog(
            "Confirm Import",
            isPresented: $showImportConfirmation,
            titleVisibility: .visible
        ) {
            Button("Import \(selectedImportMode == .replace ? "and Replace" : "and Merge")", role: .destructive) {
                onConfirmImport()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let preflight = pendingImportPreflight {
                let warningsText = preflight.warnings.isEmpty ? "None" : preflight.warnings.joined(separator: ", ")
                Text("Version: \(preflight.version)\nLists: \(preflight.counts.lists), Todos: \(preflight.counts.todos), Steps: \(preflight.counts.steps), Launch Resources: \(preflight.counts.launchResources)\nWarnings: \(warningsText)")
            } else {
                Text("Proceed with import?")
            }
        }
    }

    @ViewBuilder
    private func settingsCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(tokens.accentTerracotta)
                Text(title)
                    .font(tokens.editorialTitle(17, weight: .semibold))
                    .foregroundStyle(tokens.textPrimary)
            }
            content()
        }
        .padding(12)
        .background(tokens.bgElevated, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(tokens.sectionBorder, lineWidth: 1)
        )
    }
}
