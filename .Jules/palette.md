## 2025-05-15 - [Consistent Icon-Only Button Accessibility]
**Learning:** Icon-only buttons in the existing codebase often lacked either `.accessibilityLabel` (for screen readers) or `.help` (for tooltips), leading to inconsistent UX for different input methods.
**Action:** When adding or modifying icon-only buttons, always include both `.accessibilityLabel` and `.help` to ensure full accessibility and discoverability. For toggle states, ensure the labels and tooltips are dynamic and reflect the current state (e.g., "Mark as completed" vs "Mark as not completed").

## 2025-05-16 - [Semantic Color Tokens vs Hardcoded Colors]
**Learning:** Hardcoded colors like `Color.white` or `Color.green` do not adapt to theme changes, leading to poor contrast or unreadable text (e.g., white text on white background) in Light Mode.
**Action:** Always use semantic tokens from the `@Environment(\.themeTokens)` (e.g., `tokens.textPrimary`, `tokens.success`, `tokens.danger`) instead of raw SwiftUI colors. This ensures accessibility, consistent contrast, and seamless theme transitions.
