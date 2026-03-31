# Daily Review: multi-card visibility + collapse scope fix

## Reported Problems
1. In a bucket with count > 1 (e.g., Today: 2), only one task card is visible.
2. Overdue collapse control behavior is perceived as affecting broader column scope than intended.

## Systematic Debugging Evidence
- Data bucketing logic is correct (`buildBoard` counts/todos are populated and tests pass for grouping).
- No explicit per-column height cap exists in `DailyReviewView`.
- Current UI uses nested scroll composition with lazy stacks:
  - Horizontal `ScrollView` + `LazyHStack` for columns
  - `LazyVStack` for cards inside each column
- This composition can cause unstable child realization/layout in non-virtualization-sized kanban sections, matching the symptom "count says 2 but only one rendered".
- Column collapse is currently toggled by tapping the full column header row, which can feel over-broad and accidental.

## Fix Scope
- Replace lane column container from `LazyHStack` to deterministic `HStack`.
- Replace per-column card stack from `LazyVStack` to deterministic `VStack`.
- Tighten collapse trigger to explicit chevron button.
- Harden collapse state keying using `lane + bucket` identity and add regression tests for scope isolation.

## Success Criteria
- Bucket with 2+ tasks renders all cards.
- Overdue collapse only affects the intended column in the intended lane.
- Existing lane collapse (Completed) still works.
