import AppKit
import Observation

@Observable
@MainActor
final class QuickCaptureService {
    var isVisible: Bool = false
    var needsAccessibilityPermission: Bool = false
    private var panel: QuickCapturePanel?
    private var hostingView: QuickCaptureHostingView?
    
    var deepFocusService: DeepFocusService?
    var onCapture: ((String) -> Void)?
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    
    func setup() {
        checkAndRequestAccessibility()
        setupGlobalHotkey()
    }
    
    private func checkAndRequestAccessibility() {
        let trusted = AXIsProcessTrusted()
        if !trusted {
            needsAccessibilityPermission = true
        }
    }
    
    func requestAccessibilityPermission() {
        let options = ["AXIsProcessTrustedOptionPrompt" as CFString: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }
    
    private func setupGlobalHotkey() {
        let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue)
        
        let callback: CGEventTapCallBack = { proxy, type, event, refcon in
            guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
            let service = Unmanaged<QuickCaptureService>.fromOpaque(refcon).takeUnretainedValue()
            
            if type == .keyDown {
                let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
                let flags = event.flags
                
                let hasCmd = flags.contains(.maskCommand)
                let hasShift = flags.contains(.maskShift)
                
                if hasCmd && hasShift && keyCode == 17 {
                    Task { @MainActor in
                        service.showCapturePanel()
                    }
                    return nil
                }
            }
            
            return Unmanaged.passUnretained(event)
        }
        
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        eventTap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap, eventsOfInterest: eventMask, callback: callback, userInfo: selfPtr)
        
        guard let eventTap = eventTap else {
            return
        }
        
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
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
    
    func cleanup() {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
    }
}
