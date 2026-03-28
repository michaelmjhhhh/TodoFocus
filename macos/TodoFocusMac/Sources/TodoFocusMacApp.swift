import SwiftUI

@main
struct TodoFocusMacApp: App {
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
        WindowGroup {
            Group {
                if let store {
                    RootView(
                        appModel: appModel,
                        store: store,
                        launchpadService: launchpadService,
                        databasePath: databaseManager?.path ?? "unavailable",
                        themeStore: themeStore
                    )
                    .preferredColorScheme(themeStore.preferredColorScheme)
                    .themeMode(themeStore.theme)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Database unavailable")
                            .font(.headline)
                        Text(startupError ?? "unknown startup error")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                    .padding(20)
                }
            }
            .preferredColorScheme(themeStore.preferredColorScheme)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: false))

#if os(macOS)
        Settings {
            SettingsView(databasePath: databaseManager?.path ?? "", themeStore: themeStore)
        }
#endif
    }
}
