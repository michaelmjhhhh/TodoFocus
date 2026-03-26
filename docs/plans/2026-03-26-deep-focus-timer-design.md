# Deep Focus Timer Feature Design

## Overview

Add a configurable timer to Deep Focus sessions. Users can choose "Timed" (enter custom minutes) or "Infinite" mode. When a timed session ends, the app shows a macOS system notification, auto-ends the session, and marks the focus task as complete.

## User Flow

1. User selects a task and taps "Start Focus" (⌘⇧F)
2. A sheet appears with two options:
   - **Timed**: Enter custom minutes (default: 25)
   - **Infinite**: No timer, manual end only
3. User configures choice and confirms
4. Session runs (either timed or infinite)
5. If timed:
   - Timer fires after specified duration
   - System notification: "Focus Session Complete" (shows duration + distractions)
   - Session auto-ends
   - Focus task is marked complete
6. DeepFocusReport displays (same as manual end)

## Architecture

### Modified Files

**`DeepFocusService`**
- Add `duration: TimeInterval?` parameter to `startSession(blockedApps:duration:focusTaskId:)`
- Add internal timer via `Timer.publish` that fires when duration expires
- When timer fires: call `endSession()`, trigger notification, mark task complete
- If duration is `nil` or `0`, session runs infinite (no timer)

**`DeepFocusTimerNotifier` (NEW)**
- Handles `UNUserNotificationCenter` permission request
- Fires "Focus Session Complete" notification with session summary (duration, distraction count)

**UI: Start Focus Sheet**
- Toggle between "Timed" and "Infinite" modes
- If Timed: `TextField` for minutes (NumberFormatter, min 1), pre-filled with 25
- Start button confirms choice

### Key Decisions

| Decision | Choice |
|----------|--------|
| Default duration | 25 minutes |
| Duration persistence | None - user chooses each session |
| Notification style | macOS system notification (UNUserNotificationCenter) |
| Task completion on timer end | Auto-mark complete (no prompt) |
| Infinite sessions | Available via "Infinite" option at start |

### Data Flow

```
startSession(blockedApps: [String], duration: TimeInterval?, focusTaskId: String)
    │
    ├─ If duration != nil && duration > 0:
    │   └─ Timer.publish(every: duration, on: .main, in: .common)
    │       └─ on timer fire:
    │           ├─ endSession()
    │           ├─ DeepFocusTimerNotifier.notifySessionComplete(report)
    │           └─ TodoAppStore.markComplete(focusTaskId)
    │
    └─ If duration == nil || duration == 0:
        └─ No timer, session runs until manual endSession() call
```

### Error Handling

- **Notification permission denied**: Session still ends, notification silently skipped
- **Timer already running + new session starts**: Old session ends first, new one begins
- **App quit before timer fires**: Timer is lost - user must restart session

## File Changes Summary

| File | Change |
|------|--------|
| `Sources/App/DeepFocusService.swift` | Add duration param, timer logic |
| `Sources/App/DeepFocusTimerNotifier.swift` | NEW - notification handling |
| `Sources/Features/Common/DeepFocusOverlayView.swift` | Add start focus sheet UI |
| `Sources/App/TodoAppStore.swift` | Add `markComplete(todoId:)` method |
| `Sources/App/AppModel.swift` | Add UI state for duration input |

## Notification Content

**Title**: "Focus Session Complete"
**Body**: "You focused for X minutes. Distractions: Y"
**Sound**: Default system sound
