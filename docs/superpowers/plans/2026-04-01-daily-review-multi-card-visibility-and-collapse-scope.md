# Daily Review Multi-Card Visibility + Collapse Scope Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix Daily Review so all cards in a bucket render reliably and column collapse control affects only intended scope.

**Architecture:** Use deterministic stacks (`HStack/VStack`) in Daily Review kanban rendering to avoid lazy realization artifacts in nested-scroll context. Represent collapse state by lane+bucket key. Restrict toggle interaction to explicit chevron control.

**Tech Stack:** SwiftUI, Observation, XCTest

---

### Task 1: Workflow artifacts

**Files:**
- Create: `docs/superpowers/issues/2026-04-01-daily-review-multi-card-visibility-and-collapse-scope.md`
- Create: `docs/superpowers/plans/2026-04-01-daily-review-multi-card-visibility-and-collapse-scope.md`

- [ ] Create GitHub issue from issue doc
- [ ] Create branch from latest main

### Task 2: Rendering and interaction fix

**Files:**
- Modify: `macos/TodoFocusMac/Sources/Features/Review/DailyReviewView.swift`

- [ ] Replace `LazyHStack` with `HStack` for columns
- [ ] Replace per-column `LazyVStack` with `VStack` for cards
- [ ] Make column collapse trigger explicit chevron button
- [ ] Key collapse state by lane+bucket

### Task 3: Regression tests

**Files:**
- Modify: `macos/TodoFocusMac/Tests/CoreTests/DailyReviewViewTests.swift`

- [ ] Add test for multi-card in same bucket count/content integrity
- [ ] Add test for collapse scope isolation (open overdue toggle does not affect open today / completed overdue)

### Task 4: Verification and PR

**Files:**
- Create: `docs/superpowers/prs/2026-04-01-fix-<issue>-daily-review-multi-card-visibility-and-collapse-scope.md`

- [ ] Run full tests
- [ ] Run release build
- [ ] Commit + push + open PR with `Closes #<issue>`
