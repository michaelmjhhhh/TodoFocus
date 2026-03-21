import SwiftUI

struct RootView: View {
    @Bindable var appModel: AppModel
    @Bindable var store: TodoAppStore
    let launchpadService: LaunchpadService
    let databasePath: String
    @State private var containerWidth: Double = 1200
    @State private var isSidebarVisible: Bool = true

    init(appModel: AppModel, store: TodoAppStore, launchpadService: LaunchpadService, databasePath: String) {
        self._appModel = Bindable(appModel)
        self._store = Bindable(store)
        self.launchpadService = launchpadService
        self.databasePath = databasePath
    }

    var body: some View {
        GeometryReader { proxy in
            HStack(spacing: 0) {
                if isSidebarVisible {
                    SidebarView(appModel: appModel, store: store, lists: store.lists)
                        .frame(width: 250)
                        .background(.ultraThinMaterial)

                    Divider()
                }

                TaskListView(appModel: appModel, store: store)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Rectangle()
                    .fill(Color.secondary.opacity(0.18))
                    .frame(width: 6)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let next = appModel.detailPanelWidth - value.translation.width
                                appModel.updateDetailPanelWidth(next, windowWidth: proxy.size.width)
                            }
                    )

                TaskDetailView(store: store, launchpadService: launchpadService, todo: store.selectedTodo)
                    .frame(width: appModel.detailPanelWidth)
                    .background(.regularMaterial)
            }
            .background(
                VisualTokens.appBackground
            )
            .onAppear {
                containerWidth = proxy.size.width
                appModel.updateDetailPanelWidth(appModel.detailPanelWidth, windowWidth: containerWidth)
            }
            .onChange(of: proxy.size.width) { _, newValue in
                containerWidth = newValue
                appModel.updateDetailPanelWidth(appModel.detailPanelWidth, windowWidth: newValue)
            }
        }
        .task {
            try? store.reload()
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isSidebarVisible.toggle()
                    }
                } label: {
                    Image(systemName: "sidebar.leading")
                }
            }
        }
        .onChange(of: appModel.selectedTodoID) { _, newValue in
            if newValue != nil {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isSidebarVisible = false
                }
            }
        }
    }
}
