# Daily Review No Date Column + Menubar Glass + Kanban Density

## Scope
- Add dedicated `No Date` column in Daily Review kanban (separate from `Later`).
- Apply lightweight liquid-glass style to MenuBar panel (performance-first).
- Reduce visual crowding inside kanban cards (action row spacing/fit).

## Constraints
- Keep macOS native behavior and low rendering overhead.
- Avoid heavy animated blur stacks.
- Preserve existing task actions and review semantics.

## Acceptance Criteria
- Open lane shows `Overdue / Today / Tomorrow / Later / No Date`.
- `No Date` tasks do not appear in `Later`.
- MenuBar panel gets subtle material/vibrancy feel without heavy effects.
- Kanban card actions are readable and less cramped.
