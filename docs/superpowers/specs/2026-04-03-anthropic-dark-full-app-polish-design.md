# Anthropic Dark Full-App Polish Design (TodoFocus)

## Summary
This design defines a dark-mode-only visual and safe interaction polish for TodoFocus using an Anthropic-inspired "Scholarly Curator" style. The scope is full app coverage (core workflow and secondary screens) without changing product behavior, persistence logic, launch security guardrails, or keyboard semantics.

## Visual Direction
- Philosophy: scholarly depth, editorial elegance, subtle tactility.
- Dark palette:
  - Background (Ink): `#1A1A18`
  - Surface (Charcoal): `#242422`
  - Primary (Amber): `#D97706`
  - Secondary (Parchment): `#CCB89E`
  - Tertiary (Stone): `#9C8E7B`
  - Text Primary: `#FCF9F3`
  - Text Secondary: `rgba(252, 249, 243, 0.6)`
- Typography (fallback strategy for this pass):
  - Headline/display: native serif fallback (`New York`) to emulate Newsreader role.
  - Body/interface: native sans (`SF`) to emulate Inter role.
- Component language:
  - Corner radius `12`.
  - Tonal elevation (surface contrast) over heavy shadows.
  - Amber-led active/focus states with restrained glow.

## Scope
- Full app pass in dark mode only, including:
  - `RootView` shell
  - Sidebar
  - Task list and quick add
  - Task detail and launch resource editor / deep focus setup sheet
  - Quick capture views
  - Daily review and stats views
  - Settings
  - Menu bar panel and shared overlays
- Includes visual updates and safe layout/interaction polish.

## Non-Goals
- No workflow restructuring or feature redesign.
- No model/repository/database/migration changes.
- No changes to launch execution security boundaries.
- No shortcut/keybinding behavior changes.
- No light/system-theme redesign in this PR.

## Architecture
### 1. Token-Led Foundation (Recommended Approach)
- Keep `ThemeTokens` as the source of truth for app theming.
- Re-map dark token values to Anthropic palette and introduce role-based typography tokens.
- Preserve light/system support behavior but leave visual polish out of scope.

### 2. Shared Style Consolidation
- Update shared interactive styles to read from tokens rather than ad-hoc `Color.white.opacity(...)` dark constants where touched.
- Normalize row/button/input states across screens:
  - default / hovered / focused / selected / disabled.

### 3. Screen-Level Pass
- Apply screen-specific spacing/typography/hierarchy refinements while retaining existing logic and flows.

## Screen-Level Design
### Root Shell
- Increase content breathing room and separator subtlety.
- Keep split layout and resizable detail panel behavior.
- Improve visual affordance of detail divider without changing interaction model.

### Sidebar
- Editorial hierarchy: stronger section titles, calmer list rows.
- Amber-tinted active state; parchment-toned secondary metadata.
- Preserve custom list color identity as secondary accent.

### Task List + Quick Add
- Reframe quick add as "New Intention" visually.
- Improve title-vs-metadata contrast and spacing rhythm in rows.
- Keep completed panel behavior; clarify visual separation only.

### Task Detail + Launchpad + Focus Setup
- Establish reading/editorial rhythm for sections.
- Harmonize card/input language (radius, borders, focus accents).
- Keep existing validation and action semantics unchanged.

### Quick Capture
- Keep capture behavior and permission flow.
- Apply token-consistent surfaces and warning emphasis.

### Daily Review / Stats
- Promote key metrics with display typography treatment.
- Use amber for key highlights only; reduce accent noise.

### Settings + Menu Bar + Overlays
- Align all surfaces and form controls to shared dark token language.
- Preserve all current actions and accessibility affordances.

## Constraints
- Reuse `ThemeTokens` and `MotionTokens`.
- Avoid introducing new hardcoded dark constants in feature views.
- Maintain deterministic animations and macOS-native behavior.
- Preserve accessibility labels and keyboard parity.

## Risks and Mitigations
- Inconsistent visual migration due to existing hardcoded colors.
  - Mitigation: replace touched hardcoded dark constants with token references.
- Readability regressions from serif use.
  - Mitigation: limit serif to display/headline roles only.
- Interaction inconsistency across screens.
  - Mitigation: centralize state styles in shared style helpers.

## Acceptance Criteria
- Dark mode reflects Anthropic palette and editorial hierarchy app-wide.
- Full app screens are visually coherent under shared tokens/styles.
- Quick add reads as "New Intention" without behavior changes.
- Existing shortcuts, launchpad guardrails, and flows remain intact.
- Verification gates pass before completion claims:
  - `xcodebuild test ...` shows `** TEST SUCCEEDED **`
  - `xcodebuild build ...` shows `** BUILD SUCCEEDED **`

## Implementation Direction
Proceed with a token-led pass first, then targeted screen-level polish. Keep changes focused and minimal, avoiding unrelated refactors.
