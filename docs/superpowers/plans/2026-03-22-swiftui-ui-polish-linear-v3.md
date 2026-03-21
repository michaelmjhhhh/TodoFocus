# SwiftUI UI Polish (Linear v3) Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade TodoFocus macOS UI to feel materially more polished by improving interaction fidelity (press/hover/focus/motion), expanding color richness with accessible contrast, and refining sidebar/list/detail visual hierarchy while preserving existing behavior.

**Architecture:** Keep existing SwiftUI feature modules and data logic intact, and add a thin visual system layer (tokens + motion + state styles). Implement changes in three passes: interaction primitives first, color/theme system second, then component-level composition polish (sidebar, task columns, detail panel, launchpad messaging).

**Tech Stack:** SwiftUI, Observation (`@Observable`), XCTest, xcodebuild, @ui-ux-pro-max guidance, @swiftui-expert-skill guidelines.

---

## File Structure (UI-Polish Scope)

- `macos/TodoFocusMac/Sources/Features/Common/VisualTokens.swift` -- semantic colors, gradients, emphasis scales.
- `macos/TodoFocusMac/Sources/Features/Common/MotionTokens.swift` (new) -- shared timing/easing/spring tokens.
- `macos/TodoFocusMac/Sources/Features/Common/InteractiveStyles.swift` (new) -- reusable button/row focus/hover/pressed styles.
- `macos/TodoFocusMac/Sources/RootView.swift` -- shell spacing, divider subtlety, sidebar/detail transitions.
- `macos/TodoFocusMac/Sources/Features/Sidebar/SidebarView.swift` -- selection state styling, hover affordances, list creation affordance.
- `macos/TodoFocusMac/Sources/Features/TaskList/TaskListView.swift` -- command bar, active/completed columns, header hierarchy.
- `macos/TodoFocusMac/Sources/Features/TaskList/TodoRowView.swift` -- completion affordance prominence, hover actions, selection clarity.
- `macos/TodoFocusMac/Sources/Features/TaskDetail/TaskDetailView.swift` -- restrained toolbar/header, editable title UX, section transitions.
- `macos/TodoFocusMac/Sources/Features/TaskDetail/LaunchResourceEditorView.swift` -- launchpad hint + status clarity.
- `macos/TodoFocusMac/Tests/CoreTests/UIInteractionTokensTests.swift` (new) -- token-level expectations.
- `macos/TodoFocusMac/Tests/CoreTests/TaskListPresentationTests.swift` (new) -- filtered/split column semantics.
- `macos/TodoFocusMac/Tests/CoreTests/TaskDetailPresentationTests.swift` (new) -- title edit + launch hint presence rules.

---

## Chunk 1: Interaction Fidelity Baseline (Buttons, Hover, Focus, Press)

### Task 1: Build reusable interaction and motion tokens

**Files:**
- Create: `macos/TodoFocusMac/Sources/Features/Common/MotionTokens.swift`
- Create: `macos/TodoFocusMac/Sources/Features/Common/InteractiveStyles.swift`
- Test: `macos/TodoFocusMac/Tests/CoreTests/UIInteractionTokensTests.swift`

- [ ] **Step 1: Write failing token tests**

Add tests asserting token constraints:
- press feedback duration in `0.12...0.20`
- hover duration in `0.10...0.16`
- primary spring response in `0.22...0.32`

- [ ] **Step 2: Run token tests to verify fail-first**

Run: `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS" -only-testing:CoreTests/UIInteractionTokensTests`

Expected: FAIL (files/types missing).

- [ ] **Step 3: Implement `MotionTokens`**

Define shared animation values:
- `quick`, `standard`, `emphasis` durations
- `interactiveSpring`, `panelSpring`

- [ ] **Step 4: Implement `InteractiveStyles`**

Create reusable styles for:
- icon buttons (hover + pressed)
- row container states (idle/hover/selected)
- subtle focus ring style for text inputs

