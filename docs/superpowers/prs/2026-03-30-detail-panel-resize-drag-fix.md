## Summary
- fix unstable drag-resize behavior for the divider between task list and right detail panel
- make width updates linear and predictable across a single drag gesture

## Linked Issue
Closes #92

## Root Cause
- drag logic used continuously updated `detailPanelWidth` while also applying `translation`, which compounded width changes during one gesture

## Changes
- added `detailPanelDragStartWidth` state in `RootView`
- capture width once at drag start
- compute `nextWidth = dragStartWidth - translation.width`
- reset drag-start width when gesture ends
- preserve existing clamping/persistence behavior through `AppModel.updateDetailPanelWidth`

## Verification
- `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"`
  - `** TEST SUCCEEDED **`
- `xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -configuration Release -derivedDataPath "macos/TodoFocusMac/build/DerivedData" -destination "platform=macOS"`
  - `** BUILD SUCCEEDED **`
