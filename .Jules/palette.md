## 2025-05-15 - [Consistent Icon-Only Button Accessibility]
**Learning:** Icon-only buttons in the existing codebase often lacked either `.accessibilityLabel` (for screen readers) or `.help` (for tooltips), leading to inconsistent UX for different input methods.
**Action:** When adding or modifying icon-only buttons, always include both `.accessibilityLabel` and `.help` to ensure full accessibility and discoverability. For toggle states, ensure the labels and tooltips are dynamic and reflect the current state (e.g., "Mark as completed" vs "Mark as not completed").

## 2025-05-22 - [Adaptive Theming with Semantic Tokens]
**Learning:** Hardcoded colors like `Color.white` or `Color.red` fail to adapt correctly in a dual-theme (Light/Dark) system and can break visual hierarchy or legibility. Using semantic tokens (e.g., `tokens.textPrimary`, `tokens.danger`) ensures components automatically adapt to theme changes while maintaining consistent semantic meaning across the UI.
**Action:** Always prefer `@Environment(\.themeTokens)` for colors and backgrounds. Avoid static system colors in shared components and custom modifiers.
