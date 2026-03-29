## Summary
Closes #77.

Polishes three visual rough edges in macOS task detail surfaces:
- Hard Focus passphrase input field styling.
- Right panel header/body seam transition.
- Steps editor and step row visual consistency.

## What Changed
- Updated `macos/TodoFocusMac/Sources/Features/TaskDetail/TaskDetailView.swift`:
  - Hard Focus passphrase `SecureField` now uses custom dark-surface styling with balanced padding, subtle border, and focused ring/glow state.
  - Added smooth gradient treatment between task detail header and body to remove abrupt seam.
  - Refined Steps section layout:
    - Unified input + Add button row styling and spacing.
    - Improved step row container, text hierarchy, and action affordances.

- Added issue record:
  - `docs/superpowers/issues/2026-03-29-hard-focus-and-task-detail-ui-polish.md`

## Why
These UI seams and control inconsistencies were visible during normal task/detail and focus setup flows, reducing perceived polish despite correct behavior.

## Verification
```bash
xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"
cd macos/TodoFocusMac
xcodebuild build -project "TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -configuration Release -derivedDataPath "build/DerivedData" -destination "platform=macOS"
```

Results:
- Tests succeeded.
- Release build succeeded.
