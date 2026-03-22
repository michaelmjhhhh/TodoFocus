import AppKit

class QuickCapturePanel: NSPanel {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 140),
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
        self.backgroundColor = NSColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 0.95)
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.isOpaque = false
        self.hasShadow = true
    }
    
    func showAtCenter() {
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - 200
            let y = screenFrame.midY - 70
            self.setFrameOrigin(NSPoint(x: x, y: y))
        }
        self.makeKeyAndOrderFront(nil)
    }
    
    func hidePanel() {
        self.orderOut(nil)
    }
}
