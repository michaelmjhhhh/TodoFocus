## Summary

Daily Review header cleanup:
- remove the summary stats strip under the page title
- unify lane header icon styling so `Open` matches `Completed`

Closes #115

## Files
- `macos/TodoFocusMac/Sources/Features/Review/DailyReviewView.swift`
- `docs/superpowers/issues/2026-03-31-daily-review-header-cleanup.md`

## Verification
- `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"`
  - `** TEST SUCCEEDED **`
- `xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -configuration Release -derivedDataPath "macos/TodoFocusMac/build/DerivedData" -destination "platform=macOS"`
  - `** BUILD SUCCEEDED **`
