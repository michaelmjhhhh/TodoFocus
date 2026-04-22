import SwiftUI

struct RootView: View {
    @Bindable var appModel: AppModel
    @Bindable var store: TodoAppStore
    let launchpadService: LaunchpadService
    let databasePath: String
    let themeStore: ThemeStore
    @State private var containerWidth: Double = 1200
    @State private var isSidebarVisible: Bool = true
    @State private var isHeaderExpanded: Bool = true
    @State private var themeTokens: ThemeTokens
    @State private var isHardFocusActive: Bool = false
    @State private var detailPanelDragStartWidth: Double?
    @State private var detailPanelLiveWidth: Double = WindowPersistence.loadDetailWidth()

    init(appModel: AppModel, store: TodoAppStore, launchpadService: LaunchpadService, databasePath: String, themeStore: ThemeStore) {
        self._appModel = Bindable(appModel)
        self._store = Bindable(store)
        self.launchpadService = launchpadService
        self.databasePath = databasePath
        self.themeStore = themeStore
        self._themeTokens = State(initialValue: ThemeTokens(theme: themeStore.theme))
    }

    var body: some View {
        GeometryReader { proxy in
            HStack(spacing: 0) {
                if isSidebarVisible {
                    SidebarView(appModel: appModel, store: store, lists: store.lists, themeStore: themeStore)
                        .frame(width: 250)
                        .background(themeTokens.bgElevated)
                        .overlay(alignment: .trailing) {
                            Rectangle()
                                .fill(themeTokens.sectionBorder.opacity(0.9))
                                .frame(width: 1)
                        }

                    Divider()
                        .overlay(themeTokens.sectionBorder.opacity(0.4))
                }

                if appModel.selection == .dailyReview {
                    DailyReviewView(appModel: appModel, store: store)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    TaskListView(appModel: appModel, store: store)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                if store.selectedTodo != nil {
                    Rectangle()
                        .fill(.clear)
                        .frame(width: 14)
                        .overlay {
                            Rectangle()
                                .fill(themeTokens.sectionBorder.opacity(0.9))
                                .frame(width: 3)
                        }
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    if detailPanelDragStartWidth == nil {
                                        detailPanelDragStartWidth = detailPanelLiveWidth
                                    }
                                    let startWidth = detailPanelDragStartWidth ?? detailPanelLiveWidth
                                    let next = startWidth - value.translation.width
                                    detailPanelLiveWidth = WindowPersistence.clampDetailWidth(next, windowWidth: proxy.size.width)
                                }
                                .onEnded { value in
                                    let startWidth = detailPanelDragStartWidth ?? detailPanelLiveWidth
                                    let next = startWidth - value.translation.width
                                    appModel.updateDetailPanelWidth(next, windowWidth: proxy.size.width)
                                    detailPanelLiveWidth = appModel.detailPanelWidth
                                    detailPanelDragStartWidth = nil
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
                    .frame(width: detailPanelLiveWidth)
                    .background(themeTokens.panelBackground)
                    .overlay(alignment: .leading) {
                        Rectangle()
                            .fill(themeTokens.sectionBorder)
                            .frame(width: 1)
                    }
                    .shadow(color: Color.black.opacity(0.30), radius: 12, x: -6, y: 0)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .background(
                themeTokens.appBackground
            )
            .animation(MotionTokens.panelSpring, value: store.selectedTodo?.id)
            .onAppear {
                containerWidth = proxy.size.width
                appModel.updateDetailPanelWidth(appModel.detailPanelWidth, windowWidth: containerWidth)
                detailPanelLiveWidth = appModel.detailPanelWidth
                appModel.quickCaptureService.deepFocusService = appModel.deepFocusService
                appModel.quickCaptureService.onCapture = { [weak store] text in
                    store?.appendToFocusTaskNotes(text)
                }
                appModel.quickCaptureService.setup()
                appModel.quickCaptureService.dailyReviewPreviewService = appModel.dailyReviewPreviewService
                appModel.dailyReviewPreviewService.store = store
            }
            .onChange(of: proxy.size.width) { _, newValue in
                containerWidth = newValue
                appModel.updateDetailPanelWidth(appModel.detailPanelWidth, windowWidth: newValue)
                detailPanelLiveWidth = appModel.detailPanelWidth
            }
            .onChange(of: themeStore.theme) { _, newTheme in
                themeTokens = ThemeTokens(theme: newTheme)
            }
            .onChange(of: appModel.detailPanelWidth) { _, newValue in
                detailPanelLiveWidth = newValue
            }
        }
        .task {
            do {
                try store.reload()
            } catch {
                store.mutationErrorMessage = "Failed to load data: \(error.localizedDescription)"
            }
        }
        .onReceive(store.hardFocusManager.$isEnforcing) { isEnforcing in
            if isHardFocusActive && !isEnforcing && store.deepFocusService.isActive {
                Task { @MainActor in
                    _ = await store.endDeepFocus(endedByHardFocus: true)
                }
            }
            isHardFocusActive = isEnforcing
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("todoFocusNavigateToDailyReview"))) { _ in
            appModel.selectSidebar(.dailyReview)
        }
        .immersiveHeader(isExpanded: $isHeaderExpanded, isSidebarVisible: $isSidebarVisible)
        .environment(\.themeTokens, themeTokens)
        .overlay(alignment: .bottomTrailing) {
            Button("") {
                withAnimation(.easeInOut(duration: 0.2)) {
                    themeStore.cycleTheme()
                }
            }
            .keyboardShortcut("l", modifiers: [.command, .shift])
            .opacity(0)
            .allowsHitTesting(false)
        }
        .safeAreaInset(edge: .top) {
            if isHardFocusActive {
                HardFocusLockView(sessionManager: store.hardFocusManager)
                    .environment(\.themeTokens, themeTokens)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
}