- [ ] **Step 5: Re-run token tests**

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add macos/TodoFocusMac/Sources/Features/Common/MotionTokens.swift macos/TodoFocusMac/Sources/Features/Common/InteractiveStyles.swift macos/TodoFocusMac/Tests/CoreTests/UIInteractionTokensTests.swift
git commit -m "feat: add shared motion and interaction style tokens"
```

---

## Chunk 2: Color System Expansion (Richer but Controlled)

### Task 2: Replace flat palette with semantic multi-accent system

**Files:**
- Modify: `macos/TodoFocusMac/Sources/Features/Common/VisualTokens.swift`
- Modify: `macos/TodoFocusMac/Sources/RootView.swift`
- Test: `macos/TodoFocusMac/Tests/CoreTests/UIInteractionTokensTests.swift`

- [ ] **Step 1: Add failing tests for semantic color roles**

Validate token presence for:
- background tiers (`bgBase`, `bgElevated`, `bgFloating`)
- text roles (`textPrimary`, `textSecondary`)
- semantic roles (`success`, `warning`, `danger`)
- accents (`accentBlue`, `accentViolet`, `accentAmber`)

- [ ] **Step 2: Run tests to confirm fail-first**

Run same CoreTests subset.

- [ ] **Step 3: Implement expanded token set**

Rules:
- keep dark neutral baseline
- add color depth through accents and surfaces, not random saturation
- maintain legibility (contrast-safe choices)

- [ ] **Step 4: Apply app-shell gradient and depth layers**

Update `RootView` backgrounds/dividers to use semantic tokens.

- [ ] **Step 5: Re-run CoreTests**

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add macos/TodoFocusMac/Sources/Features/Common/VisualTokens.swift macos/TodoFocusMac/Sources/RootView.swift macos/TodoFocusMac/Tests/CoreTests/UIInteractionTokensTests.swift
git commit -m "feat: introduce semantic multi-accent visual token system"
```

---

## Chunk 3: Sidebar Refinement (State Clarity + Tactile Feedback)

### Task 3: Polish sidebar interactions and hierarchy

**Files:**
- Modify: `macos/TodoFocusMac/Sources/Features/Sidebar/SidebarView.swift`
- Test: `macos/TodoFocusMac/Tests/CoreTests/TaskListPresentationTests.swift`

- [ ] **Step 1: Write failing sidebar presentation tests**

Cover:
- selected item visual state semantics
- hover state change semantics
- add-list affordance still present and functional

- [ ] **Step 2: Run tests to verify fail-first**

Run CoreTests subset for new test file.

- [ ] **Step 3: Implement sidebar visual hierarchy polish**

Apply:
- icon/text spacing normalization
- selected indicator (not color-only)
- hover feedback with subtle elevation
- smoother collapse/expand animation using `MotionTokens`

- [ ] **Step 4: Keep behavior parity**

Verify:
- selection still updates app state
- add-list still creates list

- [ ] **Step 5: Run CoreTests**

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add macos/TodoFocusMac/Sources/Features/Sidebar/SidebarView.swift macos/TodoFocusMac/Tests/CoreTests/TaskListPresentationTests.swift
git commit -m "feat: refine sidebar hierarchy and interaction feedback"
```

---

## Chunk 4: Task Columns and Row Micro-Interactions

### Task 4: Make Active/Completed columns feel deliberate and scannable

**Files:**
- Modify: `macos/TodoFocusMac/Sources/Features/TaskList/TaskListView.swift`
- Modify: `macos/TodoFocusMac/Sources/Features/TaskList/TodoRowView.swift`
- Test: `macos/TodoFocusMac/Tests/CoreTests/TaskListPresentationTests.swift`

- [ ] **Step 1: Write failing tests for column semantics and search composition**

Test expectations:
- command search filters both columns
- completed collapse state does not affect active column
- clear-completed CTA disabled when empty

- [ ] **Step 2: Run tests to verify fail-first**

Run CoreTests subset.

- [ ] **Step 3: Implement row polish**

Requirements:
- completion control always prominent
- secondary actions remain hover-revealed
- selected row state strongly legible
- press feedback for all row controls

- [ ] **Step 4: Implement column polish**

Requirements:
- balanced column headers
- improved spacing and section rhythm
- refined command bar surface/focus ring

- [ ] **Step 5: Run CoreTests**

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add macos/TodoFocusMac/Sources/Features/TaskList/TaskListView.swift macos/TodoFocusMac/Sources/Features/TaskList/TodoRowView.swift macos/TodoFocusMac/Tests/CoreTests/TaskListPresentationTests.swift
git commit -m "feat: polish task columns and row micro-interactions"
```

