# Fix detail panel resize drag behavior

## Problem
Dragging the divider between task list and right detail panel does not feel stable because width updates are compounded during a single drag gesture.

## Root Cause
`RootView` computes next width from the continuously updated current width instead of a fixed drag-start width.

## Fix
- Capture panel width at drag start.
- Compute `nextWidth = dragStartWidth - translation.width` during drag updates.
- Reset drag-start width on drag end.

## Acceptance Criteria
- Divider drag is smooth and predictable.
- Right detail panel width follows pointer movement linearly.
- Existing width clamping/persistence still works.
