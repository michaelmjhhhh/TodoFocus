# Deep Focus Timer Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a configurable timer to Deep Focus sessions. Users choose "Timed" (enter custom minutes) or "Infinite". When timer expires: system notification fires, session auto-ends, focus task marked complete.

**Architecture:** Modify `DeepFocusService.startSession()` to accept optional `duration` parameter. Add `Timer.publish` for timed sessions. Create `DeepFocusTimerNotifier` for UNUserNotificationCenter notifications. Update `DeepFocusSetupSheet` with Timed/Infinite toggle.

**Tech Stack:** SwiftUI, Observation, UNUserNotificationCenter, Timer.publish, GRDB

---

## Task 1: Create DeepFocusTimerNotifier

**Files:**
- Create: `macos/TodoFocusMac/Sources/App/DeepFocusTimerNotifier.swift`

**Step 1: Write the failing test**

Create test file first:
```swift
// macos/TodoFocusMac/Tests/CoreTests/DeepFocusTimerNotifierTests.swift
import XCTest
@testable import TodoFocusMac

final class DeepFocusTimerNotifierTests: XCTestCase {
    func testNotificationContent() async {
        let notifier = DeepFocusTimerNotifier()
        let report = DeepFocusReport(
            duration: 1500, // 25 minutes
            distractionCount: 3,
            blockedApps: ["com.apple.MobileSMS"],
            focusTaskTitle: "Test Task",
            stats: DeepFocusStats(),
            focusTaskId: "test-id"
        )
        // Verify notifier can format notification content
        let content = notifier.formatNotificationContent(from: report)
        XCTAssertTrue(content.contains("25"))
        XCTAssertTrue(content.contains("3"))
    }
}
```

Run: `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS" -only-testing:DeepFocusTimerNotifierTests`
Expected: FAIL - file doesn't exist

**Step 2: Create DeepFocusTimerNotifier.swift**

```swift
import Foundation
import UserNotifications

final class DeepFocusTimerNotifier {
    private let notificationCenter = UNUserNotificationCenter.current()
    private let categoryIdentifier = "DEEP_FOCUS_COMPLETE"

    init() {
        setupNotificationCategory()
    }

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound])
            return granted
        } catch {
            return false
        }
    }

    func notifySessionComplete(report: DeepFocusReport) {
        let content = UNMutableNotificationContent()
        content.title = "Focus Session Complete"
        content.body = formatNotificationContent(from: report)
        content.sound = .default
        content.categoryIdentifier = categoryIdentifier

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Fire immediately
        )

        notificationCenter.add(request) { error in
            if let error {
                print("Failed to deliver notification: \(error)")
            }
        }
    }

    func formatNotificationContent(from report: DeepFocusReport) -> String {
        let minutes = Int(report.duration / 60)
        let minutesText = minutes == 1 ? "minute" : "minutes"
        let distractionText = report.distractionCount == 1 ? "distraction" : "distractions"
        return "You focused for \(minutes) \(minutesText). \(report.distractionCount) \(distractionText)."
    }

    private func setupNotificationCategory() {
        let category = UNNotificationCategory(
            identifier: categoryIdentifier,
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        notificationCenter.setNotificationCategories([category])
    }
}
```

**Step 3: Run test to verify it passes**

Run: `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS" -only-testing:DeepFocusTimerNotifierTests`
Expected: PASS

**Step 4: Commit**

```bash
git add macos/TodoFocusMac/Sources/App/DeepFocusTimerNotifier.swift macos/TodoFocusMac/Tests/CoreTests/DeepFocusTimerNotifierTests.swift
git commit -m "$(cat <<'EOF'
feat: add DeepFocusTimerNotifier for session complete notifications

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Add markComplete method to TodoAppStore

**Files:**
- Modify: `macos/TodoFocusMac/Sources/App/TodoAppStore.swift`

**Step 1: Write the failing test**

```swift
// In TodoAppStoreTests.swift
func testMarkCompleteMarksTodoAsCompleted() throws {
    let todo = try todoRepository.addTodo(
        AddTodoInput(title: "Test", listID: nil, isMyDay: false, isImportant: false, planned: false),
        now: Date()
    )

    try store.markComplete(todoId: todo.todo.id)

    let updated = try todoRepository.fetchTodo(id: todo.todo.id)
    XCTAssertTrue(updated?.isCompleted ?? false)
}
```

Run: `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS" -only-testing:TodoAppStoreTests`
Expected: FAIL - `markComplete` doesn't exist

