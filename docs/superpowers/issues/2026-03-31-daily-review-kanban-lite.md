# Daily Review Kanban Lite

## Problem
Current Daily Review layout is still list-heavy and visually flat. It does not give a clear board-level view of open vs completed work by time horizon.

## Proposal
Implement a lightweight kanban-style Daily Review:
- Lanes: Open + Completed
- Time columns: Overdue / Today / Tomorrow / Later
- Completed defaults to collapsed
- Preserve existing per-task actions
- Keep UI light and performance-friendly

## Acceptance Criteria
- Daily Review shows Open lane with 4 time columns.
- Completed lane exists and is collapsed by default.
- Completed lane can be expanded/collapsed manually.
- Existing task actions still work correctly in board cards.
- No regressions in sorting and due-label behavior.
- Tests/build pass.
