# Quick Capture Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement global Quick Capture that appends to current focus task's notes when Deep Focus is active, or shows task picker when not.

**Architecture:**
- Uses `NSEvent.addGlobalMonitorForEvents` to capture Cmd+Shift+T anywhere on system
- Floating `NSPanel` for quick capture input
- If Deep Focus active → append to focus task's notes with timestamp
- If no Deep Focus → show task picker or add to Inbox (future)
- Focus task stored in `AppModel`

**Tech Stack:** SwiftUI + AppKit (NSPanel, NSEvent global monitor), GRDB

---

## Chunk 1: Core Quick Capture Window

### Task 1: Create QuickCapturePanel (NSPanel)

**Files:**
- Create: `macos/TodoFocusMac/Sources/Features/QuickCapture/QuickCapturePanel.swift`

- [ ] **Step 1: Create QuickCapturePanel.swift**

```swift
import AppKit

class QuickCapturePanel: NSPanel {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 120),
            styleMask: [.titled, .closable, .nonactivatingPanel, .hudWindow],
            backing: .buffered,
            defer: false
        )
        self.level = .floating
        self.isFloatingPanel = true
        self.becomesKeyOnlyIfNeeded = true
        self.hidesOnDeactivate = false
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.isMovableByWindowBackground = true
        self.backgroundColor = NSColor.windowBackgroundColor
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    }
    
    func showAtCenter() {
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - 200
            let y = screenFrame.midY - 60
            self.setFrameOrigin(NSPoint(x: x, y: y))
        }
        self.makeKeyAndOrderFront(nil)
    }
}
```

- [ ] **Step 2: Build and verify**

- [ ] **Step 3: Commit**

---

### Task 2: Create QuickCaptureView (SwiftUI in NSHostingView)

**Files:**
- Create: `macos/TodoFocusMac/Sources/Features/QuickCapture/QuickCaptureView.swift`

- [ ] **Step 1: Create QuickCaptureView.swift**

```swift
import SwiftUI

struct QuickCaptureView: View {
    @Binding var text: String
    let onSubmit: () -> Void
    let onCancel: () -> Void
    let targetInfo: String
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(Color(hex: "C46849"))
                Text("Quick Capture")
                    .font(.headline)
                Spacer()
                Text(targetInfo)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            TextField("Capture a thought...", text: $text)
                .textFieldStyle(.roundedBorder)
                .onSubmit(onSubmit)
            
            HStack {
                Spacer()
                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.escape)
                
                Button("Add") {
                    onSubmit()
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(16)
        .frame(width: 400, height: 120)
    }
}

class QuickCaptureHostingView: NSHostingView<QuickCaptureView> {
    init(onSubmit: @escaping (String) -> Void, onCancel: @escaping () -> Void, targetInfo: String) {
        self.onSubmit = onSubmit
        self.onCancel = onCancel
        self.targetInfo = targetInfo
        
        var text = ""
        super.init(rootView: QuickCaptureView(
            text: Binding(
                get: { text },
                set: { text = $0 }
            ),
            onSubmit: { self.handleSubmit(text) },
            onCancel: { self.onCancel() },
            targetInfo: targetInfo
        ))
    }
    
    private let onSubmit: (String) -> Void
    private let onCancel: () -> Void
    private let targetInfo: String
    
    private func handleSubmit(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        onSubmit(text)
    }
    
    @MainActor required dynamic init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
```

- [ ] **Step 2: Build and verify**

- [ ] **Step 3: Commit**

---

## Chunk 2: Quick Capture Service

### Task 3: Create QuickCaptureService

**Files:**
- Create: `macos/TodoFocusMac/Sources/App/QuickCaptureService.swift`

- [ ] **Step 1: Create QuickCaptureService.swift**

```swift
import AppKit
import Observation

@Observable
@MainActor
final class QuickCaptureService {
    var isVisible: Bool = false
    private var panel: QuickCapturePanel?
    private var globalMonitor: Any?
    private var localMonitor: Any?
    
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
            targetInfo = "No Deep Focus - will show task picker"
        }
        
        let hostingView = QuickCaptureHostingView(
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
        
        if let dfService = deepFocusService, dfService.isActive {
            onCapture?(captureText)
        }
        
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
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
```

- [ ] **Step 2: Build and verify**

- [ ] **Step 3: Commit**

---

## Chunk 3: Integration

