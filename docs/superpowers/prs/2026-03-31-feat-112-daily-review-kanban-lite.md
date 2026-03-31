## Summary

Implements a lightweight Daily Review kanban layout focused on clarity and performance:

- Adds `DailyReviewBoardViewModel` to compute board data in one pass.
- Refactors Daily Review into two lanes: `Open` and `Completed`.
- Adds time buckets per lane: `Overdue`, `Today`, `Tomorrow`, `Later`.
- Sets `Completed` lane to collapsed by default with manual toggle.
- Keeps existing task actions (`Done`, `My Day`, `Reschedule`) unchanged.
- Adds tests for board grouping correctness.

Closes #112

## Changed Files

- `macos/TodoFocusMac/Sources/Features/Review/DailyReviewView.swift`
- `macos/TodoFocusMac/Tests/CoreTests/DailyReviewViewTests.swift`
- `docs/superpowers/plans/2026-03-31-daily-review-kanban-lite.md`
- `docs/superpowers/issues/2026-03-31-daily-review-kanban-lite.md`

## Verification

- `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"`
  - `** TEST SUCCEEDED **`
- `xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -configuration Release -derivedDataPath "macos/TodoFocusMac/build/DerivedData" -destination "platform=macOS"`
  - `** BUILD SUCCEEDED **`
