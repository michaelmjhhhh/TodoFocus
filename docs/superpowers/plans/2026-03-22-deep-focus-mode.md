# Deep Focus Mode Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement Deep Focus Mode - a soft-blocking focus system that tracks distraction attempts and provides feedback without being overly restrictive.

**Architecture:**
- Deep Focus uses Accessibility API (AXUIElement) to monitor app switching via NSWorkspace notifications
- A floating NSWindow overlay appears when user tries to open a blocked app
- Focus session data stored in GRDB (same as existing data)
- Deep Focus state managed in a new `DeepFocusService` class
- UI integration via new `DeepFocusOverlayView` and `DeepFocusButton`

**Tech Stack:** SwiftUI + AppKit (NSWorkspace, AXUIElement), GRDB, Observation

---

## Chunk 1: Data Models & Service

### Task 1: Create DeepFocusSession model

**Files:**
- Create: `macos/TodoFocusMac/Sources/App/DeepFocusService.swift`
- Modify: `macos/TodoFocusMac/Sources/App/AppModel.swift:1-42`
- Test: Build verification

- [ ] **Step 1: Create DeepFocusService.swift with session model**

```swift
import Foundation
import Observation

@Observable
final class DeepFocusService {
    var isActive: Bool = false
    var currentSessionId: String?
    var blockedApps: Set<String> = []  // Bundle identifiers
    var distractionAttempts: [String: Int] = [:]  // app bundle id -> count
    
    private var appMonitor: Any?
    
    func startSession(blockedApps: [String]) {
        self.isActive = true
        self.currentSessionId = UUID().uuidString
        self.blockedApps = Set(blockedApps)
        self.distractionAttempts = [:]
        startMonitoring()
    }
    
    func endSession() -> DeepFocusReport? {
        guard isActive else { return nil }
        let report = DeepFocusReport(
            sessionId: currentSessionId ?? "",
            blockedApps: Array(blockedApps),
            distractionAttempts: distractionAttempts,
            startTime: Date()...Date(),
            completed: false
        )
        reset()
        return report
    }
    
    func recordDistraction(appBundleId: String) {
        distractionAttempts[appBundleId, default: 0] += 1
    }
    
    private func startMonitoring() {
        // NSWorkspace notification monitoring
    }
    
    private func reset() {
        isActive = false
        currentSessionId = nil
        blockedApps = []
        distractionAttempts = [:]
        stopMonitoring()
    }
    
    private func stopMonitoring() {
        appMonitor = nil
    }
}

struct DeepFocusReport {
    let sessionId: String
    let blockedApps: [String]
    let distractionAttempts: [String: Int]
    let startTime: ClosedRange<Date>
    let completed: Bool
    
    var totalDistractionAttempts: Int {
        distractionAttempts.values.reduce(0, +)
    }
}
```

- [ ] **Step 2: Update AppModel.swift to include DeepFocusService**

Add to `AppModel.swift`:
```swift
var deepFocusService: DeepFocusService = DeepFocusService()
```

- [ ] **Step 3: Build and verify**

---

## Chunk 2: App Monitoring & Overlay

### Task 2: Implement app switching detection

**Files:**
- Modify: `macos/TodoFocusMac/Sources/App/DeepFocusService.swift`

- [ ] **Step 1: Implement NSWorkspace notification monitoring**

```swift
import AppKit

private func startMonitoring() {
    let workspace = NSWorkspace.shared
    let notificationCenter = workspace.notificationCenter
    
    appMonitor = notificationCenter.addObserver(
        forName: NSWorkspace.didActivateApplicationNotification,
        object: nil,
        queue: .main
    ) { [weak self] notification in
        self?.handleAppActivation(notification)
    }
}

private func handleAppActivation(_ notification: Notification) {
    guard isActive,
          let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
          let bundleId = app.bundleIdentifier else { return }
    
    if blockedApps.contains(bundleId) {
        recordDistraction(appBundleId: bundleId)
        showOverlay(for: bundleId)
    }
}
```

- [ ] **Step 2: Add overlay window management**

Add property:
```swift
private var overlayWindow: NSWindow?
```

Add method:
```swift
private func showOverlay(for bundleId: String) {
    // Create or show overlay window
    // Show "Focus Mode Active - You tried to open X"
}
```

- [ ] **Step 3: Build and verify**

---

### Task 3: Create DeepFocusOverlayView

**Files:**
- Create: `macos/TodoFocusMac/Sources/Features/Common/DeepFocusOverlayView.swift`

- [ ] **Step 1: Create SwiftUI overlay view**

