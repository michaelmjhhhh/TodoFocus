import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct SettingsView: View {
    let databasePath: String
    @State private var exportError: String?
    @State private var importError: String?
    @State private var showExportSuccess = false
    @State private var showImportSuccess = false
    @State private var showExportError = false
    @State private var showImportError = false

    var body: some View {
        TabView {
            GeneralSettingsView(
                databasePath: databasePath,
                onExport: performExport,
                onImport: performImport,
                showExportSuccess: $showExportSuccess,
                showImportSuccess: $showImportSuccess,
                showExportError: $showExportError,
                showImportError: $showImportError,
                exportError: $exportError,
                importError: $importError
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
                    try service.importFromJSON(data)
                    showImportSuccess = true
                } catch {
                    importError = error.localizedDescription
                    showImportError = true
                }
            }
        }
    }
}

struct GeneralSettingsView: View {
    let databasePath: String
    let onExport: () -> Void
    let onImport: () -> Void
    @Binding var showExportSuccess: Bool
    @Binding var showImportSuccess: Bool
    @Binding var showExportError: Bool
    @Binding var showImportError: Bool
    @Binding var exportError: String?
    @Binding var importError: String?

    var body: some View {
        Form {
            Section {
                Text("Data Management")
                    .font(.headline)
            }

            Section {
                Button("Export Data") {
                    onExport()
                }
                .buttonStyle(.bordered)

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
            Text("Your data has been imported. Please restart the app to see all changes.")
        }
        .alert("Import Failed", isPresented: $showImportError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importError ?? "An unknown error occurred.")
        }
    }
}
