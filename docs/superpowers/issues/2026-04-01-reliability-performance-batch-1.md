# Reliability + Performance Batch 1

- Date: 2026-04-01
- Issue: #131
- Branch: `fix/reliability-performance-batch-1`
- Workflow: `systematic-debugging` + `dispatching-parallel-agents`

## Scope

Fix 7 confirmed findings from repository review:

1. QuickCapture hotkey tap idempotency
2. QuickCapture callback lifetime safety
3. Export snapshot atomicity
4. Import launch-resource validation parity
5. Task list visible/filter recomputation hot path
6. Detail panel width persistence write frequency
7. Daily Review due date formatter allocation

## Evidence

### 1) Hotkey tap idempotency
- `macos/TodoFocusMac/Sources/App/QuickCaptureService.swift`
- Repeated setup can register duplicate event taps/sources.

### 2) Callback lifetime safety
- `macos/TodoFocusMac/Sources/App/QuickCaptureService.swift`
- C callback context currently risks dangling-pointer lifecycle.

### 3) Export snapshot atomicity
- `macos/TodoFocusMac/Sources/Data/Export/ExportService.swift`
- Lists and todos are loaded in separate reads, risking cross-table inconsistency.

### 4) Import validation parity
- `macos/TodoFocusMac/Sources/Data/Export/ExportService.swift`
- URL resources on import need full validation before persistence.

### 5) Task list recomputation hot path
- `macos/TodoFocusMac/Sources/App/TodoAppStore.swift`
- `macos/TodoFocusMac/Sources/Features/TaskList/TaskListView.swift`
- Repeated filter/visible recomputation in render path.

### 6) Detail width persistence churn
- `macos/TodoFocusMac/Sources/RootView.swift`
- `macos/TodoFocusMac/Sources/App/AppModel.swift`
- `macos/TodoFocusMac/Sources/App/WindowPersistence.swift`
- Persisting width on every drag tick causes unnecessary IO.

### 7) Daily Review formatter allocation
- `macos/TodoFocusMac/Sources/Features/Review/DailyReviewView.swift`
- Per-call `DateFormatter` creation in due-date text path.

## Root-Cause Summary

- Lifecycle/concurrency edges around C event tap callback context.
- Snapshot consistency gap in export path.
- Validation mismatch between import and runtime parse rules.
- Repeated computation and persistence in UI hot paths.

## Fix Plan

- Workstream A (Reliability): findings 1-2.
- Workstream B (Data correctness): findings 3-4.
- Workstream C (Performance/UI): findings 5-7.

All three are implemented in parallel with disjoint file ownership and integrated on this branch.

## Acceptance Criteria

- No regressions in QuickCapture behavior.
- Export/import correctness improved with deterministic handling.
- Reduced repeated work in task filtering and width persistence path.
- Daily Review date rendering avoids repeated formatter allocation.
- Build/tests pass on branch before PR.
