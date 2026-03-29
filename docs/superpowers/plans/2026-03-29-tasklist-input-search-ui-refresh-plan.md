# Task List Search + Quick Add UI Refresh Plan

## Goal
Improve perceived quality and usability of the top search input and quick-add input in Task List without altering existing behavior.

## Files
- Modify: `macos/TodoFocusMac/Sources/Features/Common/ThemeTokens.swift`
- Modify: `macos/TodoFocusMac/Sources/Features/TaskList/QuickAddView.swift`
- Modify: `macos/TodoFocusMac/Sources/Features/TaskList/TaskListView.swift`
- Create: `docs/superpowers/prs/2026-03-29-fix-<issue>-tasklist-input-search-ui-refresh.md`

## Steps
1. Add reusable input-surface token aliases in `ThemeTokens` for bg/border/focus ring/shadow.
2. Redesign `QuickAddView`:
   - custom plain text field in styled rounded surface
   - strong primary add button when text is valid
   - disabled style and focus ring animation
   - retain ⌘⇧N focus behavior
3. Redesign `TaskListView.commandBar`:
   - improved icon/input spacing and surface contrast
   - focused border/ring using tokens
   - add clear button when query non-empty
   - retain ⌘K focus behavior
4. Verify interaction/accessibility:
   - button hit targets and labels
   - state transitions use `MotionTokens`
5. Run verification gates:
   - `xcodegen generate`
   - `xcodebuild test ...`
   - `xcodebuild build ...`
6. Write PR markdown with verification outcomes.
