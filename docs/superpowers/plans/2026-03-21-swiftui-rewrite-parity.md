# TodoFocus SwiftUI Rewrite (Feature Parity) Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild TodoFocus as a native macOS SwiftUI app with equivalent features, UX flows, and core logic to the current Electron app while improving startup, memory usage, and runtime responsiveness.

**Architecture:** Build a parallel macOS app (`macos/TodoFocusMac`) with layered modules: `Core` (domain + filtering), `Data` (SQLite via GRDB), and `App` (SwiftUI views + app services). Keep behavior parity by codifying current Electron behavior into a parity test matrix before implementation, then verify each feature area against those contracts.

**Tech Stack:** Swift 6, SwiftUI, Observation (`@Observable`), GRDB (SQLite), XCTest, xcodebuild, SwiftLint (optional), GitHub Releases artifact delivery (`.app` zipped, non-App-Store).

---

## File Structure (Target)

Lock this structure before coding so responsibilities stay clear.

- `macos/TodoFocusMac/TodoFocusMacApp.swift` -- app entry, scene setup, dependency wiring.
- `macos/TodoFocusMac/App/` -- app-level state + coordinators.
  - `AppModel.swift` -- selected list/task, panel sizing, global app state.
  - `ThemeStore.swift` -- dark/light preference persistence.
  - `LaunchpadService.swift` -- URL/file/app open orchestration (safe allowlist).
- `macos/TodoFocusMac/Core/` -- pure domain logic.
  - `Models/Todo.swift`, `List.swift`, `Step.swift`, `LaunchResource.swift`
  - `Filters/TimeFilter.swift`, `SmartList.swift`, `TodoQuery.swift`
  - `Validation/LaunchResourceValidation.swift`
- `macos/TodoFocusMac/Data/` -- persistence and repository layer.
  - `Database/DatabaseManager.swift` -- GRDB setup, migrations, db path.
  - `Database/Migrations.swift` -- additive migration definitions.
  - `Repositories/TodoRepository.swift`, `ListRepository.swift`, `StepRepository.swift`
  - `DTO/` -- row mappings and serialization helpers.
- `macos/TodoFocusMac/Features/` -- SwiftUI feature modules.
  - `Sidebar/SidebarView.swift`
  - `TaskList/TaskListView.swift`, `TodoRowView.swift`, `QuickAddView.swift`
  - `TaskDetail/TaskDetailView.swift`, `LaunchResourceEditorView.swift`, `StepsEditorView.swift`
  - `Common/ResizableSplitView.swift`
- `macos/TodoFocusMac/Tests/` -- XCTest targets.
  - `CoreTests/`
  - `DataTests/`
  - `FeatureBehaviorTests/`
- `docs/superpowers/parity/feature-parity-matrix.md` -- source of truth for behavior parity checks.
- `README.md` -- rewrite architecture and run/build instructions.

---

## Chunk 1: Baseline Capture and Parity Contracts

### Task 1: Freeze current behavior before rewrite

**Files:**
- Create: `docs/superpowers/parity/feature-parity-matrix.md`
- Modify: `docs/superpowers/plans/2026-03-21-swiftui-rewrite-parity.md`
- Reference: `README.md`, `AGENTS.md`, existing Electron feature files

- [ ] **Step 1: Record feature parity matrix (fail-first checklist)**

Create matrix sections for:
- Smart lists (My Day/Important/Planned)
- Per-view time filters
- Custom list CRUD with color
- Steps, notes autosave, due dates
- Launch resources editor + Launch All
- Native file/app pickers
- Resizable detail panel
- Theme persistence

Expected: each section includes explicit behavior statements and acceptance examples.

- [ ] **Step 2: Capture edge-case contracts from existing app**

Add explicit rules:
- quick-add from Important/Planned preserves smart-list intent
- Launch All executes sequentially; one failure does not block others
- web-only fallback behavior becomes macOS-native no-op equivalent when unavailable

Expected: parity matrix has at least 20 pass/fail assertions.

- [ ] **Step 3: Commit parity contract docs**

```bash
git add docs/superpowers/parity/feature-parity-matrix.md docs/superpowers/plans/2026-03-21-swiftui-rewrite-parity.md
git commit -m "docs: add swift rewrite parity matrix and behavior contracts"
```

