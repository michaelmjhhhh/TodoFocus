## 2025-05-15 - [Consistent Icon-Only Button Accessibility]
**Learning:** Icon-only buttons in the existing codebase often lacked either `.accessibilityLabel` (for screen readers) or `.help` (for tooltips), leading to inconsistent UX for different input methods.
**Action:** When adding or modifying icon-only buttons, always include both `.accessibilityLabel` and `.help` to ensure full accessibility and discoverability. For toggle states, ensure the labels and tooltips are dynamic and reflect the current state (e.g., "Mark as completed" vs "Mark as not completed").

## 2026-04-05 - [Semantic Color Consistency and Icon Button Accessibility]
**Learning:** Hardcoded semantic colors (like `Color.red`) bypass the theme system and may have poor contrast or inconsistent appearance in different themes. Additionally, buttons with text labels but no tooltips can still be less discoverable than those with explicit help modifiers.
**Action:** Always use `tokens.danger` or other semantic tokens instead of hardcoded colors. Ensure all interactive elements, even those with text labels, have appropriate tooltips (`.help`) and accessibility labels to maximize usability and discoverability.
