import AppKit

class DailyReviewPreviewPanel: NSPanel {
    var onWindowClose: (() -> Void)?

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 460),
            styleMask: [.titled, .closable, .nonactivatingPanel, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        self.level = .floating
        self.isFloatingPanel = true
        self.becomesKeyOnlyIfNeeded = false
        self.hidesOnDeactivate = false
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.isMovableByWindowBackground = true
        self.backgroundColor = NSColor(red: 0.937, green: 0.914, blue: 0.871, alpha: 0.97)
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.isOpaque = false
        self.hasShadow = true
    }
    
    func showAtCenter() {
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - 180
            let y = screenFrame.midY - 230
            self.setFrameOrigin(NSPoint(x: x, y: y))
        }
        self.makeKeyAndOrderFront(nil)
    }
    
    func hidePanel() {
        self.orderOut(nil)
    }

    override func close() {
        super.close()
        onWindowClose?()
    }
}
