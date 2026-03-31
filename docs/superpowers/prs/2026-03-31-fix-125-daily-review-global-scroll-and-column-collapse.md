## Summary
- Kept Daily Review page-level vertical scrolling as the primary scroll container.
- Added per-column collapse/expand for all time buckets in both Open and Completed lanes.
- Preserved existing Completed lane-level collapse/expand behavior.
- Kept column content naturally expanded when open (no inner vertical card scroller).

## Changes
- `DailyReviewBoardViewModel`
  - Added lane-aware collapsed bucket sets:
    - `openCollapsedBuckets`
    - `completedCollapsedBuckets`
  - Added methods:
    - `isColumnCollapsed(bucket:isCompletedLane:)`
    - `toggleColumn(bucket:isCompletedLane:)`
- `DailyReviewView`
  - Converted each column header into a plain button with chevron indicator.
  - Column body now hides/shows based on per-column collapse state.
  - No nested vertical list scroller was introduced; page scroll remains at outer level.
- `DailyReviewViewTests`
  - Added coverage for lane-level and per-column collapse independence.

## Verification
- `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -derivedDataPath "/tmp/todofocus-deriveddata-test" -destination "platform=macOS"`
  - Result: `** TEST SUCCEEDED **`
- `xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -configuration Release -derivedDataPath "/tmp/todofocus-deriveddata-build" -destination "platform=macOS"`
  - Result: `** BUILD SUCCEEDED **`

## Issue
Closes #125
