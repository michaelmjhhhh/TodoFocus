# Quick Capture Voice Input MVP (Chinese + English)

## Problem
Quick Capture currently supports only typed input. Users want a fast voice option while preserving explicit confirmation before save.

## Scope (MVP)
- Add voice capture button in Quick Capture panel.
- Click once to start recording/transcription, click again to stop.
- Support Chinese + English speech recognition.
- Recognized text overwrites the input field.
- If permissions are denied, show guidance and keep manual text input available.
- Keep existing save behavior: user must click `Add` to persist.

## UX Requirements
- UI should be polished and aligned with existing app visual style.
- Clear recording status (idle/recording/error).
- Permission-denied state provides a settings shortcut.

## Non-Goals
- No auto-save on stop.
- No natural-language date parsing in this iteration.
- No cloud STT integration.

## Acceptance Criteria
- User can record and transcribe via panel controls.
- Permission denial does not block manual capture.
- Existing keyboard shortcuts and capture flow remain intact.
- Build and tests pass.
