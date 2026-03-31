# Stability and Performance Hardening Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Eliminate silent-failure hotspots, harden Daily Review reliability, and reduce avoidable runtime overhead without changing product behavior.

**Architecture:** Keep repository APIs stable, but improve call-site error handling and refresh granularity in `TodoAppStore`. Stabilize Daily Review rendering and action feedback in-view, and reduce hot-path allocation/lookup overhead with lightweight caches.

**Tech Stack:** SwiftUI, Observation, GRDB/SQLite, XCTest

---

## Chunk 1: Workflow Setup (Issue + Branch)

### Task 1: Create tracking issue and branch

**Files:**
- Modify: `docs/superpowers/issues/2026-03-31-stability-performance-hardening.md`

- [ ] **Step 1: Create GitHub issue from issue doc**
Run: `gh issue create --title "Stability and performance hardening" --body-file docs/superpowers/issues/2026-03-31-stability-performance-hardening.md`
Expected: issue number returned

- [ ] **Step 2: Create fix branch from main**
Run: `git switch -c fix/<issue>-stability-performance-hardening`
Expected: branch created and checked out

## Chunk 2: Silent Failure Hardening

### Task 2: Add structured error feedback in app store + Daily Review actions

**Files:**
- Modify: `macos/TodoFocusMac/Sources/App/TodoAppStore.swift`
- Modify: `macos/TodoFocusMac/Sources/Features/Review/DailyReviewView.swift`

- [ ] **Step 1: Add store-level error state and helper for user-facing mutation errors**
- [ ] **Step 2: Replace high-impact `try?` in mutation paths with `do/catch` and error capture**
- [ ] **Step 3: Wire Daily Review action runner to report failures instead of swallowing**
- [ ] **Step 4: Add/adjust unit tests for failure behavior where feasible**

## Chunk 3: Performance and Render Stability

### Task 3: Reduce unnecessary full reload and hot-path overhead

**Files:**
- Modify: `macos/TodoFocusMac/Sources/App/TodoAppStore.swift`
- Modify: `macos/TodoFocusMac/Sources/Features/Review/DailyReviewView.swift`
- Modify: `macos/TodoFocusMac/Sources/Core/Validation/LaunchResourceValidation.swift`
- Modify: `macos/TodoFocusMac/Sources/App/DeepFocusService.swift`

- [ ] **Step 1: Introduce targeted refresh helpers (`reloadTodos`, `reloadLists`) and apply to safe callsites**
- [ ] **Step 2: Replace repeated formatter construction with shared static formatters**
- [ ] **Step 3: Build list-name lookup map once per render pass in Daily Review**
- [ ] **Step 4: Remove build warnings (unused locals / non-mutated vars) where behavior is unchanged**

## Chunk 4: Verification and PR

### Task 4: Verify, document, and publish

**Files:**
- Modify: `docs/superpowers/prs/2026-03-31-fix-<issue>-stability-performance-hardening.md`

- [ ] **Step 1: Run tests**
Run: `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"`
Expected: `** TEST SUCCEEDED **`

- [ ] **Step 2: Run release build**
Run: `xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -configuration Release -derivedDataPath "macos/TodoFocusMac/build/DerivedData" -destination "platform=macOS"`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit + push + PR**
Run: `git add ... && git commit -m "fix: harden stability and performance hotspots" && git push -u origin <branch> && gh pr create ...`
Expected: PR URL returned

