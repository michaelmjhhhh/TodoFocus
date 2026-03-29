# UI Polish: Hard Focus Passphrase Field + Task Detail Steps/Header Seam

## Summary
Polish two visible UI quality issues in the task detail and Hard Focus setup surfaces.

## Scope
1. **Hard Focus sheet** (`Start Hard Focus`):
   - Passphrase input row looks visually inconsistent (border weight, fill, padding, focus state).
2. **Task detail right panel**:
   - Top header-to-body seam feels abrupt.
   - Steps input/button row and step item row look visually rough/inconsistent.

## Repro
- Open task detail panel.
- Open `Deep Focus` / `Start Hard Focus` sheet.
- Observe passphrase field near bottom.
- Return to task detail and inspect Steps section and top seam transition.

## Expected
- Input fields use consistent dark-surface styling, clear but subtle focus ring, balanced padding.
- Header/body transition in right panel is smoother and less visually abrupt.
- Steps section has cohesive visual hierarchy: input + action + list item row share same language.

## Constraints
- Preserve existing dark theme direction and terracotta accent.
- No behavior changes to Deep Focus logic.
- Keep changes focused to UI styling and layout only.

## Acceptance Criteria
- Hard Focus passphrase field is visually consistent with the rest of the panel.
- Steps section appears polished and aligned with panel style.
- Right panel top seam no longer looks abrupt.
- `xcodebuild test` and release `xcodebuild build` still pass.
