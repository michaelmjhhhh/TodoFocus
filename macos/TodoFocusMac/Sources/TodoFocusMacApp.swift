import SwiftUI

@main
struct TodoFocusMacApp: App {
    @State private var appModel = AppModel()
    @State private var themeStore = ThemeStore()
    private let databaseManager: DatabaseManager?

    init() {
        databaseManager = try? DatabaseManager()
    }

    var body: some Scene {
        WindowGroup {
            RootView(appModel: appModel, databasePath: databaseManager?.path ?? "unavailable")
                .preferredColorScheme(themeStore.preferredColorScheme)
        }
    }
}
