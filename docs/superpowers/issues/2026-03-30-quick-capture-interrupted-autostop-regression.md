## Summary
Quick Capture voice mode shows an interruption state immediately after start and can auto-stop before meaningful speech is detected.

## Symptoms
- User enters Quick Capture and starts voice capture.
- UI quickly shows `Listening interrupted, tap mic to retry` even when user has not finished speaking.
- UI can transition to `Auto-stopped after short silence` almost immediately.

## Expected
- Voice capture should not show interruption noise from a single recognition lane unless capture is actually unusable.
- Auto-finalize should only run after meaningful speech activity has been detected.

## Root Cause Hypothesis
- Silence auto-finalize timer starts immediately on recording start, before any transcript activity.
- Error callback from one recognition locale lane is surfaced as user-facing interruption too aggressively.

## Scope
- QuickCapture voice status and auto-finalize timing logic only.
- No API/provider changes.
