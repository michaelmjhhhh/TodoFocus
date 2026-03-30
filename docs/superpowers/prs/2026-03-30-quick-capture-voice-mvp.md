## Summary
- add Quick Capture voice input MVP with click-to-start/stop recording
- support bilingual transcription (`en-US` + `zh-CN`) and overwrite input behavior
- add polished recording state UI and permission fallback guidance
- add required microphone/speech permission usage descriptions

## Linked Issue
Closes #90

## Changes
- extended `QuickCaptureService` with voice capture state machine, permissions, and recognition pipeline
- added bilingual recognition requests and transcript selection flow
- bound Quick Capture input field to service draft text so speech results update live
- redesigned Quick Capture panel controls for cleaner, more graceful UX
- added permission-denied guidance with direct Settings shortcut
- updated `Info.plist` for speech/microphone permission prompts

## Verification
- `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"`
  - `** TEST SUCCEEDED **`
- `xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -configuration Release -derivedDataPath "macos/TodoFocusMac/build/DerivedData" -destination "platform=macOS"`
  - `** BUILD SUCCEEDED **`
