# Fix: Deep Focus timed completion shows false Hard Focus error banner

## Symptom
After a timed Deep Focus session ends naturally, UI shows:
`Failed to end Hard Focus session ... (HardFocusError error 2)`

## Reproduction
1. Start Deep Focus in timed mode.
2. Wait for timer completion.
3. Observe transient error banner despite normal completion.

## Root Cause
Timed completion path can attempt Hard Focus teardown more than once (race/ordering between timers and teardown paths).
Second teardown throws `HardFocusError.noActiveSession`, which is currently surfaced as mutation error.

## Fix
Treat `HardFocusError.noActiveSession` as idempotent success for teardown/finalization paths.
Keep surfacing real teardown failures.

## Acceptance
- No error banner on normal timed completion.
- Non-benign teardown failures still surface.
- Tests pass.
