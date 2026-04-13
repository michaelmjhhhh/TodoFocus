## 2025-05-15 - [Consistent Icon-Only Button Accessibility]
**Learning:** Icon-only buttons in the existing codebase often lacked either `.accessibilityLabel` (for screen readers) or `.help` (for tooltips), leading to inconsistent UX for different input methods.
**Action:** When adding or modifying icon-only buttons, always include both `.accessibilityLabel` and `.help` to ensure full accessibility and discoverability. For toggle states, ensure the labels and tooltips are dynamic and reflect the current state (e.g., "Mark as completed" vs "Mark as not completed").

## 2025-05-16 - [Accessible Color Swatches]
**Learning:** Using `.onTapGesture` on decorative shapes (like `Circle`) makes them inaccessible to keyboard users and silent to screen readers.
**Action:** Always wrap interactive color swatches in a `Button` with `.buttonStyle(.plain)` and provide an `accessibilityLabel` and `.help` tooltip. Center the mapping of hex codes to names in a utility like `ListColor` to ensure consistency.
