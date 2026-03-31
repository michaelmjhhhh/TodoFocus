# Daily Review Column Scroll Bug

## Bug
In Daily Review kanban columns, counts can show multiple tasks while only one card is visible, with no way to scroll to the rest in some window sizes/layout states.

## Root Cause (expected)
Column content uses a plain stack without guaranteed per-column vertical scrolling when height is constrained.

## Fix Scope
- Make column task content explicitly vertically scrollable.
- Keep horizontal lane scrolling behavior unchanged.
- Preserve current card layout/actions.

## Acceptance Criteria
- If a column has multiple tasks, all tasks are reachable via scroll.
- No regression in lane switching, grouping, or actions.
