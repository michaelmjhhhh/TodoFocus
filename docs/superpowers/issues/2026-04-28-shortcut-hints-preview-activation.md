# Shortcut Hints and Preview Activation

## Problem

The app should show all available keyboard shortcuts in a persistent bottom-right hint bar. The current hint bar is attached to `TaskListView`, so it is not global, and it omits the Daily Review Preview shortcut `⌘⇧U`.

The Daily Review Preview panel opens with `⌘⇧U`, but pressing its “Open Daily Review” button does not reliably trigger the main app from the floating preview panel.

## Success Criteria

- The shortcut hint bar appears at the app root in the bottom-right corner.
- The hint bar includes `⌘⇧T`, `⌘⇧U`, `⌘⇧F`, `⌘K`, `⌘⇧L`, and `⌘⇧N`.
- The Task List no longer owns the hint bar.
- The Daily Review Preview activation action hides the preview, activates the current app, and posts the Daily Review navigation notification.
- Regression tests cover the shortcut list and preview activation sequence where practical.

