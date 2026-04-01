# Plan: Deep Focus Session Templates (Issue #145)

## Implementation
1. Add template persistence store (model + CRUD + UserDefaults serialization).
2. Add focused unit tests for store behavior (save/load/rename/delete).
3. Integrate template UI in `DeepFocusSetupSheet`:
   - display template chips/cards
   - apply/start actions
   - save current configuration as template
   - context menu rename/delete
4. Keep backward compatibility with current Deep Focus setup behavior.

## Verification
- `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"`
- `xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -configuration Release -derivedDataPath "macos/TodoFocusMac/build/DerivedData" -destination "platform=macOS"`
