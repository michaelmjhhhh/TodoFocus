## Summary
- Fixed Daily Review bucket rendering so multiple tasks in the same bucket reliably display.
- Tightened column collapse interaction scope so toggle intent is explicit and lane-isolated.

## Root Cause
- The kanban lane used lazy stacks in a nested-scroll layout (`LazyHStack` for columns + `LazyVStack` for cards), which can produce unstable child realization/height behavior in this UI shape.
- Column collapse was toggled by tapping the full header row, which made scope feel too broad and accidental.

## Changes
- `DailyReviewView`
  - Replaced lane columns container from `LazyHStack` to `HStack`.
  - Replaced per-column cards stack from `LazyVStack` to `VStack`.
  - Changed per-column collapse trigger from full-header tap to explicit chevron button.
  - Hardened collapse identity by keying state with `lane + bucket` (`ReviewColumnCollapseKey`).
- `DailyReviewViewTests`
  - Updated collapse tests to lane-aware API.
  - Added `testColumnCollapseScopeIsolationForOverdue`.
  - Added `testBuildBoardKeepsAllTodosInSameBucket`.

## Verification
- `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -derivedDataPath "/tmp/todofocus-dd-127-target" -destination "platform=macOS" -only-testing:CoreTests/DailyReviewViewTests`
  - Result: `** TEST SUCCEEDED **`
- `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -derivedDataPath "/tmp/todofocus-dd-127-fulltest" -destination "platform=macOS"`
  - Result: `** TEST SUCCEEDED **`
- `xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -configuration Release -derivedDataPath "/tmp/todofocus-dd-127-build" -destination "platform=macOS"`
  - Result: `** BUILD SUCCEEDED **`

## Issue
Closes #127
