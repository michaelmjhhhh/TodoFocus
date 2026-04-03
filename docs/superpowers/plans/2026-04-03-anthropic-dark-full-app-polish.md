# Anthropic Dark Full-App Polish Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a dark-mode-only Anthropic-inspired visual/system polish across all major TodoFocus macOS screens without changing product behavior.

**Architecture:** Use a token-led migration: first update shared dark theme tokens and interaction styles, then apply focused screen-level view updates that consume those tokens. Keep all logic paths, persistence, keyboard shortcuts, and launch security behavior unchanged.

**Tech Stack:** SwiftUI, Observation, native macOS APIs, existing ThemeTokens/MotionTokens architecture.

---

## Chunk 1: Theme Foundation and Shared Interaction Language

### Task 1: Extend dark-mode theme tokens for Anthropic palette and typography roles

**Files:**
- Modify: `macos/TodoFocusMac/Sources/Features/Common/ThemeTokens.swift`
- Modify: `macos/TodoFocusMac/Sources/Features/Common/VisualTokens.swift`
- Test: `macos/TodoFocusMac/Tests/CoreTests/UIInteractionTokensTests.swift`

- [ ] **Step 1: Add/adjust dark token values to Anthropic palette**
- [ ] **Step 2: Add semantic aliases needed by views (editorial heading/body roles, accent variants, subtle separators)**
- [ ] **Step 3: Keep light/system values operational but unchanged in scope**
- [ ] **Step 4: Update token-related tests if current assertions rely on replaced dark values**
- [ ] **Step 5: Run focused token tests**
Run: `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS" -only-testing:CoreTests/UIInteractionTokensTests`
Expected: Token test target passes.

### Task 2: Unify shared button/row/input state styling to token-driven visuals

**Files:**
- Modify: `macos/TodoFocusMac/Sources/Features/Common/InteractiveStyles.swift`
- Modify: `macos/TodoFocusMac/Sources/Features/Common/ThemeTokens.swift`

- [ ] **Step 1: Replace hardcoded white-opacity interaction values with token-derived states**
- [ ] **Step 2: Ensure selected/hover/focus hierarchy maps to Anthropic style (amber/parchment/stone)**
- [ ] **Step 3: Keep motion behavior tied to `MotionTokens` only**
- [ ] **Step 4: Build compile check for common components**
Run: `xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -configuration Debug -destination "platform=macOS"`
Expected: Build succeeds.

## Chunk 2: Shell, Sidebar, and Task List Experience

### Task 3: Polish root shell spacing, separators, and panel visual affordances

**Files:**
- Modify: `macos/TodoFocusMac/Sources/RootView.swift`

- [ ] **Step 1: Adjust shell background/surface layering to new dark tokens**
- [ ] **Step 2: Refine divider/edge contrast for editorial depth while preserving split behavior**
- [ ] **Step 3: Keep detail panel resize mechanics untouched; polish affordance only**
- [ ] **Step 4: Compile-check RootView path**
Run: `xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -configuration Debug -destination "platform=macOS"`
Expected: Build succeeds.

### Task 4: Sidebar editorial hierarchy pass

**Files:**
- Modify: `macos/TodoFocusMac/Sources/Features/Sidebar/SidebarView.swift`
- Modify: `macos/TodoFocusMac/Sources/Features/Common/InteractiveStyles.swift` (if needed only for shared row style)

- [ ] **Step 1: Tune heading/list typographic hierarchy for dark mode**
- [ ] **Step 2: Apply token-driven active/hover styling with restrained amber emphasis**
- [ ] **Step 3: Preserve current list behavior and custom color semantics**
- [ ] **Step 4: Compile-check sidebar interactions**
Run: `xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -configuration Debug -destination "platform=macOS"`
Expected: Build succeeds.

### Task 5: Task list + quick add (“New Intention”) visual pass

**Files:**
- Modify: `macos/TodoFocusMac/Sources/Features/TaskList/TaskListView.swift`
- Modify: `macos/TodoFocusMac/Sources/Features/TaskList/QuickAddView.swift`
- Modify: `macos/TodoFocusMac/Sources/Features/TaskList/TodoRowView.swift`