---

## Chunk 2: Native App Scaffold and Build System

### Task 2: Create macOS SwiftUI app skeleton

**Files:**
- Create: `macos/TodoFocusMac/TodoFocusMacApp.swift`
- Create: `macos/TodoFocusMac/App/AppModel.swift`
- Create: `macos/TodoFocusMac/App/ThemeStore.swift`
- Create: `macos/TodoFocusMac/Features/Common/ResizableSplitView.swift`
- Create: `macos/TodoFocusMac/Tests/CoreTests/AppModelTests.swift`

- [ ] **Step 1: Write failing app state test first**

```swift
func testDefaultDetailPanelWidth() {
    let model = AppModel()
    XCTAssertEqual(model.detailPanelWidth, 360)
}
```

- [ ] **Step 2: Run test to verify failure**

Run: `xcodebuild test -scheme TodoFocusMac -destination 'platform=macOS' -only-testing:CoreTests/AppModelTests`

Expected: FAIL with missing app target/types.

- [ ] **Step 3: Generate app target and minimal app state**

Implement:
- `@main` app entry
- one WindowGroup scene
- `@Observable` `AppModel` with selected list/task/panel width

- [ ] **Step 4: Add theme persistence store**

Implement `ThemeStore` with `UserDefaults` persistence for system/light/dark.

- [ ] **Step 5: Re-run tests and app build**

Run:
- `xcodebuild test -scheme TodoFocusMac -destination 'platform=macOS' -only-testing:CoreTests/AppModelTests`
- `xcodebuild build -scheme TodoFocusMac -destination 'platform=macOS'`

Expected: PASS, app builds and launches blank shell.

- [ ] **Step 6: Commit scaffold**

```bash
git add macos/TodoFocusMac
git commit -m "feat: scaffold native macOS SwiftUI app shell"
```

---

## Chunk 3: Data Layer Rewrite (SQLite + Migrations)

### Task 3: Replace Prisma with GRDB repositories preserving schema semantics

**Files:**
- Create: `macos/TodoFocusMac/Data/Database/DatabaseManager.swift`
- Create: `macos/TodoFocusMac/Data/Database/Migrations.swift`
- Create: `macos/TodoFocusMac/Data/DTO/TodoRecord.swift`
- Create: `macos/TodoFocusMac/Data/DTO/ListRecord.swift`
- Create: `macos/TodoFocusMac/Data/DTO/StepRecord.swift`
- Create: `macos/TodoFocusMac/Data/Repositories/TodoRepository.swift`
- Create: `macos/TodoFocusMac/Data/Repositories/ListRepository.swift`
- Create: `macos/TodoFocusMac/Data/Repositories/StepRepository.swift`
- Create: `macos/TodoFocusMac/Tests/DataTests/MigrationTests.swift`
- Create: `macos/TodoFocusMac/Tests/DataTests/TodoRepositoryTests.swift`

- [ ] **Step 1: Write failing migration test**

Test verifies DB bootstrap creates required tables/columns including `launchResources`.

- [ ] **Step 2: Run migration test (expect fail)**

Run: `xcodebuild test -scheme TodoFocusMac -destination 'platform=macOS' -only-testing:DataTests/MigrationTests`

Expected: FAIL because DB manager does not exist.

- [ ] **Step 3: Implement DB manager with deterministic app data path**

Requirements:
- local path under `~/Library/Application Support/todofocus/`
- create DB if missing
- register migrations on startup

- [ ] **Step 4: Implement additive migrations for Todo/List/Step parity**

Add migration identifiers mirroring current schema behavior.

- [ ] **Step 5: Write failing repository tests for CRUD**

Tests for:
- create/update/delete todo
- list CRUD
- step CRUD and ordering
- launch resource payload persistence

- [ ] **Step 6: Implement repositories with transactional writes**

Ensure multi-field updates are atomic and deterministic.

- [ ] **Step 7: Re-run data tests**

Run:
- `xcodebuild test -scheme TodoFocusMac -destination 'platform=macOS' -only-testing:DataTests`

Expected: PASS.

- [ ] **Step 8: Commit data layer**

