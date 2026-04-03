# PR: Anthropic Dark Full-App UI Polish (Dark Mode)

Closes #157

## Summary
- Reworked dark-mode design tokens to Anthropic palette values (ink/charcoal/amber/parchment/stone) while leaving light/system behavior intact.
- Added typography role helpers in `ThemeTokens` to support editorial serif headings and clean sans UI labels without bundling custom fonts.
- Updated shared interactive styling to use token-driven selected/hover/focus states.
- Polished shell and core workflow surfaces (root shell, sidebar, task list, quick add, task rows) with safer spacing and hierarchy updates.
- Applied consistency polish to secondary screens (quick capture, daily review, settings) for a cohesive dark-mode language.

## Behavior and Safety
- No persistence/model/migration changes.
- No launch resource execution/security logic changes.
- No keyboard shortcut behavior changes.

## Verification
1. Full tests
- Command:
  - `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"`
- Result:
  - `** TEST SUCCEEDED **`

2. Release build
- Command:
  - `xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -configuration Release -derivedDataPath "macos/TodoFocusMac/build/DerivedData" -destination "platform=macOS"`
- Result:
  - `** BUILD SUCCEEDED **`

3. Focused regression checks during implementation
- Command:
  - `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS" -only-testing:CoreTests/UIInteractionTokensTests -only-testing:CoreTests/DailyReviewViewTests`
- Result:
  - `** TEST SUCCEEDED **`
