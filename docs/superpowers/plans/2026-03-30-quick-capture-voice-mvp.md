# Quick Capture Voice Input MVP Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a polished voice-input option to Quick Capture with click-to-start/stop recording, bilingual (Chinese + English) transcription, overwrite behavior, and graceful permission fallback.

**Architecture:** Extend `QuickCaptureService` with a speech-capture state machine and Speech/AVFoundation integration. Bind the panel input directly to service-owned draft text so speech results can update UI instantly. Keep persistence logic unchanged (`Add` confirms save).

**Tech Stack:** SwiftUI, Observation, Speech framework, AVFoundation, macOS AppKit panel.

---

## Chunk 1: Voice Capture Core

### Task 1: Add service-level speech state and lifecycle

**Files:**
- Modify: `macos/TodoFocusMac/Sources/App/QuickCaptureService.swift`

- [ ] **Step 1:** add state for draft text, recording state, permission status, and speech errors.
- [ ] **Step 2:** integrate permission checks for speech + microphone with async requests.
- [ ] **Step 3:** add start/stop/toggle voice capture APIs.
- [ ] **Step 4:** implement bilingual recognition pipeline (`zh-CN` + `en-US`) and transcript selection.
- [ ] **Step 5:** ensure cleanup stops audio/recognition tasks safely.

## Chunk 2: Quick Capture UI Polish + Voice Controls

### Task 2: Add polished voice controls and permission fallback in panel

**Files:**
- Modify: `macos/TodoFocusMac/Sources/Features/QuickCapture/QuickCaptureView.swift`
- Modify: `macos/TodoFocusMac/Sources/Features/QuickCapture/QuickCapturePanel.swift`

- [ ] **Step 1:** bind text field to service draft text.
- [ ] **Step 2:** add microphone start/stop control and visual recording status.
- [ ] **Step 3:** add permission-denied guidance + open settings action.
- [ ] **Step 4:** polish spacing/colors/typography to match app tokens.

## Chunk 3: App Configuration + Verification

### Task 3: Add required permission strings and verify

**Files:**
- Modify: `macos/TodoFocusMac/Info.plist`

- [ ] **Step 1:** add `NSMicrophoneUsageDescription` and `NSSpeechRecognitionUsageDescription`.
- [ ] **Step 2:** run full tests.
- [ ] **Step 3:** run Release build.

