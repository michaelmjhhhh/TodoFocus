## 2025-05-15 - [Consistent Icon-Only Button Accessibility]
**Learning:** Icon-only buttons in the existing codebase often lacked either `.accessibilityLabel` (for screen readers) or `.help` (for tooltips), leading to inconsistent UX for different input methods.
**Action:** When adding or modifying icon-only buttons, always include both `.accessibilityLabel` and `.help` to ensure full accessibility and discoverability. For toggle states, ensure the labels and tooltips are dynamic and reflect the current state (e.g., "Mark as completed" vs "Mark as not completed").

## 2025-05-16 - [Accessible Color Pickers]
**Learning:** Interactive color swatches implemented with `onTapGesture` on shapes are not accessible to keyboard users or screen readers.
**Action:** Always implement color swatches as `Button` elements with `.buttonStyle(.plain)`. Centralize the color palette in a utility (e.g., `ListColor`) that provides semantic names for each hex code to be used in `.accessibilityLabel()` and `.help()` modifiers.