```bash
git add macos/TodoFocusMac/Data macos/TodoFocusMac/Tests/DataTests
git commit -m "feat: add GRDB data layer with migrations and repositories"
```

---

## Chunk 4: Core Domain Logic Parity

### Task 4: Implement pure filtering and smart-list semantics

**Files:**
- Create: `macos/TodoFocusMac/Core/Models/Todo.swift`
- Create: `macos/TodoFocusMac/Core/Models/List.swift`
- Create: `macos/TodoFocusMac/Core/Models/Step.swift`
- Create: `macos/TodoFocusMac/Core/Models/LaunchResource.swift`
- Create: `macos/TodoFocusMac/Core/Filters/TimeFilter.swift`
- Create: `macos/TodoFocusMac/Core/Filters/SmartList.swift`
- Create: `macos/TodoFocusMac/Core/Filters/TodoQuery.swift`
- Create: `macos/TodoFocusMac/Core/Validation/LaunchResourceValidation.swift`
- Create: `macos/TodoFocusMac/Tests/CoreTests/TimeFilterTests.swift`
- Create: `macos/TodoFocusMac/Tests/CoreTests/SmartListTests.swift`
- Create: `macos/TodoFocusMac/Tests/CoreTests/LaunchResourceValidationTests.swift`

- [ ] **Step 1: Write failing tests for time filters**

Cover: overdue/today/tomorrow/next-7-days/no-date/all-dates.

- [ ] **Step 2: Run tests (expect fail)**

Run: `xcodebuild test -scheme TodoFocusMac -destination 'platform=macOS' -only-testing:CoreTests/TimeFilterTests`

- [ ] **Step 3: Implement `TimeFilter` and date window logic**

Rules must match parity matrix examples exactly.

- [ ] **Step 4: Write failing tests for smart lists + quick-add intent**

Cover Important/Planned quick-add tagging behavior.

- [ ] **Step 5: Implement smart-list rules and query composition**

Use pure functions so UI and data layer reuse same logic.

- [ ] **Step 6: Write failing tests for launch resource validation**

Rules:
- allow `http/https` URLs only
- `file` must be absolute path
- `app` allows `.app` absolute path or allowlisted schemes
- max resources 12, payload length guard

- [ ] **Step 7: Implement launch resource validator**

No filesystem access in validator; pure parse/sanitize only.

- [ ] **Step 8: Run core tests**

Run: `xcodebuild test -scheme TodoFocusMac -destination 'platform=macOS' -only-testing:CoreTests`

Expected: PASS.

- [ ] **Step 9: Commit core parity logic**

```bash
git add macos/TodoFocusMac/Core macos/TodoFocusMac/Tests/CoreTests
git commit -m "feat: implement core smart-list, time-filter, and launch validation logic"
```

---

## Chunk 5: Main UI Parity (Sidebar, Task List, Detail)

### Task 5: Rebuild three-panel UX in SwiftUI with equivalent interactions

**Files:**
- Create: `macos/TodoFocusMac/Features/Sidebar/SidebarView.swift`
- Create: `macos/TodoFocusMac/Features/TaskList/TaskListView.swift`
- Create: `macos/TodoFocusMac/Features/TaskList/TodoRowView.swift`
- Create: `macos/TodoFocusMac/Features/TaskList/QuickAddView.swift`
- Create: `macos/TodoFocusMac/Features/TaskDetail/TaskDetailView.swift`
- Create: `macos/TodoFocusMac/Features/TaskDetail/StepsEditorView.swift`
- Create: `macos/TodoFocusMac/Features/TaskDetail/LaunchResourceEditorView.swift`
- Modify: `macos/TodoFocusMac/TodoFocusMacApp.swift`
- Create: `macos/TodoFocusMac/Tests/FeatureBehaviorTests/TaskDetailBehaviorTests.swift`

- [ ] **Step 1: Write failing feature behavior tests**

Tests:
- selecting list filters task list
- selecting task opens detail pane
- notes autosave debounce writes once per pause
- detail pane width persists after resize

- [ ] **Step 2: Run feature tests to confirm fail-first**

Run: `xcodebuild test -scheme TodoFocusMac -destination 'platform=macOS' -only-testing:FeatureBehaviorTests/TaskDetailBehaviorTests`

