# Plan: No Date Column + Menubar Glass + Kanban Density

## Implementation Steps
1. Extend review bucket model with `noDate` and update board grouping.
2. Keep `Later` only for dated tasks after tomorrow.
3. Tune kanban card action layout to reduce crowding:
   - Slightly smaller action controls
   - Better wrapping/spacing behavior
4. Add lightweight menu bar panel glass treatment using native material APIs.
5. Add/adjust tests for no-date bucket behavior.
6. Run full test/build verification.

## Verification
- `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"`
- `xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -configuration Release -derivedDataPath "macos/TodoFocusMac/build/DerivedData" -destination "platform=macOS"`
