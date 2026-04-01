## Summary
- add Deep Focus session templates (local persistence)
- support save/apply/start/rename/delete template flows in `DeepFocusSetupSheet`
- keep passphrase requirement and existing session start behavior

## Template Model
- `name`
- `durationMinutes` (`nil` => infinite session)
- `blockedApps` bundle IDs

## Implementation
- new `DeepFocusTemplateStore` with UserDefaults-backed CRUD
- UI integration in `DeepFocusSetupSheet`:
  - template chip list
  - apply template
  - start from template
  - save current configuration as template
  - context menu rename/delete
- supports unknown bundle IDs by adding fallback custom app rows when applying templates

## Verification
- `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"`
  - `** TEST SUCCEEDED **`
- `xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -configuration Release -derivedDataPath "macos/TodoFocusMac/build/DerivedData" -destination "platform=macOS"`
  - `** BUILD SUCCEEDED **`

Closes #145
