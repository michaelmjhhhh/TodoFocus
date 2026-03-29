## Summary
Closes #81.

Fixes five MenuBar Deep Focus issues:
- Quit path did not consistently clean up focus sessions.
- 25-minute session could display as 26m.
- End from MenuBar did not require passphrase.
- Open from MenuBar could produce undesirable full-screen-style behavior.
- MenuBar panel did not show current focus task.

## Root Cause
- No app-level termination hook to unify focus shutdown behavior.
- Minute formatting used `ceil` without clamping negative elapsed time when `now` was slightly earlier than session start.
- MenuBar end action directly called emergency-style end flow without passphrase gate.
- Open action always used `openWindow` directly.
- MenuBar UI lacked task-title context binding.

## What Changed
- `TodoAppStore`:
  - Added `endDeepFocusWithPassphrase(_:)`.
  - Added `endFocusForAppTermination()`.
- `TodoFocusMacApp`:
  - Added `NSApplicationDelegate` terminate hook to run focus cleanup before quit.
  - Set a stable default main window size.
- `DeepFocusMenuBarState`:
  - Clamped elapsed time lower bound to avoid 26m at start.
- `DeepFocusMenuBarPanel`:
  - Added passphrase prompt for MenuBar end flow.
  - Added inline invalid passphrase feedback.
  - `Open TodoFocus` now prioritizes restoring existing main window.
  - Added current focus task title display.
- Tests:
  - Added off-by-one boundary test for MenuBar countdown.
  - Added passphrase-required end-flow and termination cleanup tests.

## Verification
```bash
cd macos/TodoFocusMac
xcodegen generate
xcodebuild test -project "TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS" -only-testing:CoreTests/DeepFocusMenuBarStateTests -only-testing:CoreTests/TodoAppStoreTests
xcodebuild test -project "TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"
xcodebuild build -project "TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -configuration Release -derivedDataPath "build/DerivedData" -destination "platform=macOS"
```

Results:
- Targeted tests succeeded.
- Full tests succeeded.
- Release build succeeded.
