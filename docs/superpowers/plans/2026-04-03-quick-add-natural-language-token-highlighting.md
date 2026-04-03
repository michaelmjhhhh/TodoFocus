# Plan: Quick Add Natural Language Token Highlighting

## Goal
Highlight recognized natural-language tokens inline in Quick Add input (e.g. `tomorrow buy milk` should render `tomorrow` highlighted) while keeping existing parsing behavior unchanged.

## Scope
- Task List `QuickAddView` only.
- Highlight tokens currently supported by parser:
  - Date: `today`, `tomorrow`, `next week`, weekdays (`mon..sun`, full names)
  - Time: `9am`, `9:30am`, `21:15`
  - Flags: `!`, `!high`, `@myday`
  - List token: `#listName`

## Design
1. Extend `QuickAddNaturalLanguageParser` with reusable token analysis that returns recognized token ranges in source string.
2. Reuse the same recognition logic for parse + highlight to prevent drift.
3. Update `QuickAddView` rendering to show highlighted text while preserving typing interactions and submit behavior.
4. Add parser tests for token highlight ranges.

## Verification
- `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"`
