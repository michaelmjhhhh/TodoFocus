## Summary

Fixes a serious Daily Review kanban bug where a column can show count > 1 but only one task card is visible with no scroll path.

### Change
- Add explicit vertical scrolling to per-column task content.
- Cap column content height so overflow becomes scrollable instead of clipped.

Closes #121

## Files
- `macos/TodoFocusMac/Sources/Features/Review/DailyReviewView.swift`
- `docs/superpowers/issues/2026-03-31-daily-review-column-scroll-bug.md`
- `docs/superpowers/plans/2026-03-31-daily-review-column-scroll-bug-fix.md`

## Verification
- `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"`
  - `** TEST SUCCEEDED **`
- `xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -configuration Release -derivedDataPath "macos/TodoFocusMac/build/DerivedData" -destination "platform=macOS"`
  - `** BUILD SUCCEEDED **`
