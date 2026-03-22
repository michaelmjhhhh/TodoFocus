import AppKit
import Observation

@Observable
@MainActor
final class QuickCaptureService {
    var isVisible: Bool = false
    private var panel: QuickCapturePanel?
    private nonisolated(unsafe) var globalMonitor: Any?
    private var hostingView: QuickCaptureHostingView?
    
    var deepFocusService: DeepFocusService?
    var onCapture: ((String) -> Void)?
    
    func setup() {
        setupGlobalHotkey()
    }
    
    private func setupGlobalHotkey() {
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.modifierFlags.contains([.command, .shift]) else { return }
            if event.charactersIgnoringModifiers == "t" {
                Task { @MainActor in
                    self?.showCapturePanel()
                }
            }
        }
    }
    
    func showCapturePanel() {
        if panel == nil {
            panel = QuickCapturePanel()
        }
        
        let targetInfo: String
        if let dfService = deepFocusService, dfService.isActive {
            let count = dfService.blockedApps.count
            targetInfo = "Adding to Deep Focus (blocking \(count) apps)"
        } else {
            targetInfo = "No Deep Focus - will add to Inbox"
        }
        
        hostingView = QuickCaptureHostingView(
            onSubmit: { [weak self] text in
                self?.handleCapture(text)
            },
            onCancel: { [weak self] in
                self?.hidePanel()
            },
            targetInfo: targetInfo
        )
        
        panel?.contentView = hostingView
        panel?.showAtCenter()
        isVisible = true
    }
    
    private func handleCapture(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            hidePanel()
            return
        }
        
        let timestamp = formatTimestamp(Date())
        let captureText = "\n[\(timestamp)] \(trimmed)"
        onCapture?(captureText)
        hidePanel()
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func hidePanel() {
        panel?.orderOut(nil)
        isVisible = false
    }
    
    deinit {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