**Step 2: Add markComplete method to TodoAppStore**

Add this method after `toggleComplete` (around line 97):

```swift
func markComplete(todoId: String) throws {
    var input = UpdateTodoInput()
    input.isCompleted = true
    try todoRepository.updateTodo(id: todoId, input: input, now: now())
    try reload()
    NSSound(named: NSSound.Name("Pop"))?.play()
}
```

**Step 3: Run test to verify it passes**

Run: `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS" -only-testing:TodoAppStoreTests`
Expected: PASS

**Step 4: Commit**

```bash
git add macos/TodoFocusMac/Sources/App/TodoAppStore.swift
git commit -m "$(cat <<'EOF'
feat: add markComplete method to TodoAppStore

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Modify DeepFocusService with duration parameter and timer

**Files:**
- Modify: `macos/TodoFocusMac/Sources/App/DeepFocusService.swift`
- Modify: `macos/TodoFocusMac/Sources/App/TodoAppStore.swift` (update startDeepFocus call)

**Step 1: Write failing tests**

```swift
// In DeepFocusServiceTests.swift
func testStartSessionWithDurationSetsTimer() {
    let service = DeepFocusService()
    service.startSession(blockedApps: [], duration: 60, focusTaskId: "test-id")

    XCTAssertTrue(service.isActive)
    XCTAssertNotNil(service.sessionStartTime)
    // Timer will fire after 60 seconds in real usage
}

func testStartSessionWithNilDurationRunsInfinite() {
    let service = DeepFocusService()
    service.startSession(blockedApps: [], duration: nil, focusTaskId: "test-id")

    XCTAssertTrue(service.isActive)
    // No timer should be set
}
```

Run: `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS" -only-testing:DeepFocusServiceTests`
Expected: FAIL - `startSession` doesn't accept `duration` parameter

**Step 2: Modify DeepFocusService.startSession signature and add timer logic**

Replace the `DeepFocusService` class with:

```swift
@Observable
@MainActor
final class DeepFocusService {
    private var stats: DeepFocusStats = DeepFocusStats()
    var isActive: Bool = false
    var lastReport: DeepFocusReport?
    var currentSessionId: String?
    var currentFocusTaskId: String?
    var blockedApps: Set<String> = []
    var distractionAttempts: [String: Int] = [:]
    var distractionAppNames: [String: String] = [:]
    var onEndFocusSession: ((DeepFocusReport?) -> Void)?

    private var sessionStartTime: Date?
    private var overlayWindow: NSWindow?
    private var appMonitor: NSObjectProtocol?
    private var timerCancellable: AnyCancellable?
    private var timerNotifier = DeepFocusTimerNotifier()
    private var onTimerComplete: (() -> Void)?

    func startSession(blockedApps: [String], duration: TimeInterval?, focusTaskId: String, onTimerComplete: (() -> Void)? = nil) {
        // End any existing session first
        if isActive {
            _ = endSession()
        }

        self.blockedApps = Set(blockedApps)
        self.currentFocusTaskId = focusTaskId
        self.currentSessionId = UUID().uuidString
        self.sessionStartTime = Date()
        self.isActive = true
        self.onTimerComplete = onTimerComplete

        // Request notification permission if we have a duration
        if let duration, duration > 0 {
            Task {
                _ = await timerNotifier.requestAuthorization()
            }
            startTimer(duration: duration)
        }

        startMonitoring()
    }

    private func startTimer(duration: TimeInterval) {
        timerCancellable = Timer.publish(every: duration, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.handleTimerComplete()
            }
    }

    private func handleTimerComplete() {
        timerCancellable?.cancel()
        timerCancellable = nil

        guard let report = endSession() else { return }

        // Show notification
        timerNotifier.notifySessionComplete(report: report)

        // Mark task complete
        onTimerComplete?()

        // Show report (handled by onEndFocusSession callback in UI)
    }

    func endSession() -> DeepFocusReport? {
        timerCancellable?.cancel()
        timerCancellable = nil

        guard isActive, let sessionId = currentSessionId, let startTime = sessionStartTime else {
            return nil
        }

        let duration = Date().timeIntervalSince(startTime)
        let sessionDistractionCount = distractionAttempts.values.reduce(0, +)
        stats.totalFocusTime += duration
        stats.sessionCount += 1
        stats.distractionCount += sessionDistractionCount
        stats.save()

        let report = DeepFocusReport(
            duration: duration,
            distractionCount: sessionDistractionCount,
            blockedApps: Array(blockedApps),
            focusTaskTitle: nil,
            stats: stats,
            focusTaskId: currentFocusTaskId
        )
        lastReport = report

        hideOverlay()
        reset()
        onEndFocusSession?(report)
        return report
    }

    // ... rest of existing methods unchanged ...
}
```

