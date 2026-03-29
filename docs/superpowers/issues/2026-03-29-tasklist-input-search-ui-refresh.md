# UI Polish: Task List Search + Quick Add Input Refresh

## Summary
Refresh the Task List top command/search bar and Quick Add row to improve visual quality and interaction clarity while preserving current behavior.

## Scope
1. `TaskListView.commandBar` (Search):
   - Improve visual hierarchy, focus affordance, and empty/non-empty states.
   - Keep keyboard shortcut (`⌘K`) behavior unchanged.
2. `QuickAddView` (Add a task):
   - Replace default rounded border field with native-styled custom surface.
   - Improve add button affordance, disabled state, and focus clarity.

## Repro
- Open `My Day` or any task list view.
- Observe search and quick-add controls at the top.
- Current controls look flat/dated and do not communicate state strongly.

## Expected
- Search and quick-add controls look cohesive with TodoFocus dark theme.
- Focus, enabled/disabled, and input-present states are obvious at a glance.
- Keyboard interactions remain identical (⌘K focus search, ⌘⇧N focus add field).

## Constraints
- Use existing design tokens (`ThemeTokens`, `MotionTokens`), no ad-hoc visual system.
- No changes to task/query business logic.
- Keep changes focused to Task List surface only.

## Acceptance Criteria
- Search and quick-add controls are visibly polished and consistent.
- Add button disabled/enabled state is clear.
- Search clear affordance exists when text is present.
- Build/tests pass.
