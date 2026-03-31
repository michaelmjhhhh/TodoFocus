## Summary
- Hardened mutation flows by removing high-impact silent `try?` failure paths in `TodoAppStore` and surfacing actionable error messages.
- Improved Daily Review reliability by removing nested vertical scroll clipping in column cards and adding inline error feedback.
- Added lightweight performance improvements by introducing targeted reload helpers (`reloadTodos`, `reloadLists`) and reducing unnecessary full-store refreshes.
- Completed warning cleanups for non-mutated vars and unused local binding.

## Key Changes
- `TodoAppStore`
  - Added `mutationErrorMessage`, `clearMutationError()`, and centralized error mapping helper.
  - Replaced key `try?` writes with `do/catch` in list operations, deep-focus completion paths, note persistence, and quick capture fallback creation.
  - Added `reloadTodos()` and `reloadLists()` and applied them to safe callsites to reduce full reload frequency.
- `DailyReviewView`
  - Removed inner vertical `ScrollView` in column cards to avoid clipped multi-card visibility regressions.
  - Added inline dismissible error banner.
  - Added list-id -> list-name map to reduce repeated linear lookup while rendering cards.
- `TaskListView`
  - Added dismissible error banner wired to `store.mutationErrorMessage`.
- `TaskDetailView`
  - Surfaced add-step error message (replaced prior TODO).
- Minor cleanups
  - `DeepFocusService`: removed unused `sessionId` binding.
  - `ExportService`, `ListRepository`, `TodoRepository`: replaced non-mutated `var` with `let`.
  - `RootView`: replaced startup `try? reload` with `do/catch` and user-visible error state.

## Verification
- `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"`
  - Result: `** TEST SUCCEEDED **`
- `xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -configuration Release -derivedDataPath "macos/TodoFocusMac/build/DerivedData" -destination "platform=macOS"`
  - Result: `** BUILD SUCCEEDED **`

## Issue
Closes #123
