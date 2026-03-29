# Deep Focus Menu Bar Status Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.  
> **Model requirement:** When parallelizing with subagents, use `gpt-5.3-codex` for all workers.

**Goal:** Add a polished macOS menu bar status entry that shows Deep Focus state in real time and provides fast actions (open main window, end focus) without changing existing focus business logic.

**Architecture:** Add a `MenuBarExtra` scene at app entry and drive it from existing observable state (`AppModel.deepFocusService` + `TodoAppStore`). Build a dedicated SwiftUI panel component under `Features/MenuBar` that reuses `ThemeTokens`/`MotionTokens` and only calls existing store APIs for side effects. Add a small pure state mapper for deterministic UI labels/countdown and unit-test it.

**Tech Stack:** SwiftUI macOS scenes (`MenuBarExtra`, `WindowGroup`), Observation (`@Observable`, `@Bindable`), existing ThemeTokens/MotionTokens, XCTest.

---

## Chunk 1: Scene Wiring + State Model

### Task 1: Add testable menu bar state mapper (TDD first)

**Files:**
- Create: `macos/TodoFocusMac/Sources/Features/MenuBar/DeepFocusMenuBarState.swift`
- Create: `macos/TodoFocusMac/Tests/CoreTests/DeepFocusMenuBarStateTests.swift`

- [ ] **Step 1: Write failing tests for state text and countdown formatting**

```swift
func testInactiveStateLabel() {
    let state = DeepFocusMenuBarState.from(
        isActive: false,
        startedAt: nil,
        configuredDuration: nil,
        blockedAppCount: 0,
        now: Date(timeIntervalSince1970: 1000)
    )
    XCTAssertEqual(state.title, "Deep Focus")
    XCTAssertEqual(state.subtitle, "Idle")
}

func testActiveTimedStateShowsRemaining() {
    let start = Date(timeIntervalSince1970: 1000)
    let now = Date(timeIntervalSince1970: 1060)
    let state = DeepFocusMenuBarState.from(
        isActive: true,
        startedAt: start,
        configuredDuration: 25 * 60,
        blockedAppCount: 3,
        now: now
    )
    XCTAssertEqual(state.menuBarBadge, "24m")
    XCTAssertTrue(state.subtitle.contains("3 apps"))
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS" -only-testing:CoreTests/DeepFocusMenuBarStateTests`  
Expected: FAIL (new type not found).

- [ ] **Step 3: Implement minimal state mapper**

Implementation requirements:
- Build a pure struct with no SwiftUI dependency.
- Inputs: `isActive`, `startedAt`, `configuredDuration`, `blockedAppCount`, `now`.
- Outputs: `title`, `subtitle`, `menuBarBadge`, `isActive`.
- Timed session formatting uses minute granularity and clamps at `0m`.

- [ ] **Step 4: Re-run tests and ensure pass**

Run: same `xcodebuild ... -only-testing` command  
Expected: PASS.

- [ ] **Step 5: Commit chunk**

```bash
git add macos/TodoFocusMac/Sources/Features/MenuBar/DeepFocusMenuBarState.swift \
        macos/TodoFocusMac/Tests/CoreTests/DeepFocusMenuBarStateTests.swift
git commit -m "test+feat(menubar): add deep focus menu bar state mapper"
```

### Task 2: Expose session start time safely for countdown

**Files:**
- Modify: `macos/TodoFocusMac/Sources/App/DeepFocusService.swift`
- Modify: `macos/TodoFocusMac/Tests/CoreTests/DeepFocusServiceTests.swift`

- [ ] **Step 1: Add failing test for observable start timestamp**

Test target behavior:
- After `startSession`, `sessionStartedAt` is non-nil.
- After `endSession`, `sessionStartedAt` becomes nil.

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS" -only-testing:CoreTests/DeepFocusServiceTests`  
Expected: FAIL (property missing).

- [ ] **Step 3: Implement minimal API surface**

Implementation requirements:
- Add `var sessionStartedAt: Date? { sessionStartTime }` read-only computed property.
- Keep existing private storage and session behavior unchanged.

- [ ] **Step 4: Re-run tests and ensure pass**

