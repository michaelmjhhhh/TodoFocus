## Summary
- soften the visual seam between title input and Deep Focus controls in task detail header
- make the trailing action cluster feel integrated instead of detached

## Linked Issue
Closes #107

## Changes
- reduced header control spacing to tighten the transition
- added a subtle trailing blend gradient on the title input container edge
- wrapped the Deep Focus/Close control group in a low-contrast rounded surface with border

## Verification
- `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"`
  - `** TEST SUCCEEDED **`
- `xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -configuration Release -derivedDataPath "macos/TodoFocusMac/build/DerivedData" -destination "platform=macOS"`
  - `** BUILD SUCCEEDED **`
