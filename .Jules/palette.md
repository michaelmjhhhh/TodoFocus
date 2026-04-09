## 2025-05-15 - [Consistent Icon-Only Button Accessibility]
**Learning:** Icon-only buttons in the existing codebase often lacked either `.accessibilityLabel` (for screen readers) or `.help` (for tooltips), leading to inconsistent UX for different input methods.
**Action:** When adding or modifying icon-only buttons, always include both `.accessibilityLabel` and `.help` to ensure full accessibility and discoverability. For toggle states, ensure the labels and tooltips are dynamic and reflect the current state (e.g., "Mark as completed" vs "Mark as not completed").

## 2025-05-16 - [Semantic Theme Tokens over Hardcoded Colors]
**Learning:** Even with a robust `ThemeTokens` system, hardcoded semantic colors (like `Color.red` for errors) were often used in core views, leading to inconsistent behavior and poor adherence to the design system's terracotta-accented aesthetic.
**Action:** Always prefer semantic tokens (e.g., `tokens.danger`, `tokens.success`, `tokens.accentAmber`) over hardcoded system colors for badges, indicators, and button states to ensure visual harmony and adaptive behavior across all themes.
