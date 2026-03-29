# Bugfix: MenuBar Quit Focus Cleanup + Countdown Off-by-One

## Symptoms
1. Quitting from MenuBar `Quit` then reopening can show focus mismatch:
   - App may still show hard focus lock state.
   - MenuBar shows inactive focus.
2. Starting a 25-minute session sometimes shows `26m` in MenuBar.
3. Ending focus from MenuBar currently does not require passphrase.
4. Opening app from MenuBar can default to a full-screen style window behavior.
5. MenuBar does not show which task is currently in Deep Focus.

## Repro
- Start Deep Focus with 25m duration.
- Observe MenuBar badge may show `26m` at session start.
- Quit app from MenuBar `Quit` or regular app quit.
- Reopen app and observe status mismatch.

## Root Cause
- Quit path has no unified shutdown hook to end focus sessions before termination.
- MenuBar minute calculation uses `ceil` on `sessionDuration - elapsed` without clamping negative elapsed when `now < sessionStartedAt` by a small timing delta.

## Expected
- Any app quit path triggers deterministic focus shutdown.
- 25m session displays `25m` at start, never `26m`.
- App/MenuBar focus state stays consistent after reopen.
- MenuBar `End Deep Focus` requires passphrase and rejects invalid input.
- MenuBar `Open TodoFocus` restores/opens a normal main window experience.
- MenuBar panel displays current Deep Focus task title when available.
