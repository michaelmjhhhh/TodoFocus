# Stability and Performance Hardening (Store, Daily Review, Quick Capture)

## Summary
A full hardening pass is needed across TodoFocus core flows to reduce silent failures, improve user-facing reliability, and lower UI/data-path overhead.

## Root-Cause Evidence (Systematic Debugging)
1. Silent failure paths: many `try?` usages in mutating flows swallow errors and hide failed writes.
2. Heavy refresh path: `TodoAppStore` reloads lists+todos after almost every mutation, amplifying DB and UI work.
3. Daily Review reliability/UX: action failures are swallowed and card lane rendering has had repeated regressions.
4. Repeated formatter allocation in hot paths introduces avoidable overhead.

## Scope
- Replace high-impact `try?` sites with explicit error handling and user-visible feedback where needed.
- Introduce targeted refresh helpers in `TodoAppStore` to avoid unnecessary full reloads.
- Make Daily Review actions report failures and stabilize multi-card rendering behavior.
- Cache common formatters / reduce repeated lookup cost in board rendering.
- Add/extend tests for regression and behavior guarantees.

## Success Criteria
- Key action flows no longer fail silently.
- Daily Review can reliably show multiple cards per column and actions surface errors.
- Tests covering Daily Review board and import/export still pass.
- Full test and release build pass on macOS.

## Risks
- Broad touch area in store/view interactions; mitigated by focused changes and test verification.

