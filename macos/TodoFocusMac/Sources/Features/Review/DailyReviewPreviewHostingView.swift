import AppKit
import SwiftUI

class DailyReviewPreviewHostingView: NSHostingView<DailyReviewPreviewView> {
    private let onClose: () -> Void
    private let onActivateApp: () -> Void

    required init(rootView: DailyReviewPreviewView) {
        self.onClose = { }
        self.onActivateApp = { }
        super.init(rootView: rootView)
    }

    init(service: DailyReviewPreviewService, store: TodoAppStore, onClose: @escaping () -> Void, onActivateApp: @escaping () -> Void) {
        self.onClose = onClose
        self.onActivateApp = onActivateApp

        let view = DailyReviewPreviewView(
            service: service,
            store: store,
            onClose: onClose,
            onActivateApp: onActivateApp
        )
        super.init(rootView: view)
    }
    
    @MainActor required dynamic init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