- [ ] **Step 1: Re-style quick add entry hierarchy and affordance without changing submission logic**
- [ ] **Step 2: Improve task row title/metadata contrast and spacing rhythm**
- [ ] **Step 3: Keep completion/important behavior exactly as-is**
- [ ] **Step 4: Verify list-level interaction parity (selection, hover, buttons)**
- [ ] **Step 5: Run focused behavior tests**
Run: `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS" -only-testing:CoreTests/TodoAppStoreSelectionTests -only-testing:CoreTests/FeatureBehaviorTests`
Expected: Selected tests pass.

## Chunk 3: Detail, Capture, Review, Settings, and Menu Bar

### Task 6: Task detail + launch resource editor + deep focus setup style pass

**Files:**
- Modify: `macos/TodoFocusMac/Sources/Features/TaskDetail/TaskDetailView.swift`
- Modify: `macos/TodoFocusMac/Sources/Features/TaskDetail/LaunchResourceEditorView.swift`

- [ ] **Step 1: Apply consistent section/card/input treatment from shared tokens**
- [ ] **Step 2: Preserve validation and action semantics**
- [ ] **Step 3: Preserve launchpad guardrails and payload handling logic (visual changes only)**
- [ ] **Step 4: Compile-check detail workflows**
Run: `xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -configuration Debug -destination "platform=macOS"`
Expected: Build succeeds.

### Task 7: Quick Capture visual alignment pass

**Files:**
- Modify: `macos/TodoFocusMac/Sources/Features/QuickCapture/QuickCaptureView.swift`
- Modify: `macos/TodoFocusMac/Sources/Features/QuickCapture/QuickCapturePanel.swift`

- [ ] **Step 1: Align panel, warning, and input visuals with Anthropic dark tokens**
- [ ] **Step 2: Preserve accessibility-permission messaging behavior**
- [ ] **Step 3: Run quick capture behavior tests**
Run: `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS" -only-testing:CoreTests/FeatureBehaviorTests`
Expected: Focused tests pass.

### Task 8: Daily review/stats/settings/menu bar consistency pass

**Files:**
- Modify: `macos/TodoFocusMac/Sources/Features/Review/DailyReviewView.swift`
- Modify: `macos/TodoFocusMac/Sources/Features/Common/DeepFocusReportView.swift`
- Modify: `macos/TodoFocusMac/Sources/Features/Common/DeepFocusStatsReportView.swift`
- Modify: `macos/TodoFocusMac/Sources/Features/Settings/SettingsView.swift`
- Modify: `macos/TodoFocusMac/Sources/Features/MenuBar/DeepFocusMenuBarPanel.swift`
- Modify: `macos/TodoFocusMac/Sources/Features/Common/HardFocusLockView.swift`
- Modify: `macos/TodoFocusMac/Sources/Features/Common/DeepFocusOverlayView.swift`

- [ ] **Step 1: Apply consistent dark surfaces, typography hierarchy, and accent usage**
- [ ] **Step 2: Keep all commands/menus/actions unchanged**
- [ ] **Step 3: Run existing review/menu bar related tests**
Run: `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS" -only-testing:CoreTests/DailyReviewViewTests -only-testing:CoreTests/DeepFocusMenuBarStateTests`
Expected: Focused tests pass.

## Chunk 4: Workflow Artifacts, Verification, and PR Readiness

### Task 9: Issue/PR artifact documentation

**Files:**
- Create: `docs/superpowers/issues/2026-04-03-anthropic-dark-full-app-polish.md`
- Create: `docs/superpowers/prs/2026-04-03-anthropic-dark-full-app-polish.md`

- [ ] **Step 1: Create issue doc with scope, constraints, and acceptance criteria**
- [ ] **Step 2: Create PR doc with `Closes #<issue>`, summary, and verification evidence placeholders**

### Task 10: Full verification gates before completion claim

**Files:**
- Modify: `docs/superpowers/prs/2026-04-03-anthropic-dark-full-app-polish.md` (fill results)

- [ ] **Step 1: Regenerate project if needed**
Run: `cd macos/TodoFocusMac && xcodegen generate`
Expected: Project generation succeeds.

- [ ] **Step 2: Run full test suite gate**
Run: `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"`
Expected: Output includes `** TEST SUCCEEDED **`.

- [ ] **Step 3: Run release build gate**
Run: `xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -configuration Release -derivedDataPath "macos/TodoFocusMac/build/DerivedData" -destination "platform=macOS"`
Expected: Output includes `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Run requesting-code-review pass on `origin/main...HEAD` and address findings**
- [ ] **Step 5: Finalize PR doc with exact command outputs and resulting markers**

