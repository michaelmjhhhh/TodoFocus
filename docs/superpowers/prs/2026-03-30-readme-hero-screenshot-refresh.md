## Summary
- refresh README with the latest product-positioned structure and updated visual hierarchy
- replace hero screenshot with current full-app UI capture

## Linked Issue
Closes #105

## Changes
- updated `README.md` content structure for mixed audience (users + contributors)
- replaced `assets/overdue-screenshot.png` with latest UI screenshot (`new.png` source)
- kept this PR docs-only and separate from voice behavior/code fixes

## Verification
- `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"`
  - `** TEST SUCCEEDED **`
- `xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -configuration Release -derivedDataPath "macos/TodoFocusMac/build/DerivedData" -destination "platform=macOS"`
  - `** BUILD SUCCEEDED **`
