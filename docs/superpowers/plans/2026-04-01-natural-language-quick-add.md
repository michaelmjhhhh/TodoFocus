# Plan: Natural Language Quick Add (Issue #143)

## Design
1. Add pure parser utility for quick-add command interpretation:
   - Input: raw text, `now`, `Calendar`
   - Output: normalized title + optional due date + optional list token + flags
2. Integrate parser in `TodoAppStore` via a new quick-add entry point using current view defaults.
3. Update `TaskListView` quick-add submit path to call natural-language quick add.
4. Add tests:
   - parser unit tests for tokens and date/time logic
   - store integration tests for flag/list/due-date mapping

## Non-goals
- Non-English locale parsing
- Advanced priority taxonomy beyond important flag
- Creating missing lists from hashtag

## Verification
- `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"`
- `xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -configuration Release -derivedDataPath "macos/TodoFocusMac/build/DerivedData" -destination "platform=macOS"`
