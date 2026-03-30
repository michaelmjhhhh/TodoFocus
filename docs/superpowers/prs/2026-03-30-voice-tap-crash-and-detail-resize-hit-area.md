## Summary
- fix Quick Capture crash in realtime audio tap callback path
- enlarge right detail-panel resize divider hit area for easier dragging

## Linked Issue
Closes #96

## Root Cause
- `QuickCaptureService` is `@MainActor`, but AVAudio tap callback executes on a realtime queue.
- Callback creation in actor-isolated context caused runtime executor isolation assertion.

## Changes
- moved audio tap installation callback path into a `nonisolated` static helper (`installAudioTap`) in `QuickCaptureService`
- kept recognition flow behavior unchanged (still appends buffer to each active recognition request)
- expanded detail resize hit target from narrow line to larger transparent drag zone with slim visual center line

## Verification
- `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"`
  - `** TEST SUCCEEDED **`
- `xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -configuration Release -derivedDataPath "macos/TodoFocusMac/build/DerivedData" -destination "platform=macOS"`
  - `** BUILD SUCCEEDED **`
