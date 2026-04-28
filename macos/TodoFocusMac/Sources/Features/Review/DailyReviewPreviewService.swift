import AppKit
import Observation
import SwiftUI

extension Notification.Name {
    static let todoFocusNavigateToDailyReview = Notification.Name("todoFocusNavigateToDailyReview")
}

@Observable
@MainActor
final class DailyReviewPreviewService {
    var isVisible: Bool = false
    private var panel: DailyReviewPreviewPanel?
    private var hostingView: DailyReviewPreviewHostingView?
    @ObservationIgnored private let appActivator: @MainActor () -> Void
    @ObservationIgnored private let notificationCenter: NotificationCenter
    
    var store: TodoAppStore?

    init(
        appActivator: @escaping @MainActor () -> Void = DailyReviewPreviewService.activateCurrentApplication,
        notificationCenter: NotificationCenter = .default
    ) {
        self.appActivator = appActivator
        self.notificationCenter = notificationCenter
    }
    
    func showPanel() {
        guard let store else { return }
        
        if panel == nil {
            panel = DailyReviewPreviewPanel()
            panel?.onWindowClose = { [weak self] in
                self?.isVisible = false
            }
        }
        
        let onClose: () -> Void = { [weak self] in
            self?.hidePanel()
        }
        let onActivateApp: () -> Void = { [weak self] in
            self?.activateAppAndNavigateToDailyReview()
        }
        
        if hostingView == nil {
            hostingView = DailyReviewPreviewHostingView(
                service: self,
                store: store,
                onClose: onClose,
                onActivateApp: onActivateApp
            )
            panel?.contentView = hostingView
        } else {
            hostingView?.rootView = DailyReviewPreviewView(
                service: self,
                store: store,
                onClose: onClose,
                onActivateApp: onActivateApp
            )
        }
        
        panel?.showAtCenter()
        isVisible = true
    }
    
    func hidePanel() {
        panel?.hidePanel()
        isVisible = false
    }
    
    func togglePanel() {
        if isVisible {
            hidePanel()
        } else {
            showPanel()
        }
    }

    func activateAppAndNavigateToDailyReview() {
        hidePanel()
        appActivator()
        notificationCenter.post(name: .todoFocusNavigateToDailyReview, object: nil)
    }

    private static func activateCurrentApplication() {
        NSRunningApplication.current.activate(options: [.activateAllWindows])
        NSApp.activate(ignoringOtherApps: true)
        NSApp.windows
            .first { $0.isVisible && $0.canBecomeKey && !($0 is DailyReviewPreviewPanel) }?
            .makeKeyAndOrderFront(nil)
    }
}
