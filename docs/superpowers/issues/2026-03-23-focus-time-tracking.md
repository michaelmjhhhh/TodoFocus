# Feature: Focus Time Tracking per Task

## Issue Summary

Track actual focus time spent on each task and generate productivity reports.

**Issue Type:** enhancement

**Priority:** high

---

## Background

TodoFocus already has:
- Deep Focus Mode with app blocking
- Launchpad Tasks that open work context (URLs, files, apps)

**Missing piece**: No tracking of time spent on actual tasks.

## Goals

1. Each task stores cumulative focus time
2. Deep Focus Session结束后，自动关联到当前任务
3. View time tracked per task in detail panel
4. Productivity reports (weekly/monthly)

---

## Technical Design

### Data Model Changes

**New fields on Todo:**
- `focusTimeSeconds: Int` - cumulative seconds spent in focus on this task

**Database migration:**
- Add `focusTimeSeconds INTEGER DEFAULT 0` to todo table

### DeepFocusService Changes

**New state:**
- `currentFocusTaskId: String?` - already exists conceptually via `focusTaskId`
- Track session start time

**On session end:**
- Calculate elapsed time
- Update associated task's `focusTimeSeconds`
- Clear session state

### UI Changes

**TaskDetailView:**
- Show "Focus Time" section displaying tracked time (e.g., "2h 34m")
- Format: Xh Ym or Ym if < 1h

**Sidebar/Stats (new):**
- Weekly focus report view
- Total time, session count, avg session length
- Top tasks by time

---

## Files to Modify

1. `macos/TodoFocusMac/Sources/Core/Models/Todo.swift` - add focusTimeSeconds
2. `macos/TodoFocusMac/Sources/Data/DTO/TodoRecord.swift` - add focusTimeSeconds
3. `macos/TodoFocusMac/Sources/Data/Database/Migrations.swift` - schema migration
4. `macos/TodoFocusMac/Sources/Data/Repositories/TodoRepository.swift` - update/fetch with focusTime
5. `macos/TodoFocusMac/Sources/App/DeepFocusService.swift` - track session time
6. `macos/TodoFocusMac/Sources/App/TodoAppStore.swift` - add/update focus time methods
7. `macos/TodoFocusMac/Sources/Features/TaskDetail/TaskDetailView.swift` - show focus time
8. `macos/TodoFocusMac/Sources/Features/Common/DeepFocusReportView.swift` - extend for stats
9. `macos/TodoFocusMac/Tests/CoreTests/` - add time tracking tests

---

## Implementation Order

1. Schema migration + DTO changes
2. DeepFocusService: track session duration
3. TodoAppStore: update focus time on task
4. TaskDetailView: display focus time
5. DeepFocusReportView: extend with time stats
6. Tests

---

## Verification

```bash
xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"
xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -configuration Release
```
