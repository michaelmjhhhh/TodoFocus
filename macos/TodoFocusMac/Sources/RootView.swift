import SwiftUI

struct RootView: View {
    @Bindable var appModel: AppModel
    @Bindable var store: TodoAppStore
    let launchpadService: LaunchpadService
    let databasePath: String

    init(appModel: AppModel, store: TodoAppStore, launchpadService: LaunchpadService, databasePath: String) {
        self._appModel = Bindable(appModel)
        self._store = Bindable(store)
        self.launchpadService = launchpadService
        self.databasePath = databasePath
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(appModel: appModel, lists: store.lists)
                .navigationSplitViewColumnWidth(min: 220, ideal: 250)
        } content: {
            TaskListView(appModel: appModel, store: store)
                .navigationSplitViewColumnWidth(min: 320, ideal: 420)
        } detail: {
            ResizableSplitView(
                rightWidth: Binding(
                    get: { appModel.detailPanelWidth },
                    set: { (value: Double) in appModel.detailPanelWidth = value }
                )
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("TodoFocus")
                        .font(.title2.bold())
                    Text("SwiftUI rewrite branch")
                        .foregroundStyle(.secondary)
                    Text("DB: \(databasePath)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(24)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } right: {
                TaskDetailView(store: store, launchpadService: launchpadService, todo: store.selectedTodo)
            }
        }
        .task {
            try? store.reload()
        }
    }
}
