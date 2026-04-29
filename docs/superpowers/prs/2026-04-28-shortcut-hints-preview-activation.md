# Show Global Shortcut Hints and Fix Preview Activation

Closes #183

## Summary

- Moves the shortcut hint bar to `RootView` as a global bottom-right overlay.
- Adds `⌘⇧U` / Daily Review Preview to the visible shortcut list.
- Routes Daily Review Preview activation through `DailyReviewPreviewService.activateAppAndNavigateToDailyReview()`.
- Uses `NSRunningApplication.current.activate(options: [.activateAllWindows])`, `NSApp.activate(ignoringOtherApps: true)`, and a visible non-preview window focus step before posting the Daily Review navigation notification.
- Adds regression coverage for shortcut list contents and preview activation sequencing.

## Verification

- `xcodegen generate`
  - Created project at `macos/TodoFocusMac/TodoFocusMac.xcodeproj`
- `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS" -only-testing:CoreTests/FeatureBehaviorTests`
  - `** TEST SUCCEEDED **`
- `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"`
  - `** TEST SUCCEEDED **`
  - CoreTests: 120 tests, 0 failures
  - DataTests: 53 tests, 0 failures
- `xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -configuration Release -derivedDataPath "macos/TodoFocusMac/build/DerivedData" -destination "platform=macOS"`
  - `** BUILD SUCCEEDED **`

## Notes

- Release build still emits the existing widget extension `CFBundleVersion` warning.

