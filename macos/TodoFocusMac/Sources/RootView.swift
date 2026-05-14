import SwiftUI

struct RootView: View {
    @Bindable var appModel: AppModel
    @Bindable var store: TodoAppStore
    let launchpadService: LaunchpadService
    let databasePath: String
    @State private var containerWidth: Double = 1200
    @State private var isSidebarVisible: Bool = true
    @State private var isHeaderExpanded: Bool = true
    @State private var themeTokens = ThemeTokens()
    @State private var isHardFocusActive: Bool = false
    @State private var detailPanelDragStartWidth: Double?
    @State private var detailPanelLiveWidth: Double = WindowPersistence.loadDetailWidth()

    var body: some View {
        GeometryReader { proxy in
            HStack(spacing: 1) {
                if isSidebarVisible {
                    SidebarView(appModel: appModel, store: store, lists: store.lists)
                        .frame(width: 240)
                        .background(themeTokens.bgElevated)
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
                        .frame(width: 10)
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
                            withAnimation(MotionTokens.panelSpring) {
                                store.clearSelection()
                            }
                        }
                    )
                    .frame(width: detailPanelLiveWidth)
                    .background(themeTokens.panelBackground)
                    .shadowMedium()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .background(themeTokens.appBackground)
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
        .onReceive(NotificationCenter.default.publisher(for: .todoFocusNavigateToDailyReview)) { _ in
            appModel.selectSidebar(.dailyReview)
        }
        .immersiveHeader(isExpanded: $isHeaderExpanded, isSidebarVisible: $isSidebarVisible)
        .environment(\.themeTokens, themeTokens)
        .overlay(alignment: .bottom) {
            ShortcutHintBar(
                needsAccessibilityPermission: appModel.quickCaptureService.needsAccessibilityPermission,
                onRequestPermission: {
                    appModel.quickCaptureService.requestAccessibilityPermission()
                }
            )
            .padding(.bottom, SpacingTokens.lg)
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
