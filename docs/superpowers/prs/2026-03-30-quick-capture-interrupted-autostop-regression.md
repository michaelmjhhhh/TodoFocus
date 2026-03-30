## Summary
- fix Quick Capture voice startup regression that could immediately show interruption status
- prevent premature auto-stop before meaningful speech is detected

## Linked Issue
Closes #103

## Root Cause
- silence auto-finalize timer was started immediately when recording began, even before any speech text was detected
- recognition lane errors were surfaced too aggressively; a single lane failure could trigger interruption messaging while another lane was still viable

## Changes
- removed auto-finalize scheduling at recording start
- auto-finalize now starts only after non-empty transcript activity is detected
- added `hasDetectedSpeechSinceRecordingStart` guard to prevent premature interruption state
- track failed locales and show interruption status only when all recognition lanes fail before any speech is detected
- clear failed-lane state when a lane produces transcript output again

## Verification
- `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"`
  - `** TEST SUCCEEDED **`
- `xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -configuration Release -derivedDataPath "macos/TodoFocusMac/build/DerivedData" -destination "platform=macOS"`
  - `** BUILD SUCCEEDED **`
