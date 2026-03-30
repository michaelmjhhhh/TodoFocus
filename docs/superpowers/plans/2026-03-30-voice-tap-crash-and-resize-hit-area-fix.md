# Voice Tap Crash + Detail Resize Hit Area Fix Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove Quick Capture voice tap callback crash and make detail-panel resize divider easier to drag.

**Architecture:** Keep behavior the same but move realtime audio-tap closure creation out of actor-isolated context, and increase divider hit target while preserving current width persistence/clamping path.

**Tech Stack:** SwiftUI, AVFoundation, Speech, Swift Concurrency.

---

## Chunk 1: Crash Fix

### Task 1: Nonisolated audio tap callback path

**Files:**
- Modify: `macos/TodoFocusMac/Sources/App/QuickCaptureService.swift`

- [ ] Add a `nonisolated` helper that installs tap and appends buffers to recognition requests.
- [ ] Update `beginRecognitionPipeline()` to use helper and keep logic minimal.
- [ ] Verify no behavior drift in start/stop flow.

## Chunk 2: Divider UX

### Task 2: Enlarge detail resize hit area

**Files:**
- Modify: `macos/TodoFocusMac/Sources/RootView.swift`

- [ ] Expand drag hit region width.
- [ ] Keep visual divider slim with center line overlay.
- [ ] Keep existing drag math and width persistence.

## Chunk 3: Verification

### Task 3: Run full verification

- [ ] `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"`
- [ ] `xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -configuration Release -derivedDataPath "macos/TodoFocusMac/build/DerivedData" -destination "platform=macOS"`