### Task 4: Integrate QuickCaptureService into App

**Files:**
- Modify: `macos/TodoFocusMac/Sources/App/AppModel.swift`
- Modify: `macos/TodoFocusMac/Sources/App/TodoAppStore.swift`
- Modify: `macos/TodoFocusMac/Sources/App/TodoFocusMacApp.swift` or `RootView.swift`

- [ ] **Step 1: Add QuickCaptureService to AppModel**

Add to `AppModel.swift`:
```swift
var quickCaptureService: QuickCaptureService = QuickCaptureService()
```

- [ ] **Step 2: Wire up in TodoAppStore or RootView**

In `RootView.swift` or `TodoFocusMacApp.swift`, after store is created:
```swift
appModel.quickCaptureService.deepFocusService = appModel.deepFocusService
appModel.quickCaptureService.onCapture = { [weak store] text in
    store?.appendToFocusTaskNotes(text)
}
appModel.quickCaptureService.setup()
```

- [ ] **Step 3: Add appendToFocusTaskNotes method to TodoAppStore**

```swift
func appendToFocusTaskNotes(_ text: String) {
    guard let focusTaskId = appModel.deepFocusService.currentFocusTaskId else { return }
    guard let todo = todos.first(where: { $0.id == focusTaskId }) else { return }
    
    let currentNotes = todo.notes ?? ""
    let newNotes = currentNotes.isEmpty ? text : currentNotes + text
    updateNotesDebounced(todoId: focusTaskId, notes: newNotes)
}
```

- [ ] **Step 4: Add shortcut hint to ShortcutHintBar**

Add "⌘⇧T" hint for Quick Capture

- [ ] **Step 5: Build and verify**

- [ ] **Step 6: Commit**

---

## Chunk 4: Deep Focus Integration Enhancement

### Task 5: Track current focus task in DeepFocusService

**Files:**
- Modify: `macos/TodoFocusMac/Sources/App/DeepFocusService.swift`
- Modify: `macos/TodoFocusMac/Sources/App/TodoAppStore.swift`

- [ ] **Step 1: Add focusTaskId to DeepFocusService**

Add property:
```swift
var currentFocusTaskId: String?
```

Update `startSession`:
```swift
func startSession(blockedApps: [String], focusTaskId: String) {
    self.blockedApps = Set(blockedApps)
    self.currentSessionId = UUID().uuidString
    self.sessionStartTime = Date()
    self.isActive = true
    self.currentFocusTaskId = focusTaskId
    startMonitoring()
}
```

- [ ] **Step 2: Update TodoAppStore.startDeepFocus**

```swift
func startDeepFocus(blockedApps: [String], focusTaskId: String) {
    appModel.deepFocusService.startSession(blockedApps: blockedApps, focusTaskId: focusTaskId)
}
```

- [ ] **Step 3: Update TaskDetailView to pass taskId**

When starting Deep Focus from TaskDetailView:
```swift
store.startDeepFocus(blockedApps: Array(selectedBlockedApps), focusTaskId: todo.id)
```

- [ ] **Step 4: Clear on end**

In `endSession` or `reset`, set `currentFocusTaskId = nil`

- [ ] **Step 5: Build and verify**

- [ ] **Step 6: Commit**

---

## Chunk 5: UX Polish

### Task 6: Add visual feedback and polish

**Files:**
- Modify: `macos/TodoFocusMac/Sources/Features/QuickCapture/QuickCaptureView.swift`

- [ ] **Step 1: Add success animation**

When capture is submitted, brief success feedback:
```swift
// Brief scale animation on submit
.scaleEffect(0.98)
.animation(.easeOut(duration: 0.1), value: isSubmitting)
```

- [ ] **Step 2: Add haptic feedback on submit**

```swift
let generator = NSHapticFeedbackManager.defaultGenerator()
generator.perform(.alignment, sensitivity: .medium)
```

- [ ] **Step 3: Build and verify**

- [ ] **Step 4: Commit**

---

## Verification Checklist

- [ ] Cmd+Shift+T opens Quick Capture panel from anywhere
- [ ] When Deep Focus active, text appends to focus task's notes with timestamp
- [ ] When Deep Focus not active, show "No Deep Focus" in target info
- [ ] Cmd+Enter submits capture
- [ ] Escape cancels
- [ ] Panel auto-hides after submission
- [ ] App builds successfully
