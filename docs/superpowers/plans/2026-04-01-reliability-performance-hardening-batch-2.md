# Reliability + Performance Hardening Batch 2 (All Review Findings)

## Goal
Fix all findings from the parallel repository audit covering release integrity, data correctness, concurrency safety, and SwiftUI performance hotspots.

## Scope
- Release pipeline correctness and CI guardrails.
- Import/export data fidelity and validation consistency.
- Concurrency/lifecycle safety in focus and quick interaction flows.
- Daily Review and TaskList performance improvements.
- Documentation alignment where workflow/runbook references are incorrect.

## Non-goals
- New product features.
- Broad visual redesign.
- Database schema migration unless strictly required to preserve export fidelity.

## Workstreams

### A. Release correctness + CI risk
1. Build release artifacts from tag ref/sha, not `main`.
2. Re-enable native release test step.
3. Add PR CI workflow for `xcodebuild test`.
4. Correct AGENTS rollback command/workflow name.
5. Retire legacy release workflow from accidental use (manual-only guard + notice).

### B. Data integrity/import-export
1. Preserve todo temporal fields in export/import (`createdAt`, `updatedAt`, `lastCompletedAt`) with backward compatibility.
2. Unify launch-resource validation on write/read/import/export to avoid silent drops.
3. Ensure replace import semantics are explicit and consistent for device-local tables.
4. Prevent step re-parenting on merge collisions.
5. Add referential-integrity preflight checks for imported `listId`.
6. Harden repository update invariants (title trimming, focus time clamping).

### C. Concurrency/lifecycle
1. Main-actor safe unlock flow in `HardFocusLockView`.
2. Remove stale callback/lifecycle risk for `onEndFocusSession`.
3. Make debounced notes writes monotonic (latest-write-wins).

### D. SwiftUI performance
1. Reduce root-tree invalidation while dragging detail splitter.
2. Make Daily Review card stacks lazy per column.
3. Cut repeated per-render filtering/sorting overhead in TaskList.
4. Make completed collapse remove subtree work instead of opacity-only hiding.
5. Reduce list color map recomputation overhead.

## Implementation strategy
- Keep changes isolated by subsystem.
- Add/adjust tests with each subsystem patch.
- Prefer backward-compatible export format update (`v1.3` support plus legacy decode paths).

## Verification
- `xcodegen generate` (if needed)
- `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"`
- `xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -configuration Release -derivedDataPath "macos/TodoFocusMac/build/DerivedData" -destination "platform=macOS"`

## Exit criteria
- All identified findings addressed in code or explicitly documented as accepted risk.
- Test + Release build succeed.
- PR includes issue link, changed files summary, and verification evidence.
