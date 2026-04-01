# Reliability + Performance Hardening Batch 2

## Problem
Parallel audit found cross-cutting risks in release correctness, import/export fidelity, concurrency safety, and SwiftUI rendering performance.

## Findings to fix

### Release / CI
1. Native release workflow builds from `main` instead of tag ref.
2. Native release workflow test step is disabled.
3. No PR/push CI test gate.
4. AGENTS rollback instruction references wrong workflow command.
5. Legacy release workflow can still confuse native release path.

### Data correctness
1. Export/import loses `createdAt` / `updatedAt` / `lastCompletedAt` semantics.
2. Launch resource validation behavior is inconsistent across repository/import/export paths.
3. Replace import semantics leave device-local tables ambiguous/stale.
4. Merge import can re-parent steps on ID collision.
5. Import preflight misses referential checks (`todo.listId`).
6. `updateTodo` path can bypass stronger title/focus-time invariants.

### Concurrency / lifecycle
1. HardFocus unlock async flow mutates SwiftUI state without explicit main-actor isolation.
2. `onEndFocusSession` callback lifecycle can outlive detail view ownership.
3. Debounced notes writes can race old/new work items.

### Performance
1. Splitter drag updates can over-invalidate root view tree.
2. Daily Review card rendering is eager in columns.
3. TaskList recomputes filtering/sorting repeatedly in body.
4. Completed collapse still does hidden layout work.
5. List-color lookup rebuild overhead.

## Proposed solution
- Patch release workflow refs/triggers and add PR CI checks.
- Make export format forward-compatible and preserve temporal fields.
- Centralize launch-resource normalization/validation behavior.
- Harden import merge/replace semantics and preflight checks.
- Apply actor-safe UI async updates and lifecycle cleanup.
- Refactor high-frequency SwiftUI hotspots to reduce recompute/render work.

## Acceptance criteria
- All findings above resolved or explicitly documented with rationale.
- Native tests/build pass locally.
- PR includes verification outputs and links to this issue.
