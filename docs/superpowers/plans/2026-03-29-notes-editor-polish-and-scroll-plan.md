# Notes Editor Polish + Scroll Plan

## Goal
Upgrade Task Detail Notes editor UX and visual quality while preserving persistence behavior.

## Files
- Modify: `macos/TodoFocusMac/Sources/Features/TaskDetail/TaskDetailView.swift`
- Create: `docs/superpowers/prs/2026-03-29-fix-<issue>-notes-editor-polish-and-scroll.md`

## Steps
1. Redesign Notes section container using existing tokens and consistent corner/border treatment.
2. Add explicit focus state for Notes input.
3. Set fixed editor height and internal scrolling behavior for long content.
4. Keep `store.updateNotesDebounced` unchanged.
5. Run verification gates (`xcodegen`, test, release build).
6. Write PR markdown with verification outcomes.
