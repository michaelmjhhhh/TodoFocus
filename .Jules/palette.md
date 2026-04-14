## 2025-05-15 - [Consistent Icon-Only Button Accessibility]
**Learning:** Icon-only buttons in the existing codebase often lacked either `.accessibilityLabel` (for screen readers) or `.help` (for tooltips), leading to inconsistent UX for different input methods.
**Action:** When adding or modifying icon-only buttons, always include both `.accessibilityLabel` and `.help` to ensure full accessibility and discoverability. For toggle states, ensure the labels and tooltips are dynamic and reflect the current state (e.g., "Mark as completed" vs "Mark as not completed").

## 2025-05-22 - [Accessible Color Swatches and Keyboard Navigation]
**Learning:** Using `.onTapGesture` on shapes like `Circle` makes them inaccessible to keyboard users and screen readers on macOS. Mapping Tailwind-based hex codes to semantic names (e.g., "#EF4444" to "Red") is essential for providing meaningful accessibility labels for visual-only controls like color pickers.
**Action:** Always implement interactive swatches as `Button` elements with `.buttonStyle(.plain)` and use a centralized utility like `ListColor` to provide descriptive labels and tooltips.
