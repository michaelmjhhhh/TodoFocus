## Summary
- align task detail header actions so Deep Focus and Close behave as one trailing control group
- keep title editor on the left with stable max-width behavior

## Linked Issue
Closes #101

## Root Cause
- Deep Focus and Close controls were laid out as separate trailing elements after a spacer, which made the Deep Focus button appear visually detached depending on title width.

## Changes
- made the title editor container expand to fill left-side space
- grouped `Deep Focus` and `Close` inside a dedicated trailing `HStack`
- preserved existing Deep Focus behavior and keyboard shortcut

## Verification
- `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"`
  - `** TEST SUCCEEDED **`
- `xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -configuration Release -derivedDataPath "macos/TodoFocusMac/build/DerivedData" -destination "platform=macOS"`
  - `** BUILD SUCCEEDED **`
