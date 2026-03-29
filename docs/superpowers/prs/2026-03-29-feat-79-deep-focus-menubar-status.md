## Summary
Closes #79.

Adds a polished native macOS Menu Bar status panel for Deep Focus using `MenuBarExtra(.window)`, with quick actions to open app, end focus, and quit.

## What Changed
- Added menu bar state model + tests:
  - `macos/TodoFocusMac/Sources/Features/MenuBar/DeepFocusMenuBarState.swift`
  - `macos/TodoFocusMac/Tests/CoreTests/DeepFocusMenuBarStateTests.swift`
- Added menu bar UI panel and label:
  - `macos/TodoFocusMac/Sources/Features/MenuBar/DeepFocusMenuBarPanel.swift`
- Wired app scenes for menu bar entry + stable main window id:
  - `macos/TodoFocusMac/Sources/TodoFocusMacApp.swift`
- Exposed read-only session start timestamp for countdown formatting + tests:
  - `macos/TodoFocusMac/Sources/App/DeepFocusService.swift`
  - `macos/TodoFocusMac/Tests/CoreTests/DeepFocusServiceTests.swift`
- Added workflow docs:
  - `docs/superpowers/issues/2026-03-29-deep-focus-menubar-status.md`
  - `docs/superpowers/plans/2026-03-29-deep-focus-menubar-status-plan.md`

## Why
This gives Deep Focus immediate visibility and control from the menu bar, reducing context switching and aligning with macOS-native productivity patterns.

## Verification
```bash
cd macos/TodoFocusMac
xcodegen generate
xcodebuild test -project "TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS" -only-testing:CoreTests/DeepFocusMenuBarStateTests -only-testing:CoreTests/DeepFocusServiceTests
xcodebuild test -project "TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"
xcodebuild build -project "TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -configuration Release -derivedDataPath "build/DerivedData" -destination "platform=macOS"
```

Results:
- Focused tests succeeded.
- Full tests succeeded.
- Release build succeeded.
