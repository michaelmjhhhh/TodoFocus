# Fix Quick Capture audio tap crash + enlarge detail resize hit area

## Problem 1: Voice capture still crashes
- Crash now points to `closure #2 in QuickCaptureService.beginRecognitionPipeline()` on queue `RealtimeMessenger.mServiceQueue`.
- This indicates executor/isolation mismatch inside the audio tap callback path.

## Root Cause (confirmed)
- `QuickCaptureService` is `@MainActor`.
- `AVAudioEngine` tap callback runs on a realtime/background queue.
- The callback closure created in actor-isolated context trips concurrency isolation assertion at runtime.

## Fix Plan
- Move tap installation callback creation into a `nonisolated` helper so callback execution is not actor-isolated.
- Keep behavior unchanged (still appending audio buffers to both recognition requests).

## Problem 2: Detail panel resize drag area is too narrow
- Divider is currently hard to hit reliably.

## Fix Plan
- Increase drag hit-target width while keeping a slim visual divider line.
- Preserve current width clamp/persistence behavior.

## Acceptance Criteria
- No crash when granting permission and starting voice capture.
- Detail panel divider is easier to grab and resize.
- Full tests and release build pass.
