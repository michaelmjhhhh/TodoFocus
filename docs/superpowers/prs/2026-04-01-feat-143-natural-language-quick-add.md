## Summary
- add English natural-language parsing for Quick Add commands
- support metadata tokens for due date/time, importance, My Day, and list hashtags
- wire parser into task creation flow from Task List Quick Add
- add parser and store integration tests

## Supported Syntax (MVP)
- Date: `today`, `tomorrow`, `next week`, weekdays (`mon...sun`, full names)
- Time: `9am`, `9:30am`, `21:15`
- Flags: `!` / `!high` => Important, `@myday` => My Day
- List: `#listName` (applies only when matching existing list)

## Implementation
- new parser: `QuickAddNaturalLanguageParser`
- new store entry point: `quickAddNaturalLanguage(...)`
- `TaskListView` now submits through natural-language quick add path

## Verification
- `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"`
  - `** TEST SUCCEEDED **`
- `xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -configuration Release -derivedDataPath "macos/TodoFocusMac/build/DerivedData" -destination "platform=macOS"`
  - `** BUILD SUCCEEDED **`

Closes #143
