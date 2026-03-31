## Summary
- add manual Daily Review entry in Sidebar
- add Daily Review workspace that shows all tasks and quick cleanup actions
- add running review summary metrics (reviewed/done/rescheduled/my day)

## Linked Issue
Closes #109

## Changes
- navigation:
  - added `SidebarSelection.dailyReview`
  - added Sidebar row `Daily Review`
  - routed `RootView` to show `DailyReviewView` for this selection
- data/actions:
  - added `TodoAppStore.setMyDay(todoId:isMyDay:)`
  - reused existing complete/reschedule mutations
- UI:
  - new `DailyReviewView` with full task list (active prioritized, completed included)
  - per-task actions: `Done`, `My Day`, `Reschedule` (`Today`, `Tomorrow`, `Next 7 Days`, `No Date`)
  - review summary panel with live counters and last-action feedback
- project generation:
  - ran `xcodegen generate` to include new feature file in project

## Verification
- `xcodegen generate` (in `macos/TodoFocusMac`)
- `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"`
  - `** TEST SUCCEEDED **`
- `xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -configuration Release -derivedDataPath "macos/TodoFocusMac/build/DerivedData" -destination "platform=macOS"`
  - `** BUILD SUCCEEDED **`