Run: same `xcodebuild ... -only-testing` command  
Expected: PASS.

- [ ] **Step 5: Commit chunk**

```bash
git add macos/TodoFocusMac/Sources/App/DeepFocusService.swift \
        macos/TodoFocusMac/Tests/CoreTests/DeepFocusServiceTests.swift
git commit -m "feat(deep-focus): expose session start timestamp for status surfaces"
```

---

## Chunk 2: MenuBarExtra UI + Actions + Verification

### Task 3: Build polished MenuBar panel view (UI/UX + SwiftUI best practices)

**Files:**
- Create: `macos/TodoFocusMac/Sources/Features/MenuBar/DeepFocusMenuBarPanel.swift`
- Modify: `macos/TodoFocusMac/Sources/TodoFocusMacApp.swift`

- [ ] **Step 1: Implement MenuBar panel layout using existing design tokens**

Implementation requirements (use `ui-ux-pro-max` + `swiftui-expert-skill`):
- Reuse `ThemeTokens` colors: `panelBackground`, `sectionBorder`, `textPrimary`, `textSecondary`, `accentTerracotta`.
- Reuse `MotionTokens` for hover/focus transitions (`hoverEase`, `focusEase`).
- Keep touch/click targets >= 44pt and keyboard accessible labels.
- Hierarchy: status title -> context subtitle -> actions row.

- [ ] **Step 2: Wire real state from store/appModel**

Implementation requirements:
- Observe `store.deepFocusService` and map to `DeepFocusMenuBarState`.
- Menu bar label: icon + compact badge when active timed session exists.
- Panel body: show blocked app count and remaining/active status.

- [ ] **Step 3: Add menu actions**

Implementation requirements:
- `Open TodoFocus`: open/create main window and bring app front (`openWindow(id: "main")` + `NSApp.activate(ignoringOtherApps: true)`).
- `End Deep Focus`: `Task { @MainActor in _ = await store.endDeepFocus() }`, disabled when inactive.
- `Quit`: `NSApplication.shared.terminate(nil)`.

- [ ] **Step 4: Add `MenuBarExtra` scene and stable main window id**

Implementation requirements:
- In `TodoFocusMacApp`, give primary window scene a stable id (`WindowGroup(id: "main")`).
- Add `MenuBarExtra(...).menuBarExtraStyle(.window)` scene next to existing `WindowGroup`/`Settings`.
- Pass shared `appModel`, `store`, `themeStore` into panel.

- [ ] **Step 5: Commit chunk**

```bash
git add macos/TodoFocusMac/Sources/Features/MenuBar/DeepFocusMenuBarPanel.swift \
        macos/TodoFocusMac/Sources/TodoFocusMacApp.swift
git commit -m "feat(menubar): add deep focus status panel with quick actions"
```

### Task 4: Full verification + UX acceptance

**Files:**
- N/A (verification commands only)

- [ ] **Step 1: Run focused tests**

Run:
`xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS" -only-testing:CoreTests/DeepFocusMenuBarStateTests -only-testing:CoreTests/DeepFocusServiceTests`

Expected:
- PASS.

- [ ] **Step 2: Run full test suite**

Run:
`xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"`

Expected:
- `** TEST SUCCEEDED **`

- [ ] **Step 3: Run release build**

Run:
`xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -configuration Release -derivedDataPath "macos/TodoFocusMac/build/DerivedData" -destination "platform=macOS"`

Expected:
- `** BUILD SUCCEEDED **`

- [ ] **Step 4: Manual UX checklist (silky interaction gate)**

Checklist:
- Menu bar icon appears immediately and does not flicker during state changes.
- Active session updates badge/remaining text smoothly (no jumpy width shifts).
- End Focus action reflects state instantly and safely disables when inactive.
- Open TodoFocus reliably brings main window front from background/minimized states.
- Colors/spacing/motion match existing dark theme style.

- [ ] **Step 5: Final commit + PR flow**

```bash
git add -A
git commit -m "feat(macos): add deep focus menubar status"
# issue -> branch -> PR using docs/superpowers/issues and docs/superpowers/prs templates
```