**Step 3: Update TodoAppStore.startDeepFocus**

Change `startDeepFocus(blockedApps: String, focusTaskId: String)` to:

```swift
func startDeepFocus(blockedApps: [String], duration: TimeInterval?, focusTaskId: String) {
    appModel.deepFocusService.startSession(
        blockedApps: blockedApps,
        duration: duration,
        focusTaskId: focusTaskId,
        onTimerComplete: { [weak self] in
            try? self?.markComplete(todoId: focusTaskId)
        }
    )
}
```

**Step 4: Run tests to verify they pass**

Run: `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS" -only-testing:DeepFocusServiceTests`
Expected: PASS

**Step 5: Commit**

```bash
git add macos/TodoFocusMac/Sources/App/DeepFocusService.swift macos/TodoFocusMac/Sources/App/TodoAppStore.swift
git commit -m "$(cat <<'EOF'
feat: add duration timer to DeepFocusService

- Add duration parameter to startSession
- Add Timer.publish for timed sessions
- Auto-end session and notify when timer fires
- Mark focus task complete on timer end

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: Update DeepFocusSetupSheet with Timed/Infinite toggle

**Files:**
- Modify: `macos/TodoFocusMac/Sources/Features/TaskDetail/TaskDetailView.swift` (DeepFocusSetupSheet)

**Step 1: Write the failing test**

```swift
func testDeepFocusSetupSheetHasTimedAndInfiniteOptions() {
    let sheet = DeepFocusSetupSheet(
        selectedApps: .constant([]),
        onStart: {},
        onCancel: {}
    )

    // Verify sheet has Timed/Infinite picker
    // This requires UI test framework
}
```

**Step 2: Modify DeepFocusSetupSheet**

Replace the `DeepFocusSetupSheet` struct (starting at line 538) with:

```swift
struct DeepFocusSetupSheet: View {
    @Binding var selectedApps: Set<String>
    let onStart: (TimeInterval?) -> Void  // Changed: now passes duration
    let onCancel: () -> Void
    @State private var customApps: [(name: String, bundleId: String)] = []
    @State private var isTimedMode: Bool = true
    @State private var minutes: Int = 25

    private let availableApps: [(name: String, bundleId: String)] = [
        ("Messages", "com.apple.MobileSMS"),
        ("Safari", "com.apple.Safari"),
        ("Chrome", "com.google.Chrome"),
        ("Mail", "com.apple.mail"),
        ("Twitter/X", "com.twitter.twitter-mac"),
        ("Slack", "com.tinyspeck.slackmacgap"),
        ("Discord", "com.hnc.Discord"),
        ("Spotify", "com.spotify.client")
    ]

