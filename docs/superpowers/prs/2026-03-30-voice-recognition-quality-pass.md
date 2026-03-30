## Summary
- improve Quick Capture voice quality with English-primary and Chinese-fallback recognition flow
- prioritize final recognition results for saved text; keep partial results as preview only
- add short-silence auto-finalize so capture ends automatically after speech pause
- add inline UI reminder about language behavior and show partial preview while recording

## Linked Issue
Closes #98

## Root Cause
- voice capture previously mixed partial and final transcripts into the same committed field, which caused unstable output and poor perceived accuracy
- there was no endpointing behavior, so users had to manually stop every capture and often got incomplete final text
- language strategy was not explicit in product UX, so expected bilingual behavior was unclear

## Changes
- recognition locales now run in fixed priority order: `en-US` primary, `zh-CN` fallback
- split transcript states into:
  - `finalTranscriptsByLocale` for committed text
  - `partialTranscriptsByLocale` + `voicePreviewText` for live preview only
- commit path now writes only `bestFinalTranscript()` to `draftText`
- added short-silence endpointing (`1.2s`) with auto-stop and status feedback
- updated Quick Capture UI:
  - language reminder text (English primary, Chinese fallback)
  - preview row for partial transcripts while recording
  - slightly larger panel frame for improved readability

## Verification
- `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"`
  - `** TEST SUCCEEDED **`
- `xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -configuration Release -derivedDataPath "macos/TodoFocusMac/build/DerivedData" -destination "platform=macOS"`
  - `** BUILD SUCCEEDED **`

## Notes
- no cloud speech API added in this PR; recognition remains on-device via Apple speech stack
- follow-up reminder tracked: keep English as default primary language, Chinese as fallback in future voice quality iterations
