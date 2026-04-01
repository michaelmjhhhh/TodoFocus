## Summary
- fix false mutation-error banner shown after timed Deep Focus completion
- treat `HardFocusError.noActiveSession` as benign in Hard Focus teardown paths
- keep real Hard Focus teardown failures visible

## Root Cause
Timed completion could race into duplicate Hard Focus teardown attempts.
Second teardown threw `noActiveSession`, which was incorrectly surfaced as a user-facing error.

## Changes
- add centralized suppression rule:
  - `TodoAppStore.shouldSuppressHardFocusTeardownError(_:)`
- apply suppression in three teardown catch paths:
  - timer-completion callback teardown
  - `endDeepFocus` teardown
  - `endFocusForAppTermination` teardown
- add tests for suppression behavior in `TodoAppStoreTests`

## Verification
- `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"`
  - `** TEST SUCCEEDED **`
- `xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -configuration Release -derivedDataPath "macos/TodoFocusMac/build/DerivedData" -destination "platform=macOS"`
  - `** BUILD SUCCEEDED **`

Closes #147