```swift
import SwiftUI

struct DeepFocusOverlayView: View {
    let blockedAppName: String
    let attemptCount: Int
    let onDismiss: () -> Void
    let onEndFocus: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "flame.fill")
                .font(.system(size: 48))
                .foregroundColor(Color(hex: "C46849"))
            
            Text("Deep Focus Active")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("You tried to open \(blockedAppName)")
                .foregroundColor(.secondary)
            
            Text("Attempt #\(attemptCount)")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.2))
                .clipShape(Capsule())
            
            HStack(spacing: 16) {
                Button("End Focus") {
                    onEndFocus()
                }
                .buttonStyle(.bordered)
                
                Button("Dismiss") {
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "1C1C1E"))
                .shadow(radius: 20)
        )
        .frame(width: 300)
    }
}
```

- [ ] **Step 2: Create NSWindow wrapper for overlay**

```swift
import AppKit

class DeepFocusOverlayWindow: NSWindow {
    init(contentView: NSView) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 250),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        self.level = .floating
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = true
        self.contentView = contentView
    }
}
```

- [ ] **Step 3: Build and verify**

---

## Chunk 3: UI Integration

### Task 4: Add Deep Focus button to TaskDetailView

**Files:**
- Modify: `macos/TodoFocusMac/Sources/Features/TaskDetail/TaskDetailView.swift`

- [ ] **Step 1: Add "Start Deep Focus" button to task detail**

Add to TaskDetailView where other action buttons are:
```swift
Button {
    showDeepFocusSheet = true
} label: {
    Label("Deep Focus", systemImage: "flame.fill")
}
```

- [ ] **Step 2: Create DeepFocusSetupSheet**

```swift
struct DeepFocusSetupSheet: View {
    @Bindable var store: TodoAppStore
    @Environment(\.dismiss) private var dismiss
    @State private var selectedApps: Set<String> = []
    
    let availableApps: [(id: String, name: String)] = [
        ("com.apple.MobileSMS", "Messages"),
        ("com.apple.Safari", "Safari"),
        ("com.google.Chrome", "Chrome"),
        ("com.twitter.twitter-mac", "X/Twitter"),
        ("com.facebook.Facebook", "Facebook"),
    ]
    
    var body: some View {
        VStack {
            Text("Start Deep Focus")
                .font(.headline)
            
            List(availableApps, selection: $selectedApps) { app in
                Text(app.name)
            }
            
            Button("Start") {
                store.startDeepFocus(blockedApps: Array(selectedApps))
                dismiss()
            }
        }
        .padding()
        .frame(width: 300, height: 400)
    }
}
```

- [ ] **Step 3: Add to TodoAppStore methods**

```swift
func startDeepFocus(blockedApps: [String]) {
    appModel.deepFocusService.startSession(blockedApps: blockedApps)
}

func endDeepFocus() -> DeepFocusReport? {
    appModel.deepFocusService.endSession()
}
```

- [ ] **Step 4: Build and verify**

---

### Task 5: Show Deep Focus report after session

**Files:**
- Create: `macos/TodoFocusMac/Sources/Features/Common/DeepFocusReportView.swift`

- [ ] **Step 1: Create DeepFocusReportView**

```swift
struct DeepFocusReportView: View {
    let report: DeepFocusReport
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 48))
                .foregroundColor(Color(hex: "C46849"))
            
            Text("Focus Session Complete")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 12) {
                LabeledContent("Total distractions", value: "\(report.totalDistractionAttempts)")
                
                ForEach(report.distractionAttempts.sorted(by: { $0.value > $1.value }), id: \.key) { app, count in
                    LabeledContent(app, value: "\(count)")
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Button("Done", action: onDismiss)
                .buttonStyle(.borderedProminent)
        }
        .padding(32)
        .frame(width: 320)
    }
}
```

- [ ] **Step 2: Integrate report display in RootView or TaskDetailView**

- [ ] **Step 3: Build and verify**

---

## Chunk 4: Testing & Polish

### Task 6: Add keyboard shortcut to toggle Deep Focus

**Files:**
- Modify: `macos/TodoFocusMac/Sources/Features/Common/ShortcutHintBar.swift` (if exists)

- [ ] **Step 1: Add Cmd+Shift+F shortcut**

- [ ] **Step 2: Build and verify**

---

## Verification Checklist

- [ ] App builds successfully
- [ ] Deep Focus can be started from task detail
- [ ] Blocked apps trigger overlay
- [ ] Distraction count is tracked
- [ ] Report shows after ending focus
- [ ] No crashes or memory leaks
