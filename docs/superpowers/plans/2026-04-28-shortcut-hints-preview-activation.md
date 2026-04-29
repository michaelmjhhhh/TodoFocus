# Shortcut Hints and Preview Activation Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show all app shortcuts in a global bottom-right hint bar and fix Daily Review Preview activation from the floating panel.

**Architecture:** Keep UI changes small by reusing `ShortcutHintBar` and moving its attachment point from `TaskListView` to `RootView`. Make Daily Review Preview activation testable by routing the button through a service method with injectable activation and notification dependencies.

**Tech Stack:** SwiftUI, AppKit `NSRunningApplication`, XCTest, Observation.

---

## Chunk 1: Tests First

### Task 1: Shortcut and Activation Regression Tests

**Files:**
- Modify: `macos/TodoFocusMac/Tests/CoreTests/FeatureBehaviorTests.swift`

- [ ] Add a test asserting `ShortcutHintBar.availableShortcuts` exposes every user-visible shortcut, including `⌘⇧U`.
- [ ] Add a test for `DailyReviewPreviewService.activateAppAndNavigateToDailyReview()` that verifies the service hides the panel state, calls the app activator, and posts `.todoFocusNavigateToDailyReview`.
- [ ] Run the focused test target and confirm the new tests fail before implementation.

## Chunk 2: Implementation

### Task 2: Global Shortcut Hint Bar

**Files:**
- Modify: `macos/TodoFocusMac/Sources/Features/Common/ShortcutHintBar.swift`
- Modify: `macos/TodoFocusMac/Sources/Features/TaskList/TaskListView.swift`
- Modify: `macos/TodoFocusMac/Sources/RootView.swift`

- [ ] Add a small `ShortcutHintItem` model and a static `availableShortcuts` list to `ShortcutHintBar`.
- [ ] Render shortcut pills from the static list and include `⌘⇧U`.
- [ ] Remove `.shortcutHintBar(...)` from `TaskListView`.
- [ ] Add `ShortcutHintBar` as a `RootView` bottom-trailing overlay with padding so it stays in the app chrome globally.

### Task 3: Daily Review Preview Activation

**Files:**
- Modify: `macos/TodoFocusMac/Sources/Features/Review/DailyReviewPreviewService.swift`
- Modify: `macos/TodoFocusMac/Sources/RootView.swift`

- [ ] Add `.todoFocusNavigateToDailyReview` as a typed notification name.
- [ ] Add injectable `appActivator` and `notificationCenter` dependencies to `DailyReviewPreviewService`.
- [ ] Route the preview button closure through `activateAppAndNavigateToDailyReview()`.
- [ ] Use `NSRunningApplication.current.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])` for the default app activator, then bring the main window forward where possible.
- [ ] Update `RootView` to receive the typed notification.

## Chunk 3: Verification and PR Artifact

- [ ] Run focused tests for the changed behavior.
- [ ] Run `xcodegen generate` if the project file needs regeneration.
- [ ] Run the required full test command.
- [ ] Run the required Release build command.
- [ ] Write `docs/superpowers/prs/2026-04-28-shortcut-hints-preview-activation.md`.
- [ ] Commit, push, and open a PR.

