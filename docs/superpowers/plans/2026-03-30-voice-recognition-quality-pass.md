# Voice Recognition Quality Pass Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Improve Quick Capture voice quality using EN-primary/ZH-fallback strategy, final-first fusion, and silence auto-finalize.

**Architecture:** Keep dual recognizers but separate partial vs final transcript state per locale. Commit only final transcript to draft; show partial as preview in UI. Add inactivity-based auto-finalize timer reset on each recognition callback.

**Tech Stack:** SwiftUI, AVFoundation, Speech, Swift Concurrency.

---

## Task 1: Recognition policy updates
- Modify `QuickCaptureService.swift`
- [ ] Add locale-prioritized transcript selection helpers (EN first, ZH fallback)
- [ ] Separate partial and final transcript stores
- [ ] Apply final-first policy: only final updates committed text
- [ ] Add silence timer that auto-stops recording after short inactivity

## Task 2: UI reminder and preview
- Modify `QuickCaptureView.swift`
- [ ] Add language reminder text (EN primary, ZH fallback)
- [ ] Show partial transcript preview line while recording

## Task 3: Verify
- [ ] `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"`
- [ ] `xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -configuration Release -derivedDataPath "macos/TodoFocusMac/build/DerivedData" -destination "platform=macOS"`
