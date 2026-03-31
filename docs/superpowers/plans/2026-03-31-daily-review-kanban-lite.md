# Daily Review Kanban Lite Plan (2026-03-31)

## Goal
Upgrade Daily Review into a lightweight kanban experience with clear structure and minimal rendering overhead.

## Scope
- Primary lanes: `Open` and `Completed`.
- Time columns per lane: `Overdue`, `Today`, `Tomorrow`, `Later`.
- `Completed` lane defaults to collapsed.
- No drag-and-drop in this iteration.
- Keep existing task actions (`Done`, `My Day`, `Reschedule`) intact.

## Constraints
- Keep UI light and responsive (minimal heavy effects/animations).
- No database/schema changes.
- Reuse existing theme/motion tokens.

## Implementation Strategy
1. Introduce a lightweight view model (`DailyReviewBoardViewModel`) to compute board groups in one pass from `store.todos`.
2. Refactor `DailyReviewView` to render lane/column composition from the view model instead of inline ad-hoc grouping.
3. Add completed lane collapse state (default collapsed) with clear toggle affordance.
4. Keep card visuals clean and compact for dense task lists.
5. Preserve current action handlers and counters.

## Testing
- Extend `DailyReviewViewTests` to validate:
  - lane grouping (`open` vs `completed`),
  - time-bucket grouping,
  - deterministic ordering inside buckets.
- Run full test/build verification before PR.

## Verification Commands
- `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"`
- `xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -configuration Release -derivedDataPath "macos/TodoFocusMac/build/DerivedData" -destination "platform=macOS"`