---

## Chunk 5: Right Detail Panel Precision (Title Editing + Section Motion)

### Task 5: Upgrade detail panel to premium, restrained editing surface

**Files:**
- Modify: `macos/TodoFocusMac/Sources/Features/TaskDetail/TaskDetailView.swift`
- Modify: `macos/TodoFocusMac/Sources/Features/TaskDetail/LaunchResourceEditorView.swift`
- Test: `macos/TodoFocusMac/Tests/CoreTests/TaskDetailPresentationTests.swift`

- [ ] **Step 1: Write failing detail presentation tests**

Cover:
- title edit state feedback semantics
- validation messaging visibility rules
- launchpad hint visibility and wording contract

- [ ] **Step 2: Run tests to confirm fail-first**

Run CoreTests subset.

- [ ] **Step 3: Implement detail header refinement**

Requirements:
- cleaner title-edit container
- non-jitter focus/submit feedback
- close action visual parity with rest of shell

- [ ] **Step 4: Implement section-level motion and polish**

Requirements:
- cohesive section transitions (small, meaningful)
- consistent card border/elevation grammar
- no heavy/glassy overdraw

- [ ] **Step 5: Enhance launchpad hint clarity**

Update hint copy and status feedback hierarchy.

- [ ] **Step 6: Run CoreTests**

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add macos/TodoFocusMac/Sources/Features/TaskDetail/TaskDetailView.swift macos/TodoFocusMac/Sources/Features/TaskDetail/LaunchResourceEditorView.swift macos/TodoFocusMac/Tests/CoreTests/TaskDetailPresentationTests.swift
git commit -m "feat: refine detail panel editing and launchpad guidance"
```

---

## Chunk 6: Final UI QA Pass and Accessibility Sweep

### Task 6: Verify interactions, contrast, and animation quality

**Files:**
- Modify: `docs/superpowers/parity/swiftui-parity-test-report.md`
- Modify: `docs/superpowers/parity/feature-parity-matrix.md`

- [ ] **Step 1: Execute UI regression checklist**

Check manually:
- sidebar toggle + auto-hide behavior
- active/completed columns
- row hover/press/select states
- command search + `⌘K`
- title rename + validation feedback
- launchpad hint + launch status

- [ ] **Step 2: Run full test/build suite**

Run:
```bash
xcodegen generate
xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"
xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"
```

Expected: all pass.

- [ ] **Step 3: Document UI polish completion evidence**

Update parity report with before/after behavior notes.

- [ ] **Step 4: Commit**

```bash
git add docs/superpowers/parity/swiftui-parity-test-report.md docs/superpowers/parity/feature-parity-matrix.md
git commit -m "docs: record ui polish validation and parity evidence"
```

---

## Acceptance Gates

- Interactions feel deliberate: hover, press, focus, select, and transitions are consistent and smooth.
- Colors are richer but still legible and restrained, with semantic roles instead of ad-hoc values.
- Sidebar, task columns, and detail panel show clear visual hierarchy and tactile feedback.
- Launchpad section includes explicit, user-friendly guidance and status messaging.
- Existing functional behavior remains intact (filters, add list, edit title, launch, clear completed, search).
- Full native test/build pipeline passes.

## Out of Scope

- New product features beyond UI/UX quality improvements.
- Navigation architecture rewrite.
- iOS layout adaptation.

Plan complete and saved to `docs/superpowers/plans/2026-03-22-swiftui-ui-polish-linear-v3.md`. Ready to execute?
