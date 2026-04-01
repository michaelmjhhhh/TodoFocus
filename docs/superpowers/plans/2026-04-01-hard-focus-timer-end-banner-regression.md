# Plan: Hard Focus timed-end false error banner regression (Issue #147)

## Systematic Debugging
- Evidence gathered from `TodoAppStore.startDeepFocus` timer callback and `HardFocusSessionManager.emergencyEndSession` behavior.
- `HardFocusError.noActiveSession` is benign in idempotent teardown contexts.

## Implementation
1. Add centralized suppression rule for benign teardown error (`noActiveSession`).
2. Apply suppression in timed-completion and auto-termination teardown catch blocks.
3. Add regression tests for suppression rule.
4. Verify full test/build pipeline.

## Verification
- `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"`
- `xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -configuration Release -derivedDataPath "macos/TodoFocusMac/build/DerivedData" -destination "platform=macOS"`
