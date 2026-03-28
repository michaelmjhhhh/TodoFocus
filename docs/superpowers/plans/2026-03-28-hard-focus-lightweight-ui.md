# Hard Focus Lightweight UI Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the intrusive full-screen Hard Focus lock overlay with a lightweight, top-aligned lock bar that matches current TodoFocus visual style.

**Architecture:** Keep existing Hard Focus session logic unchanged and only redesign the presentation layer. Convert `HardFocusLockView` from a full-screen blocker into a compact status bar with an unlock popover and emergency confirmation dialog. Keep it mounted from `RootView` as an overlay, but align to top and remove background dimming.

**Tech Stack:** SwiftUI (macOS 14+), existing ThemeTokens environment, existing HardFocusSessionManager APIs.

---

### Task 1: Redesign Hard Focus Lock Surface

**Files:**
- Modify: `macos/TodoFocusMac/Sources/Features/Common/HardFocusLockView.swift`

- [ ] **Step 1: Define failing UX criteria (manual)**

Expected failures in current UI:
- Full-screen visual interruption
- Raw task ID exposed in UI
- Always-visible unlock form creating visual clutter

- [ ] **Step 2: Implement compact top lock bar**

Implementation requirements:
- Use one rounded HStack card with lock icon, title, optional session mode text.
- Use existing `ThemeTokens` colors (`bgElevated`, `sectionBorder`, `accentTerracotta`, etc.).
- Remove full-screen spacer-based layout.

- [ ] **Step 3: Move passphrase input to popover/sheet**

Implementation requirements:
- Unlock button opens a small popover.
- Passphrase field + inline error text inside popover.
- Preserve keyboard return-to-submit behavior.

- [ ] **Step 4: Keep emergency path, improve confirmation UX**

Implementation requirements:
- Replace emergency sheet with `.confirmationDialog` from the bar.
- Keep destructive action and existing warning semantics.

- [ ] **Step 5: Preserve behavior contracts**

Do not change:
- `endSession(passphrase:)` behavior
- `emergencyEndSession()` behavior
- hard focus state publishing from manager

### Task 2: Reposition Overlay in Root View

**Files:**
- Modify: `macos/TodoFocusMac/Sources/RootView.swift`

- [ ] **Step 1: Keep overlay mount, change placement contract**

Implementation requirements:
- Keep `if isHardFocusActive` condition.
- Align overlay to `.top` and add safe top padding.
- Keep main layout interactive (no dim layer).

- [ ] **Step 2: Ensure style consistency**

Implementation requirements:
- Pass existing `themeTokens` environment.
- Match spacing conventions used in app headers and floating bars.

### Task 3: Verification

**Files:**
- N/A (commands only)

- [ ] **Step 1: Build app target**

Run:
`xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"`

Expected:
- Build succeeds.

- [ ] **Step 2: Quick UX sanity checks (manual)**

Checklist:
- Hard Focus active shows compact top bar only.
- Unlock popover appears and invalid passphrase shows inline error.
- Emergency action still ends session.
- Sidebar and detail panel remain visible and non-disrupted.
