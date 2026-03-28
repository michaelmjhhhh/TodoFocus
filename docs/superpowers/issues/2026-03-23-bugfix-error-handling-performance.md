# Bug Fix: Critical Error Handling and Performance Issues

## Issue Summary

Multiple subagents completed a parallel audit of the TodoFocus codebase using `swiftui-expert-skill` and `systematic-debugging` methodologies. This issue tracks the critical bugs found that need immediate fixes.

**Issue Type:** bug

**Priority:** high

**Labels:** bug, performance, error-handling

---

## Root Cause Analysis Summary

### Category 1: Silent Error Swallowing (HIGH Priority)

Multiple operations across the codebase use `try?` which silently swallows errors, making debugging impossible and potentially causing data loss without user notification.

| Location | Problem | Impact |
|----------|---------|--------|
| `TodoAppStore.swift:80` | `try reload()` after successful write - failure ignored | UI out of sync with DB |
| `TodoAppStore.swift:85-91` | `fetchTodo` failure returns silently | Incorrect behavior hidden |
| `TodoAppStore.swift:164-170` | `addStep` uses `try?` - error swallowed | Step add silently fails |
| `TaskListView.swift:50-61` | `quickAdd` catches error but does nothing | User loses task with no feedback |
| `TodoAppStore.swift:203-209` | `deleteList` uses `try?` - failure ignored | Orphaned todos possible |

### Category 2: N+1 Performance Bug (HIGH Priority)

| Location | Problem | Impact |
|----------|---------|--------|
| `TaskListView.swift:328-331` | `colorForList` does O(n) linear search per row | O(n*m) complexity in ForEach |

**Fix:** Pre-compute `Dictionary<listId, Color>` for O(1) lookups.

### Category 3: Resource Leak (MEDIUM Priority)

| Location | Problem | Impact |
|----------|---------|--------|
| `QuickCaptureService.swift:126-135` | `cleanup()` method never called | CGEventTap not released on exit |

---

## Files to Modify

1. `macos/TodoFocusMac/Sources/App/TodoAppStore.swift`
2. `macos/TodoFocusMac/Sources/Features/TaskList/TaskListView.swift`
3. `macos/TodoFocusMac/Sources/Features/TaskDetail/TaskDetailView.swift`
4. `macos/TodoFocusMac/Sources/App/QuickCaptureService.swift`

---

## Tasks

### Task 1: Fix Silent Error Swallowing in TodoAppStore

- [ ] Replace `try?` with proper error handling that logs failures
- [ ] Add `throws` propagation for critical operations
- [ ] Ensure `reload()` failures are surfaced

### Task 2: Fix N+1 colorForList Performance Bug

- [ ] Create `listColorMap: [String: Color]` computed once from `store.lists`
- [ ] Replace `colorForList` calls with O(1) dictionary lookup

### Task 3: Fix CGEventTap Resource Leak

- [ ] Call `quickCaptureService.cleanup()` in `RootView.onDisappear`
- [ ] Or register for app termination notification

### Task 4: Fix Step Add Silent Failure

- [ ] `addStep` should throw on database failure
- [ ] UI should show error feedback when step add fails

### Task 5: Fix QuickAdd Silent Failure

- [ ] Add error feedback mechanism in TaskListView quickAdd
- [ ] Show user-facing error when quickAdd fails

---

## Verification

After fixes:
1. Run: `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"`
2. Verify build succeeds
3. Verify all existing tests pass

---

## References

- SwiftUI Expert Skill: `swiftui-expert-skill` for correctness patterns
- Systematic Debugging: `systematic-debugging` for error handling best practices
- Review commit: Parallel audit by 4 subagents using explore agent type
