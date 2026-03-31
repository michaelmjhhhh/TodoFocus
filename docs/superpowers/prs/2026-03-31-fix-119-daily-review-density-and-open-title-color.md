## Summary

Daily Review UI polish follow-up:
- reduce action-row crowding by adding a two-row compact fallback layout
- make `Open` lane title text match `Completed` style (white text)

Closes #119

## Files
- `macos/TodoFocusMac/Sources/Features/Review/DailyReviewView.swift`
- `docs/superpowers/issues/2026-03-31-daily-review-kanban-density-and-open-title-color.md`

## Verification
- `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"`
  - `** TEST SUCCEEDED **`
- `xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -configuration Release -derivedDataPath "macos/TodoFocusMac/build/DerivedData" -destination "platform=macOS"`
  - `** BUILD SUCCEEDED **`