- [ ] **Step 3: Build sidebar + list + detail layout using split views**

Use `NavigationSplitView` + custom resizable detail width to match current UX.

- [ ] **Step 4: Implement quick add + row interactions**

Include complete toggle, important toggle, due-date badges, launch-count badge.

- [ ] **Step 5: Implement detail editors (notes, due date, steps)**

Maintain behavior parity for save timing and validation.

- [ ] **Step 6: Re-run feature tests and manual smoke**

Run:
- `xcodebuild test -scheme TodoFocusMac -destination 'platform=macOS' -only-testing:FeatureBehaviorTests`
- `xcodebuild run -scheme TodoFocusMac -destination 'platform=macOS'`

Expected: tests PASS and UI shell is functional.

- [ ] **Step 7: Commit UI parity pass**

```bash
git add macos/TodoFocusMac/Features macos/TodoFocusMac/TodoFocusMacApp.swift macos/TodoFocusMac/Tests/FeatureBehaviorTests
git commit -m "feat: implement SwiftUI three-panel UI with task editing parity"
```

---

## Chunk 6: Launchpad Native Integration (Security-Parity)

### Task 6: Implement Launch All and native pickers with strict safeguards

**Files:**
- Create: `macos/TodoFocusMac/App/LaunchpadService.swift`
- Modify: `macos/TodoFocusMac/Features/TaskDetail/LaunchResourceEditorView.swift`
- Create: `macos/TodoFocusMac/Tests/CoreTests/LaunchpadServiceTests.swift`

- [ ] **Step 1: Write failing tests for launch orchestration**

Cover:
- sequential execution order
- invalid resource rejection with reason
- partial failure does not stop remaining launches

- [ ] **Step 2: Run tests (expect fail)**

Run: `xcodebuild test -scheme TodoFocusMac -destination 'platform=macOS' -only-testing:CoreTests/LaunchpadServiceTests`

- [ ] **Step 3: Implement safe launch service**

Implementation rules:
- use `NSWorkspace.shared.open` for URL/file/app targets
- no shell command execution
- return per-resource result summary

- [ ] **Step 4: Wire native pickers in resource editor**

Use:
- `NSOpenPanel` for file
- app chooser for `.app` bundles
- inline validation errors before save

- [ ] **Step 5: Run tests and manual launch matrix**

Run:
- `xcodebuild test -scheme TodoFocusMac -destination 'platform=macOS' -only-testing:CoreTests/LaunchpadServiceTests`

Manual expected:
- URL opens browser
- file opens default app
- app target launches app
- invalid target reports rejected

- [ ] **Step 6: Commit launchpad native flow**

```bash
git add macos/TodoFocusMac/App/LaunchpadService.swift macos/TodoFocusMac/Features/TaskDetail/LaunchResourceEditorView.swift macos/TodoFocusMac/Tests/CoreTests/LaunchpadServiceTests.swift
git commit -m "feat: add native launchpad service and picker-integrated resource editor"
```

---

## Chunk 7: Theme, Motion, and UX Polish Parity

### Task 7: Match visual behavior (without changing product logic)

**Files:**
- Modify: `macos/TodoFocusMac/App/ThemeStore.swift`
- Create: `macos/TodoFocusMac/Features/Common/AnimationTokens.swift`
- Create: `macos/TodoFocusMac/Tests/FeatureBehaviorTests/ThemePersistenceTests.swift`

- [ ] **Step 1: Write failing theme persistence test**

Verify changing theme survives app relaunch.

- [ ] **Step 2: Implement animation/theme tokens**

Define shared durations/easings and apply to list/detail transitions.

- [ ] **Step 3: Run tests**

Run: `xcodebuild test -scheme TodoFocusMac -destination 'platform=macOS' -only-testing:FeatureBehaviorTests/ThemePersistenceTests`

Expected: PASS.

- [ ] **Step 4: Commit polish changes**

```bash
git add macos/TodoFocusMac/App/ThemeStore.swift macos/TodoFocusMac/Features/Common/AnimationTokens.swift macos/TodoFocusMac/Tests/FeatureBehaviorTests/ThemePersistenceTests.swift
git commit -m "feat: add theme persistence and motion token parity"
```

---

