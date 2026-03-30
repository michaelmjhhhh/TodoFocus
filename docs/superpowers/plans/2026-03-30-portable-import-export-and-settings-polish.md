# Portable Import/Export + Settings UI Polish Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ensure import/export is portable across devices by transferring only portable data (lists/todos/steps and URL launch resources), and improve Settings import/export UX to be cleaner and more graceful.

**Architecture:** Keep `ExportService` as the single source of truth for payload filtering and import behavior. Add explicit portability hints to export metadata and import preflight messaging. Refresh `SettingsView` with token-based surfaces and clearer copy that explains portability limits.

**Tech Stack:** SwiftUI, Swift 6, GRDB, XCTest.

---

## Chunk 1: Portable Data Rules

### Task 1: Export/import URL launch resources only

**Files:**
- Modify: `macos/TodoFocusMac/Sources/Data/Export/ExportService.swift`
- Modify: `macos/TodoFocusMac/Sources/Data/Export/ExportModels.swift`
- Test: `macos/TodoFocusMac/Tests/DataTests/ExportServiceTests.swift`

- [ ] **Step 1: Add failing tests** for non-URL launch resources excluded from export and skipped on import.
- [ ] **Step 2: Implement filtering** so export emits only `.url` resources.
- [ ] **Step 3: Implement import guard** to accept only `.url`, increment skipped count for `.file`/`.app`.
- [ ] **Step 4: Add portability hint** in export metadata and preflight warning.
- [ ] **Step 5: Run targeted tests** for `ExportServiceTests` and ensure they pass.

## Chunk 2: Settings UX Polish + Reminder

### Task 2: Improve import/export panel look and clarity

**Files:**
- Modify: `macos/TodoFocusMac/Sources/Features/Settings/SettingsView.swift`

- [ ] **Step 1: Restructure UI** into cleaner grouped cards/sections with stronger hierarchy.
- [ ] **Step 2: Improve controls** for Import Mode and action buttons (consistent style and spacing).
- [ ] **Step 3: Add explicit reminder text** that only URL launch resources are portable; file/app resources are intentionally skipped.
- [ ] **Step 4: Improve confirmation and success text** to reflect portability behavior.

## Chunk 3: Verification

### Task 3: Run regression checks

**Files:**
- Test: `macos/TodoFocusMac/Tests/DataTests/ExportServiceTests.swift`
- Verify build: `macos/TodoFocusMac`

- [ ] **Step 1:** `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS" -only-testing:DataTests/ExportServiceTests`
- [ ] **Step 2:** `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"`
- [ ] **Step 3:** `xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -configuration Release -derivedDataPath "macos/TodoFocusMac/build/DerivedData" -destination "platform=macOS"`

Plan complete and saved to `docs/superpowers/plans/2026-03-30-portable-import-export-and-settings-polish.md`.
