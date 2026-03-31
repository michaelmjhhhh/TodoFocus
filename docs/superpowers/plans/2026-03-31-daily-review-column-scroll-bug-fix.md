# Plan: Daily Review Column Scroll Bug Fix

1. Add explicit vertical scroll container inside each kanban column body.
2. Apply a sensible max column content height so overflow is scrollable instead of clipped.
3. Keep empty-state rendering unchanged.
4. Verify with full test + release build.
