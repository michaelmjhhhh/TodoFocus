import AppKit

class DailyReviewPreviewPanel: NSPanel {
    var onWindowClose: (() -> Void)?

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 460),
            styleMask: [.titled, .closable, .nonactivatingPanel, .hudWindow, .utilityWindow],
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
        self.backgroundColor = NSColor(red: 0.07, green: 0.07, blue: 0.08, alpha: 0.94)
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
