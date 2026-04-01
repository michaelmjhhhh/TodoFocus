## Summary
- fix import compatibility for historical `v1.0` exports with non-empty todos by adding decode defaults for fields introduced later (`recurrenceInterval`, `sortOrder`, `steps`, `launchResources`)
- harden replace-import backup naming to avoid collisions by adding millisecond timestamp + random suffix
- add regression tests for both cases

## Root Cause
- `ExportTodo` used synthesized decoding with non-optional fields that can be absent in legacy `v1.0` payloads.
- backup filenames used second-level precision only.

## Changes
- `ExportTodo` custom `Decodable` defaults in `ExportModels.swift`
- backup filename generation updated in `ExportService.createBackupSnapshot()`
- tests added in `ExportServiceTests`:
  - `testDecodeV1_0PayloadWithLegacyTodoDefaultsMissingFields`
  - `testReplaceImportBackupFilenameContainsMillisAndEntropySuffix`

## Verification
- `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"`
  - `** TEST SUCCEEDED **`
- `xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -configuration Release -derivedDataPath "macos/TodoFocusMac/build/DerivedData" -destination "platform=macOS"`
  - `** BUILD SUCCEEDED **`

Closes #140
