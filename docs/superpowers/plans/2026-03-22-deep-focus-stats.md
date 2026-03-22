# Deep Focus Stats - Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add usage statistics tracking and end-of-session popup report for Deep Focus sessions, showing: total focus time, session count, and interruption count.

**Architecture:** 
- Track stats in `DeepFocusService` using a new `DeepFocusStats` struct stored in `UserDefaults`
- Show `DeepFocusReportView` as a modal sheet at session end
- Use existing `DeepFocusOverlayView` pattern for the popup presentation

**Tech Stack:** SwiftUI, UserDefaults, Observation

---

## Chunk 1: Data Model & Stats Tracking

### Files:
- Modify: `macos/TodoFocusMac/Sources/App/DeepFocusService.swift:1-50`
- Modify: `macos/TodoFocusMac/Sources/App/DeepFocusService.swift:150-200`

- [ ] **Step 1: Add DeepFocusStats struct**

In `DeepFocusService.swift`, add after the existing imports:

```swift
struct DeepFocusStats: Codable {
    var totalFocusTime: TimeInterval = 0
    var sessionCount: Int = 0
    var interruptionCount: Int = 0
    
    static let key = "deepFocusStats"
    
    static func load() -> DeepFocusStats {
        guard let data = UserDefaults.standard.data(forKey: key),
              let stats = try? JSONDecoder().decode(DeepFocusStats.self, from: data) 
        else { return DeepFocusStats() }
        return stats
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: DeepFocusStats.key)
        }
    }
}
```

- [ ] **Step 2: Add stats property to DeepFocusService**

Add to `DeepFocusService` class:
```swift
private var stats: DeepFocusStats = DeepFocusStats()
```

- [ ] **Step 3: Add stats tracking to startSession**

In `startSession` method, reset interruption tracking:
```swift
sessionStartTime = Date()
interruptionCount = 0
```

- [ ] **Step 4: Add interruption tracking**

Add a new method:
```swift
func recordInterruption() {
    interruptionCount += 1
}
```

- [ ] **Step 5: Add stats accumulation to endSession**

In `endSession` method, before calculating report:
```swift
let duration = Date().timeIntervalSince(sessionStartTime ?? Date())
stats.totalFocusTime += duration
stats.sessionCount += 1
stats.interruptionCount += interruptionCount
stats.save()
```

- [ ] **Step 6: Update DeepFocusReport struct to include stats**

Modify the return type of `endSession` to include stats:
```swift
struct DeepFocusReport {
    let duration: TimeInterval
    let interruptionCount: Int
    let blockedApps: [String]
    let focusTaskTitle: String?
    let stats: DeepFocusStats  // NEW
}
```

- [ ] **Step 7: Update endSession to pass stats**

In `endSession`:
```swift
return DeepFocusReport(
    duration: duration,
    interruptionCount: interruptionCount,
    blockedApps: blockedApps,
    focusTaskTitle: currentFocusTask?.title,
    stats: stats  // NEW
)
```

- [ ] **Step 8: Run build to verify**

```bash
xcodebuild build -project macos/TodoFocusMac/TodoFocusMac.xcodeproj -scheme TodoFocusMac -configuration Debug -destination platform=macOS
```

Expected: BUILD SUCCEEDED

---

## Chunk 2: Report View UI

### Files:
- Create: `macos/TodoFocusMac/Sources/Features/Common/DeepFocusStatsReportView.swift`
- Modify: `macos/TodoFocusMac/Sources/Features/Common/DeepFocusReportView.swift:1-20`

- [ ] **Step 1: Create DeepFocusStatsReportView**

```swift
import SwiftUI

struct DeepFocusStatsReportView: View {
    let stats: DeepFocusStats
    
    private var formattedTotalTime: String {
        let hours = Int(stats.totalFocusTime) / 3600
        let minutes = (Int(stats.totalFocusTime) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Deep Focus Stats")
                .font(.headline)
            
            HStack(spacing: 24) {
                StatCard(
                    icon: "clock.fill",
                    value: formattedTotalTime,
                    label: "Total Time"
                )
                
                StatCard(
                    icon: "number.circle.fill",
                    value: "\(stats.sessionCount)",
                    label: "Sessions"
                )
                
                StatCard(
                    icon: "bell.slash.fill",
                    value: "\(stats.interruptionCount)",
                    label: "Interruptions"
                )
            }
        }
        .padding()
    }
}

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color(hex: "C46849"))
            Text(value)
                .font(.title.weight(.semibold))
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
```

- [ ] **Step 2: Verify build**

---

## Chunk 3: Integrate Report into Session End Flow

### Files:
- Modify: `macos/TodoFocusMac/Sources/Features/Common/DeepFocusOverlayView.swift:80-120`

- [ ] **Step 1: Update DeepFocusOverlayView to show stats**

Find where `showReport` binding is used and add stats report section:

```swift
// Add after the existing report section in DeepFocusOverlayView
if showReport, let report = appModel.deepFocusService.lastReport {
    VStack {
        // Existing DeepFocusReportView content...
        
        // NEW: Stats section
        Divider()
        DeepFocusStatsReportView(stats: report.stats)
    }
    .padding()
}
```

- [ ] **Step 2: Add lastReport property to DeepFocusService**

Add to `DeepFocusService`:
```swift
var lastReport: DeepFocusReport?
```

- [ ] **Step 3: Set lastReport in endSession**

In `endSession` method:
```swift
let report = DeepFocusReport(...)
lastReport = report  // NEW
return report
```

- [ ] **Step 4: Verify build**

---

## Chunk 4: Testing

### Files:
- Modify: `macos/TodoFocusMac/Tests/CoreTests/DeepFocusServiceTests.swift` (create if not exists)

- [ ] **Step 1: Create basic test for stats tracking**

```swift
import XCTest
@testable import TodoFocusMac

final class DeepFocusServiceTests: XCTestCase {
    func testStatsAccumulation() async {
        let service = DeepFocusService()
        
        // Start and end a session
        service.startSession(blockedApps: [], focusTaskId: nil)
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        service.endSession()
        
        // Verify stats updated
        XCTAssertEqual(service.stats.sessionCount, 1)
        XCTAssertGreaterThan(service.stats.totalFocusTime, 0)
    }
    
    func testInterruptionTracking() async {
        let service = DeepFocusService()
        
        service.startSession(blockedApps: [], focusTaskId: nil)
        service.recordInterruption()
        service.recordInterruption()
        service.endSession()
        
        XCTAssertEqual(service.stats.interruptionCount, 2)
    }
}
```

- [ ] **Step 2: Run tests**

```bash
xcodebuild test -project macos/TodoFocusMac/TodoFocusMac.xcodeproj -scheme TodoFocusMac -destination "platform=macOS"
```

---

## Summary

After implementation:
- Deep Focus sessions will automatically track time, session count, and interruptions
- Stats persist in UserDefaults across app launches
- End-of-session report includes a "Stats" section showing cumulative data
- Simple, clean UI with 3 stat cards

## Notes

- UserDefaults chosen for simplicity; data is lightweight
- Stats are cumulative (lifetime totals), not per-session
- If user wants per-session breakdown later, can extend DeepFocusReport
