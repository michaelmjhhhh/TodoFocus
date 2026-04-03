# PR: Quick Add Highlighting Stability + NL Token Rule Simplification

## Summary
- replace Quick Add overlay highlighting with AppKit-backed attributed input to keep caret/focus behavior stable
- fix focus-loss regression when typing in Quick Add input
- simplify natural-language token rules per product direction:
  - remove time parsing/highlighting (`9am`, `9:30am`, `21:15`)
  - remove `!high` token (keep `!` only)
  - remove `#list` parsing/highlighting
- update parser/store tests for new expected behavior and precedence coverage

## Files
- `macos/TodoFocusMac/Sources/Features/TaskList/QuickAddHighlightingTextField.swift` (new)
- `macos/TodoFocusMac/Sources/Features/TaskList/QuickAddView.swift`
- `macos/TodoFocusMac/Sources/Core/Parsing/QuickAddNaturalLanguageParser.swift`
- `macos/TodoFocusMac/Sources/App/TodoAppStore.swift`
- `macos/TodoFocusMac/Tests/CoreTests/QuickAddNaturalLanguageParserTests.swift`
- `macos/TodoFocusMac/Tests/CoreTests/TodoAppStoreTests.swift`
- docs artifacts under `docs/superpowers/{issues,plans}`

## Verification
- `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"`
  - `** TEST SUCCEEDED **`
- `xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -configuration Release -derivedDataPath "macos/TodoFocusMac/build/DerivedData" -destination "platform=macOS"`
  - `** BUILD SUCCEEDED **`
