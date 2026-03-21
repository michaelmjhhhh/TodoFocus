import SwiftUI

@main
struct TodoFocusMacApp: App {
    @State private var appModel = AppModel()
    @State private var themeStore = ThemeStore()
    @State private var store: TodoAppStore?
    private let databaseManager: DatabaseManager?

    init() {
        databaseManager = try? DatabaseManager()
        if let databaseManager {
            let model = AppModel()
            let listRepository = ListRepository(dbQueue: databaseManager.dbQueue)
            let todoRepository = TodoRepository(dbQueue: databaseManager.dbQueue)
            _appModel = State(initialValue: model)
            _store = State(
                initialValue: TodoAppStore(
                    appModel: model,
                    listRepository: listRepository,
                    todoRepository: todoRepository
                )
            )
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if let store {
                    RootView(appModel: appModel, store: store, databasePath: databaseManager?.path ?? "unavailable")
                } else {
                    Text("Database unavailable")
                }
            }
            .preferredColorScheme(themeStore.preferredColorScheme)
        }
    }
}
