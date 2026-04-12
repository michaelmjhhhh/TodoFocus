## 2025-05-15 - [Consistent Icon-Only Button Accessibility]
**Learning:** Icon-only buttons in the existing codebase often lacked either `.accessibilityLabel` (for screen readers) or `.help` (for tooltips), leading to inconsistent UX for different input methods.
**Action:** When adding or modifying icon-only buttons, always include both `.accessibilityLabel` and `.help` to ensure full accessibility and discoverability. For toggle states, ensure the labels and tooltips are dynamic and reflect the current state (e.g., "Mark as completed" vs "Mark as not completed").

## 2025-05-15 - [Accessible Color Swatches]
**Learning:** Interactive color swatches implemented with `.onTapGesture` on shapes are not keyboard-accessible and don't provide proper feedback to screen readers.
**Action:** Always implement interactive color swatches as `Button` elements with `.buttonStyle(.plain)`. Provide descriptive accessibility labels and tooltips for each color (e.g., "Red", "Blue") to assist users with visual impairments.
