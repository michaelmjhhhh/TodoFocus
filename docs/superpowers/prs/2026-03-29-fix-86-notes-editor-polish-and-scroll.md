## Summary
Closes #86.

Polishes the Task Detail Notes input and enforces explicit internal scrolling behavior:
- Notes field now uses a cleaner themed surface with stronger hierarchy.
- Focus state is clearer (border + glow) but still subtle.
- Notes editor now has a fixed viewport height and scrolls internally for long content.

## What Changed
- Updated `macos/TodoFocusMac/Sources/Features/TaskDetail/TaskDetailView.swift`
  - Added `@FocusState private var isNotesFocused` for Notes focus styling.
  - Redesigned `notesSection` with:
    - header row (`Notes` + `Scrollable` hint)
    - contextual empty placeholder text
    - fixed `TextEditor` height (`170`) for consistent internal scrolling
    - themed container using existing tokens (`inputSurface`, `inputBorder`, `inputBorderFocused`, `inputGlow`)
    - subtle shadow and animated focus affordance via `MotionTokens.focusEase`
  - Kept existing debounced save path unchanged:
    - `store.updateNotesDebounced(todoId:notes:)`

## Why
The previous Notes editor looked visually rough and less cohesive than the rest of the polished Task Detail controls. The new treatment aligns with current input styling and makes long-note behavior explicit and predictable.

## Verification
```bash
cd macos/TodoFocusMac
xcodegen generate

xcodebuild test -project "TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"

xcodebuild build -project "TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -configuration Release -derivedDataPath "build/DerivedData" -destination "platform=macOS"
```

Results:
- `** TEST SUCCEEDED **`
- `** BUILD SUCCEEDED **`
