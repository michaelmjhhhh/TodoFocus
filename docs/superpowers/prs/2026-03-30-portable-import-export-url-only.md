## Summary
- make import/export portable by keeping launch resources URL-only
- skip non-portable launch resources (`file`, `app`) during import with explicit preflight warning and skip counts
- refresh Settings import/export section with cleaner card-style UI and explicit portability reminder
- bump export format to `1.2` while keeping support for `1.0` and `1.1`

## Linked Issue
Closes #88

## Changes
- `ExportService` now filters launch resources on export to `.url` only
- `ExportService` import now ignores non-URL launch resources and increments skipped counters
- preflight warning now calls out non-portable launch resources when present
- export metadata includes portability hints
- Settings view now has clearer grouped sections and messaging around portability constraints
- added/updated tests for URL-only behavior and non-portable skip semantics

## Verification
- `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS" -only-testing:DataTests/ExportServiceTests`
  - `** TEST SUCCEEDED **`
- `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"`
  - `** TEST SUCCEEDED **`
- `xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -configuration Release -derivedDataPath "macos/TodoFocusMac/build/DerivedData" -destination "platform=macOS"`
  - `** BUILD SUCCEEDED **`
