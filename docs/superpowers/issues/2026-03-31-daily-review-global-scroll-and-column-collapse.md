# Daily Review: keep page-level scrolling + add per-column collapse

## Problem
Current Daily Review behavior after scroll bug fixes no longer provides the desired interaction model:
- Users want page-level scroll behavior (whole review page scrollable).
- Users also need expand/collapse controls not only for Completed lane, but also for each time bucket column.

## Root-Cause Notes
- To avoid the previous nested-scroll clipping bug, column inner vertical scroll was removed.
- This fixed visibility, but reduced interaction flexibility because columns are always fully expanded.
- Existing collapse control only applies to Completed lane as a whole.

## Requested Behavior
1. Keep page-level vertical scrolling as the primary scroll container.
2. Keep Completed lane-level collapse/expand.
3. Add per-column collapse/expand for both Open and Completed lanes.
4. Keep columns naturally expanded by default (no inner vertical scroller).

## Success Criteria
- All columns can be individually collapsed/expanded.
- Completed lane can still be collapsed/expanded as a whole.
- No regression of the prior "multiple tasks but only one visible" bug.
- Daily Review tests still pass.
