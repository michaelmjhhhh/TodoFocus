# Anthropic Dark Full-App UI Polish

## Summary
Apply a full-app visual and safe interaction/layout polish for TodoFocus using the Anthropic Dark design system in dark mode only.

## Scope
- Token-led dark theme update (palette + typography roles + interaction states).
- Full-screen pass across:
  - Root shell
  - Sidebar
  - Task list / quick add / task row
  - Task detail + launch resource editor + deep focus setup sheet
  - Quick capture views
  - Daily review and stats/report surfaces
  - Settings and menu bar panel/overlays

## Constraints
- Dark mode only for this pass.
- No behavior changes to task logic, persistence, deep focus logic, or launchpad execution.
- Preserve keyboard shortcuts and accessibility labels.
- Keep Launchpad security guardrails intact.

## Acceptance Criteria
- Anthropic dark palette and editorial hierarchy are visible app-wide in dark mode.
- Quick add presents a stronger "New Intention" affordance without logic changes.
- Interaction states (hover/focus/selected) are consistent and token-driven.
- Existing tests/build gates pass.

## Verification
- `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"`
- `xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -configuration Release -derivedDataPath "macos/TodoFocusMac/build/DerivedData" -destination "platform=macOS"`
