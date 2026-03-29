## Summary
Closes #73.

Aligns tests with current production API and actor isolation rules so `xcodebuild test` passes again.

## What Changed
- Updated Core test files to respect `@MainActor` isolation for `AppModel` / `TodoAppStore` usage.
- Updated tests to match current API signatures and model fields:
  - `DeepFocusService.startSession(..., duration:, ...)`
  - `CoreTodo.isCompleted`
- Replaced Deep Focus stats assertions in tests to use public report output instead of private service internals.
- Removed outdated test that referenced removed API `TaskDetailView.shouldShowDueDateClearButton`.
- Fixed `AgentHeartbeatRecord` GRDB column mapping by adding explicit `CodingKeys` for snake_case DB columns.

## Why
Recent production changes (actor isolation + API evolution + schema naming) caused test compile/runtime failures. This PR restores test compatibility without changing product behavior.

## Verification
Ran on macOS locally:

```bash
cd macos/TodoFocusMac
xcodebuild test -project "TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"
xcodebuild build -project "TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -configuration Release -derivedDataPath "build/DerivedData" -destination "platform=macOS"
```

Both commands succeeded.

## Notes
`xcodebuild` still reports existing project warnings about duplicate file-reference group membership under `Sources/Data/*`. Not changed in this PR.
