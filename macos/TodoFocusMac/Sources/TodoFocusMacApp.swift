import SwiftUI
import AppKit

private enum SceneIDs {
    static let mainWindow = "main"
}

final class TodoFocusMacAppDelegate: NSObject, NSApplicationDelegate {
    var onTerminateRequested: (@MainActor () async -> Void)?
    private var isHandlingTermination = false

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard !isHandlingTermination else {
            return .terminateNow
        }

        guard let onTerminateRequested else {
            return .terminateNow
        }

        isHandlingTermination = true
        Task { @MainActor in
            await onTerminateRequested()
            NSApp.reply(toApplicationShouldTerminate: true)
            self.isHandlingTermination = false
        }
        return .terminateLater
    }
}

@main
struct TodoFocusMacApp: App {
    @NSApplicationDelegateAdaptor(TodoFocusMacAppDelegate.self) private var appDelegate
    @State private var appModel = AppModel()
    @State private var themeStore = ThemeStore()
    @State private var store: TodoAppStore?
    @State private var launchpadService = LaunchpadService()
    @State private var startupError: String?
    private let databaseManager: DatabaseManager?

    init() {
        do {
            let manager = try DatabaseManager()
            databaseManager = manager

            let model = AppModel()
            let listRepository = ListRepository(dbQueue: manager.dbQueue)
            let todoRepository = TodoRepository(dbQueue: manager.dbQueue)
            let stepRepository = StepRepository(dbQueue: manager.dbQueue)
            let hardFocusRepository = HardFocusSessionRepository(dbQueue: manager.dbQueue)
            _appModel = State(initialValue: model)
            _store = State(
                initialValue: TodoAppStore(
                    appModel: model,
                    listRepository: listRepository,
                    todoRepository: todoRepository,
                    stepRepository: stepRepository,
                    hardFocusRepository: hardFocusRepository
                )
            )
            _startupError = State(initialValue: nil)
        } catch {
            databaseManager = nil
            _startupError = State(initialValue: String(describing: error))
        }
    }

    var body: some Scene {
        WindowGroup(id: SceneIDs.mainWindow) {
            Group {
                if let store {
                    RootView(
                        appModel: appModel,
                        store: store,
                        launchpadService: launchpadService,
                        databasePath: databaseManager?.path ?? "unavailable"
                    )
                    .preferredColorScheme(.dark)
                    .task {
                        appDelegate.onTerminateRequested = { [weak store] in
                            appModel.quickCaptureService.cleanup()
                            await store?.endFocusForAppTermination()
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Database unavailable")
                            .font(TypographyTokens.headingLarge)
                        Text(startupError ?? "unknown startup error")
                            .font(TypographyTokens.caption)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                    .padding(20)
                }
            }
            .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .defaultSize(width: 1280, height: 820)

        MenuBarExtra {
            Group {
                if let store {
                    DeepFocusMenuBarPanel(
                        store: store,
                        mainWindowID: SceneIDs.mainWindow
                    )
                } else {
                    Text("TodoFocus unavailable")
                        .font(TypographyTokens.caption)
                        .padding(12)
                }
            }
            .preferredColorScheme(.dark)
        } label: {
            if let store {
                DeepFocusMenuBarLabel(store: store)
            } else {
                Label("TodoFocus", systemImage: "checklist")
            }
        }
        .menuBarExtraStyle(.window)

#if os(macOS)
        Settings {
            SettingsView(databasePath: databaseManager?.path ?? "")
        }
#endif
    }
}
