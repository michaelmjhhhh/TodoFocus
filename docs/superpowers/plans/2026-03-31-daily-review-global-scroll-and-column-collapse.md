# Daily Review Global Scroll + Column Collapse Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Keep Daily Review page-level scrolling while adding per-column expand/collapse controls, without reintroducing clipped card visibility regressions.

**Architecture:** Extend `DailyReviewBoardViewModel` with lane-aware per-bucket collapse state. Preserve existing Completed-lane collapse. Render column headers as interactive toggles that only hide/show that column’s card stack.

**Tech Stack:** SwiftUI, Observation, XCTest

---

### Task 1: Workflow setup

**Files:**
- Modify: `docs/superpowers/issues/2026-03-31-daily-review-global-scroll-and-column-collapse.md`

- [ ] Create GitHub issue from issue doc
- [ ] Create fix branch from latest main

### Task 2: Add per-column collapse state + UI interactions

**Files:**
- Modify: `macos/TodoFocusMac/Sources/Features/Review/DailyReviewView.swift`

- [ ] Add lane-aware per-bucket collapse state in `DailyReviewBoardViewModel`
- [ ] Add APIs to read/toggle per-column collapse
- [ ] Render each column header as collapse toggle with chevron affordance
- [ ] Keep page-level scroll as primary vertical scroll
- [ ] Keep existing Completed lane-level collapse behavior

### Task 3: Regression tests

**Files:**
- Modify: `macos/TodoFocusMac/Tests/CoreTests/DailyReviewViewTests.swift`

- [ ] Add tests for per-column collapse state behavior
- [ ] Keep existing board bucket tests green

### Task 4: Verify + PR

**Files:**
- Create: `docs/superpowers/prs/2026-03-31-fix-<issue>-daily-review-global-scroll-and-column-collapse.md`

- [ ] Run full tests
- [ ] Run Release build
- [ ] Commit, push, open PR with `Closes #<issue>`