    private let minuteFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimum = 1
        formatter.maximum = 480  // 8 hours max
        return formatter
    }()

    private func getBundleIdentifier(from appURL: URL) -> String? {
        if let bundle = Bundle(url: appURL),
           let bundleId = bundle.bundleIdentifier {
            return bundleId
        }
        return appURL.deletingPathExtension().lastPathComponent
    }

    private func addCustomApp() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.message = "Select an app to block"

        if panel.runModal() == .OK, let url = panel.url {
            if let bundleId = getBundleIdentifier(from: url) {
                let name = url.deletingPathExtension().lastPathComponent
                if !customApps.contains(where: { $0.bundleId == bundleId }) && !availableApps.contains(where: { $0.bundleId == bundleId }) {
                    customApps.append((name: name, bundleId: bundleId))
                }
            }
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Start Deep Focus")
                .font(.headline)
                .padding(.top, 20)

            // Timer Mode Picker
            VStack(spacing: 12) {
                Picker("Focus Mode", selection: $isTimedMode) {
                    Text("Timed").tag(true)
                    Text("Infinite").tag(false)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)

                if isTimedMode {
                    HStack(spacing: 8) {
                        TextField("Minutes", value: $minutes, formatter: minuteFormatter)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                            .onChange(of: minutes) { _, newValue in
                                if newValue < 1 { minutes = 1 }
                                if newValue > 480 { minutes = 480 }
                            }

                        Text("minutes")
                            .foregroundStyle(VisualTokens.textSecondary)

                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                } else {
                    Text("Session runs until you manually end it")
                        .font(.caption)
                        .foregroundStyle(VisualTokens.textSecondary)
                        .padding(.horizontal, 20)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isTimedMode)

            Text("Select apps to block during focus session")
                .font(.subheadline)
                .foregroundStyle(VisualTokens.textSecondary)

            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(availableApps, id: \.bundleId) { app in
                        appRow(name: app.name, bundleId: app.bundleId)
                    }

                    if !customApps.isEmpty {
                        Divider()
                            .padding(.vertical, 4)

                        ForEach(customApps, id: \.bundleId) { app in
                            appRow(name: app.name, bundleId: app.bundleId)
                                .contextMenu {
                                    Button("Remove") {
                                        customApps.removeAll { $0.bundleId == app.bundleId }
                                        selectedApps.remove(app.bundleId)
                                    }
                                }
                        }
                    }

                    Button {
                        addCustomApp()
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle")
                            Text("Add Custom App")
                        }
                        .foregroundStyle(VisualTokens.accentTerracotta)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 8)
                }
                .padding(.horizontal, 20)
            }
            .frame(maxHeight: 250)

            HStack(spacing: 12) {
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(VisualTokens.bgFloating, in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(VisualTokens.textPrimary)

                Button("Start") {
                    let duration: TimeInterval? = isTimedMode ? TimeInterval(minutes * 60) : nil
                    onStart(duration)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(VisualTokens.accentTerracotta, in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(.white)
            }
            .padding(.bottom, 20)
        }
        .frame(width: 300)
        .background(VisualTokens.panelBackground)
    }

    private func appRow(name: String, bundleId: String) -> some View {
        HStack {
            Image(systemName: selectedApps.contains(bundleId) ? "checkmark.square.fill" : "square")
                .foregroundStyle(selectedApps.contains(bundleId) ? VisualTokens.accentTerracotta : VisualTokens.textTertiary)

            Text(name)
                .foregroundStyle(VisualTokens.textPrimary)

            Spacer()
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            if selectedApps.contains(bundleId) {
                selectedApps.remove(bundleId)
            } else {
                selectedApps.insert(bundleId)
            }
        }
    }
}
```

**Step 3: Update TaskDetailView to pass duration to onStart**

Change the sheet call (around line 84) to:

```swift
.sheet(isPresented: $showDeepFocusSheet) {
    DeepFocusSetupSheet(
        selectedApps: $selectedBlockedApps,
        onStart: { duration in
            if let focusTaskId = todo?.id {
                store.startDeepFocus(blockedApps: Array(selectedBlockedApps), duration: duration, focusTaskId: focusTaskId)
            }
            showDeepFocusSheet = false
        },
        onCancel: {
            showDeepFocusSheet = false
        }
    )
}
```

**Step 4: Build to verify**

Run: `xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"`
Expected: BUILD SUCCEEDED

**Step 5: Commit**

```bash
git add macos/TodoFocusMac/Sources/Features/TaskDetail/TaskDetailView.swift
git commit -m "$(cat <<'EOF'
feat: add Timed/Infinite toggle to DeepFocusSetupSheet

- Add segmented picker for Timed vs Infinite mode
- Timed mode shows minutes input (default 25)
- Start button passes duration to startDeepFocus
- UI animates between mode selections

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: Run full test suite

**Step 1: Run all tests**

Run: `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"`
Expected: ALL TESTS PASS

**Step 2: Commit any test fixes if needed**

---

## Summary

| Task | Files | Description |
|------|-------|-------------|
| 1 | DeepFocusTimerNotifier.swift (new) | UNUserNotificationCenter wrapper |
| 2 | TodoAppStore.swift | Add `markComplete(todoId:)` |
| 3 | DeepFocusService.swift | Add duration param, timer logic |
| 4 | TaskDetailView.swift | Timed/Infinite UI toggle |

**Execution Options:**

1. **Subagent-Driven (this session)** - I dispatch fresh subagent per task, review between tasks, fast iteration

2. **Parallel Session (separate)** - Open new session with executing-plans, batch execution with checkpoints

Which approach?
