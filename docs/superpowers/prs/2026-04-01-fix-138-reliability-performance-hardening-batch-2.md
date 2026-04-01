## Summary
Closes #138

This PR fixes the full reliability/performance audit batch across release integrity, data import/export correctness, concurrency/lifecycle safety, and SwiftUI hot-path performance.

## Changes

### Release / CI correctness
- `release-macos-native` now checks out the tag ref (not `main`) for tagged/manual releases.
- Re-enabled tests inside native release workflow.
- Added manual dispatch tag validation (`v*` format + remote tag existence).
- Added PR/push CI workflow: `.github/workflows/ci-macos-tests.yml`.
- Marked legacy Electron release workflow as legacy and added explicit warning step.
- Fixed AGENTS rollback instruction to rerun `release-macos-native`.

### Data correctness and import/export hardening
- Added export format `1.3` with preserved todo temporal fields:
  - `createdAt`, `updatedAt`, `lastCompletedAt`.
- Export/import now preserves these fields while remaining backward-compatible with `1.0/1.1/1.2`.
- Preflight import now validates todo `listId` references by mode (`replace` vs `merge`).
- Replace import now clears runtime hard-focus tables to avoid stale state carryover.
- Merge import now prevents step ID collision re-parenting across todos (skip + report).
- Backup snapshot path for replace import made resilient to malformed legacy launch-resource payloads.
- Repository launch-resource normalization now enforces strict schema validity and canonical serialization.
- Repository `updateTodo` now enforces title trim/non-empty and clamps negative focus time to 0.

### Concurrency / lifecycle safety
- Hard focus unlock async UI mutations are now explicitly `@MainActor`.
- Task detail now clears `deepFocusService.onEndFocusSession` on disappear.
- Debounced notes writes now use cancellable `Task` + token (latest-write-wins), with DB refresh on failure.

### SwiftUI performance improvements
- Root detail panel drag now updates local live width during drag; persistence happens on drag end.
- Daily Review column cards switched to `LazyVStack`.
- TaskList now caches filtered/active/completed datasets and list-color map, recalculated on relevant state changes.
- Completed column now removes hidden subtree when collapsed (instead of opacity-only hiding).
- `setDueDate` / `updateFocusTime` path reduced full-list churn via targeted todo refresh.

## Verification
- `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"`
  - `** TEST SUCCEEDED **`
- `xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -configuration Release -derivedDataPath "macos/TodoFocusMac/build/DerivedData" -destination "platform=macOS"`
  - `** BUILD SUCCEEDED **`

## Notes
- Added/updated tests for export temporal fidelity, import reference checks, merge step collision handling, and repository invariants.
- No remaining Critical/High blockers from post-fix code review pass.
