## 2025-05-15 - [Consistent Icon-Only Button Accessibility]
**Learning:** Icon-only buttons in the existing codebase often lacked either `.accessibilityLabel` (for screen readers) or `.help` (for tooltips), leading to inconsistent UX for different input methods.
**Action:** When adding or modifying icon-only buttons, always include both `.accessibilityLabel` and `.help` to ensure full accessibility and discoverability. For toggle states, ensure the labels and tooltips are dynamic and reflect the current state (e.g., "Mark as completed" vs "Mark as not completed").

## 2025-05-16 - [Accessible Color Swatches]
**Learning:** Interactive shapes using `.onTapGesture` are not keyboard-accessible and lack semantic roles for screen readers. Using a `Button` with `.buttonStyle(.plain)` provides these for free.
**Action:** Always implement interactive swatches or items as `Button` elements. Use a centralized utility (like `ListColor`) to map hex codes to human-readable names for `.accessibilityLabel` and `.help`.
