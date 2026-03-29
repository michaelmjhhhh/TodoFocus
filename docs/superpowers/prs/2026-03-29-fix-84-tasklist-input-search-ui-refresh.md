## Summary
Closes #84.

Refreshes Task List top controls to improve visual polish and interaction clarity:
- Search bar gets stronger focus/active affordance and a clear-query control.
- Quick Add input replaces default rounded-border style with a cohesive custom surface.
- Add button receives clearer enabled/disabled states and better visual hierarchy.

## What Changed
- Updated `macos/TodoFocusMac/Sources/Features/Common/ThemeTokens.swift`
  - Added input-specific tokens used by task list controls:
    - `inputSurface`
    - `inputBorder`
    - `inputBorderFocused`
    - `inputGlow`

- Updated `macos/TodoFocusMac/Sources/Features/TaskList/QuickAddView.swift`
  - Replaced `.roundedBorder` text field with custom styled input surface.
  - Added leading icon and focus ring/glow transitions.
  - Improved Add button visual states (enabled/disabled) with consistent motion.
  - Preserved submit behavior and `⌘⇧N` focus shortcut.

- Updated `macos/TodoFocusMac/Sources/Features/TaskList/TaskListView.swift`
  - Refined quick-add container corner radius/shadow to match updated control styling.
  - Redesigned command/search bar surface and focus affordance.
  - Added clear-search button (`xmark.circle.fill`) when query is non-empty.
  - Preserved search behavior and `⌘K` focus shortcut.

## Why
The existing search and quick-add controls looked visually flat and less intentional than other polished surfaces in TodoFocus. This update aligns them with the app's dark aesthetic and improves state readability (focus, input present, and action availability).

## Verification
```bash
cd macos/TodoFocusMac
xcodegen generate

xcodebuild test -project "TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"

xcodebuild build -project "TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -configuration Release -derivedDataPath "build/DerivedData" -destination "platform=macOS"
```

Results:
- `** TEST SUCCEEDED **`
- `** BUILD SUCCEEDED **`
