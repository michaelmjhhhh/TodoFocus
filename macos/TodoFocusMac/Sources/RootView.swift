import SwiftUI

struct RootView: View {
    @Bindable var appModel: AppModel
    @Bindable var store: TodoAppStore
    let launchpadService: LaunchpadService
    let databasePath: String
    @State private var containerWidth: Double = 1200
    @State private var isSidebarVisible: Bool = true
    @State private var isHeaderExpanded: Bool = true

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
                        .background(VisualTokens.bgElevated)
                        .overlay(alignment: .trailing) {
                            Rectangle()
                                .fill(VisualTokens.sectionBorder.opacity(0.9))
                                .frame(width: 1)
                        }

                    Divider()
                        .overlay(VisualTokens.sectionBorder.opacity(0.4))
                }

                TaskListView(appModel: appModel, store: store)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                if store.selectedTodo != nil {
                    Rectangle()
                        .fill(VisualTokens.sectionBorder.opacity(0.85))
                        .frame(width: 5)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let next = appModel.detailPanelWidth - value.translation.width
                                    appModel.updateDetailPanelWidth(next, windowWidth: proxy.size.width)
                                }
                        )
                        .transition(.move(edge: .trailing).combined(with: .opacity))

                    TaskDetailView(
                        store: store,
                        launchpadService: launchpadService,
                        todo: store.selectedTodo,
                        onClose: {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                                store.clearSelection()
                            }
                        }
                    )
                    .frame(width: appModel.detailPanelWidth)
                    .background(VisualTokens.panelBackground)
                    .overlay(alignment: .leading) {
                        Rectangle()
                            .fill(VisualTokens.sectionBorder)
                            .frame(width: 1)
                    }
                    .shadow(color: Color.black.opacity(0.30), radius: 12, x: -6, y: 0)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .background(
                VisualTokens.appBackground
            )
            .animation(MotionTokens.panelSpring, value: store.selectedTodo?.id)
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
        .immersiveHeader(isExpanded: $isHeaderExpanded, isSidebarVisible: $isSidebarVisible)
    }
}