## Chunk 8: Packaging, Distribution, and Cutover

### Task 8: Replace Electron release path with native macOS release path

**Files:**
- Create: `docs/superpowers/plans/2026-03-21-swiftui-release-flow.md`
- Modify: `README.md`
- Modify: `AGENTS.md`
- Create: `.github/workflows/release-macos-native.yml`

- [ ] **Step 1: Write release workflow spec doc**

Define:
- archive + export notarized app
- `.app` zip packaging (primary release artifact)
- optional DMG note (secondary artifact only)
- checksum generation
- GitHub release upload

Explicit distribution policy:
- App Store distribution is out of scope.
- Canonical release artifact is `TodoFocus-macos-<arch>.zip` containing the `.app` bundle.

- [ ] **Step 2: Implement native CI workflow (fail-first by dry run)**

Run local lint/validation command for workflow syntax.

- [ ] **Step 3: Update README/AGENTS to new canonical stack**

Document:
- SwiftUI/GRDB architecture
- local build and test commands
- release flow and troubleshooting
- direct GitHub Releases distribution (`.app` zip), not App Store

- [ ] **Step 4: Verify build and tests before cutover**

Run:
- `xcodebuild test -scheme TodoFocusMac -destination 'platform=macOS'`
- `xcodebuild archive -scheme TodoFocusMac -destination 'generic/platform=macOS' -archivePath build/TodoFocusMac.xcarchive`

Expected: PASS + archive generated.

- [ ] **Step 5: Commit release/cutover docs and pipeline**

```bash
git add .github/workflows/release-macos-native.yml README.md AGENTS.md docs/superpowers/plans/2026-03-21-swiftui-release-flow.md
git commit -m "chore: add native macOS release workflow and rewrite docs"
```

---

## Chunk 9: Final Parity Verification and Launch Readiness

### Task 9: Certify rewrite parity before deprecating Electron runtime

**Files:**
- Modify: `docs/superpowers/parity/feature-parity-matrix.md`
- Create: `docs/superpowers/parity/swiftui-parity-test-report.md`

- [ ] **Step 1: Execute full parity checklist manually + automated**

Run all XCTest suites and mark each matrix row pass/fail with evidence.

- [ ] **Step 2: Resolve remaining parity gaps**

Create fix commits until all required rows pass.

- [ ] **Step 3: Produce parity report with known deltas**

Allowed deltas: performance improvements and native UX enhancements only.

- [ ] **Step 4: Final verification commands**

Run:
- `xcodebuild test -scheme TodoFocusMac -destination 'platform=macOS'`
- `xcodebuild build -scheme TodoFocusMac -destination 'platform=macOS'`

Expected: all tests pass, app builds cleanly.

- [ ] **Step 5: Commit final parity certification**

```bash
git add docs/superpowers/parity/feature-parity-matrix.md docs/superpowers/parity/swiftui-parity-test-report.md
git commit -m "docs: certify SwiftUI rewrite feature parity"
```

---

## Acceptance Gates

- SwiftUI app preserves all current user-facing features and behavior contracts in parity matrix.
- Local-first SQLite persistence remains default with safe migrations.
- Launchpad supports `url`/`file`/`app` with strict validation and no shell execution.
- Three-panel UX, per-view filters, smart-list semantics, notes/steps/due-date flows all match expected behavior.
- Theme persistence and detail-panel resizing work across relaunch.
- Native release workflow can produce distributable macOS artifacts from CI.

## Out of Scope (This Rewrite Plan)

- iOS/iPadOS companion app.
- Cloud sync and account system.
- New feature expansion beyond parity.
- Plugin ecosystem and scripting runtime.

## Suggested Delivery Timeline (6-8 Weeks)

- Week 1: Chunks 1-2 (contracts + scaffold)
- Week 2: Chunk 3 (data layer)
- Week 3: Chunk 4 (domain parity)
- Week 4-5: Chunks 5-6 (UI + launchpad)
- Week 6: Chunk 7 (polish)
- Week 7: Chunk 8 (release flow)
- Week 8: Chunk 9 (parity certification + cutover)

Plan complete and saved to `docs/superpowers/plans/2026-03-21-swiftui-rewrite-parity.md`. Ready to execute?
