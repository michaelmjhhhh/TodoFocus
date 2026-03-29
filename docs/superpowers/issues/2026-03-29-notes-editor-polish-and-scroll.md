# UI Polish: Notes Editor Styling + Scroll Behavior

## Summary
Improve Task Detail Notes input appearance and interaction quality, and enforce clearer scroll behavior for long content.

## Scope
1. Refine visual style of Notes editor surface (padding, border, focus, hierarchy).
2. Make Notes area fixed-height with internal vertical scrolling for long content.
3. Preserve existing note saving behavior (`updateNotesDebounced`).

## Repro
- Open Task Detail panel.
- Look at Notes input surface.
- Current Notes field appears visually rough and not aligned with newer polished controls.

## Expected
- Notes field matches current TodoFocus dark design language.
- Focus state is clear but subtle.
- Notes area uses fixed viewport and scrolls internally when content exceeds height.

## Constraints
- No behavior changes to data model/debounce update logic.
- Reuse `ThemeTokens` and `MotionTokens`.
- Keep changes focused in Task Detail UI.

## Acceptance Criteria
- Notes editor looks polished and consistent with app UI.
- Long notes scroll inside the editor viewport.
- Build/tests pass.
