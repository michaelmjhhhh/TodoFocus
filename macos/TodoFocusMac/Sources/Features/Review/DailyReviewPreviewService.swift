import AppKit
import Observation
import SwiftUI

@Observable
@MainActor
final class DailyReviewPreviewService {
    var isVisible: Bool = false
    private var panel: DailyReviewPreviewPanel?
    private var hostingView: DailyReviewPreviewHostingView?
    
    var store: TodoAppStore?
    
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
            self?.hidePanel()
            NSApp.activate(ignoringOtherApps: true)
            NotificationCenter.default.post(name: Notification.Name("todoFocusNavigateToDailyReview"), object: nil)
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
}
