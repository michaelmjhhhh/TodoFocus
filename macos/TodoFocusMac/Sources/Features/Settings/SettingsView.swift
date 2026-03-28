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
        .frame(maxWidth: 450, maxHeight: 300)
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
                    let preflight = try service.preflightImportJSON(data)
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
                lines.append("Skipped launch resources: \(report.skipped.launchResources)")
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

    var body: some View {
        Form {
            Section("Appearance") {
                Picker("Theme", selection: $themeStore.theme) {
                    Text("Dark").tag(ThemeStore.Theme.dark)
                    Text("Light").tag(ThemeStore.Theme.light)
                    Text("System").tag(ThemeStore.Theme.system)
                }
                .pickerStyle(.segmented)
            }

            Section {
                Text("Data Management")
                    .font(.headline)
            }

            Section {
                Button("Export Data") {
                    onExport()
                }
                .buttonStyle(.bordered)

                Picker("Import Mode", selection: $selectedImportMode) {
                    ForEach(ImportMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.menu)

                Button("Import Data") {
                    onImport()
                }
                .buttonStyle(.bordered)
            }

            Section {
                Text("Database: \(URL(fileURLWithPath: databasePath).lastPathComponent)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
        .alert("Export Successful", isPresented: $showExportSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your data has been exported successfully.")
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
                Text("Version: \(preflight.version)\nLists: \(preflight.counts.lists), Todos: \(preflight.counts.todos), Steps: \(preflight.counts.steps)\nWarnings: \(warningsText)")
            } else {
                Text("Proceed with import?")
            }
        }
    }
}
