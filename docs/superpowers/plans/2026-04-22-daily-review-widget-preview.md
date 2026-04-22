# Daily Review Widget Preview Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a native macOS desktop widget that previews Daily Review tasks from the shared TodoFocus database, with no editing interactions.

**Architecture:** Extract the Daily Review grouping logic into a shared domain file, centralize shared app-group database path resolution, then add a WidgetKit extension target through XcodeGen that reads the shared SQLite database and renders a compact dark widget UI aligned with TodoFocus styling. The widget stays read-only and surfaces a small Daily Review snapshot for desktop use.

**Tech Stack:** SwiftUI, WidgetKit, GRDB, XcodeGen, native macOS app extensions

---

## Chunk 1: Shared review logic and shared DB path

### Task 1: Extract reusable Daily Review board logic

**Files:**
- Create: `macos/TodoFocusMac/Sources/Core/Review/DailyReviewBoard.swift`
- Modify: `macos/TodoFocusMac/Sources/Features/Review/DailyReviewView.swift`
- Test: `macos/TodoFocusMac/Tests/CoreTests/DailyReviewViewTests.swift`

- [ ] **Step 1: Update tests to target shared review logic**

Add assertions in `macos/TodoFocusMac/Tests/CoreTests/DailyReviewViewTests.swift` against the extracted board API instead of view-local static functions.

- [ ] **Step 2: Run the focused test target and confirm it fails for the missing shared type**

Run: `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS" -only-testing:CoreTests/DailyReviewViewTests`

Expected: build/test failure because the shared review type does not exist yet.

- [ ] **Step 3: Implement the extracted board model and helpers**

Create `macos/TodoFocusMac/Sources/Core/Review/DailyReviewBoard.swift` with:
- `DailyReviewBoard`
- `DailyReviewTimeBucket`
- `DailyReviewColumn`
- `DailyReviewLane`
- `sortedForReview(_:)`
- `dueText(for:now:calendar:)`
- `dueBucket(for:now:calendar:)`
- `buildBoard(_:now:calendar:)`
- `sortColumnTodos(_:)`

Keep behavior identical to the existing `DailyReviewView` implementation.

- [ ] **Step 4: Switch `DailyReviewView` to consume the shared types**

Replace nested Daily Review board logic in `macos/TodoFocusMac/Sources/Features/Review/DailyReviewView.swift` with calls to the extracted shared implementation, keeping the UI behavior unchanged.

- [ ] **Step 5: Re-run the focused review tests and confirm they pass**

Run: `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS" -only-testing:CoreTests/DailyReviewViewTests`

Expected: `** TEST SUCCEEDED **`

### Task 2: Centralize app-group database path lookup

**Files:**
- Create: `macos/TodoFocusMac/Sources/Data/Database/AppGroupDatabasePath.swift`
- Modify: `macos/TodoFocusMac/Sources/Data/Database/DatabaseManager.swift`
- Modify: `macos/TodoFocusMac/Sources/Agent/AgentDatabase.swift`

- [ ] **Step 1: Write a focused path helper API**

Create `AppGroupDatabasePath.swift` with one small helper that returns the shared `todofocus.db` path for app group `group.com.todofocus`, with the existing fallback to `~/Library/Application Support/todofocus/todofocus.db`.

- [ ] **Step 2: Replace duplicated path logic in `DatabaseManager`**

Update `DatabaseManager.defaultDatabasePath()` to call the new helper.

- [ ] **Step 3: Replace duplicated path logic in `AgentDatabase`**

Update `AgentDatabase` initialization to call the new helper.

- [ ] **Step 4: Run the focused review tests again to confirm no regressions**

Run: `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS" -only-testing:CoreTests/DailyReviewViewTests`

Expected: `** TEST SUCCEEDED **`

## Chunk 2: Widget data and UI

### Task 3: Add a read-only widget snapshot store

**Files:**
- Create: `macos/TodoFocusMac/Sources/WidgetExtension/DailyReviewWidgetStore.swift`
- Create: `macos/TodoFocusMac/Sources/WidgetExtension/DailyReviewWidgetEntry.swift`
- Create: `macos/TodoFocusMac/Sources/WidgetExtension/DailyReviewWidgetProvider.swift`
- Modify: `macos/TodoFocusMac/Tests/CoreTests/DailyReviewViewTests.swift`

- [ ] **Step 1: Add tests for widget snapshot shaping**

Add test coverage for the snapshot behavior that the widget will need: open-task prioritization, bucket grouping, and capped preview rows.

- [ ] **Step 2: Run the focused tests and confirm they fail for missing widget snapshot types**

Run: `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS" -only-testing:CoreTests/DailyReviewViewTests`

Expected: build/test failure because widget snapshot types do not exist yet.

- [ ] **Step 3: Implement the read-only widget store**

Create `DailyReviewWidgetStore.swift` that:
- opens the shared database using `AppGroupDatabasePath`
- reads todos through GRDB
- maps `TodoRecord` to `Todo`
- filters archived todos out
- builds a `DailyReviewBoard`
- shapes a compact preview snapshot for small/medium widget families

- [ ] **Step 4: Implement timeline entry and provider**

Create `DailyReviewWidgetEntry.swift` and `DailyReviewWidgetProvider.swift` with placeholder, snapshot, and timeline logic for a read-only preview widget.

- [ ] **Step 5: Re-run the focused tests and confirm they pass**

Run: `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS" -only-testing:CoreTests/DailyReviewViewTests`

Expected: `** TEST SUCCEEDED **`

### Task 4: Build the widget UI

**Files:**
- Create: `macos/TodoFocusMac/Sources/WidgetExtension/TodoFocusWidgetsBundle.swift`
- Create: `macos/TodoFocusMac/Sources/WidgetExtension/DailyReviewWidget.swift`
- Create: `macos/TodoFocusMac/Sources/WidgetExtension/DailyReviewWidgetView.swift`

- [ ] **Step 1: Implement the widget bundle and widget definition**

Add the WidgetKit entry point and configure supported families for the preview-only widget.

- [ ] **Step 2: Implement the widget SwiftUI view**

Build a compact dark UI that follows TodoFocus visual language:
- dark elevated background
- subtle border
- terracotta accent
- compact task preview rows
- no edit controls or mutation actions

- [ ] **Step 3: Keep interaction scope minimal**

Allow only normal widget behavior such as opening the app; do not add buttons, intents, completion toggles, or task editing.

- [ ] **Step 4: Verify the widget compiles in previews/build**

Run: `xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -target "TodoFocusWidgetExtension" -destination "platform=macOS"`

Expected: `** BUILD SUCCEEDED **`

## Chunk 3: Project wiring and full verification

### Task 5: Add the widget target and entitlements through XcodeGen

**Files:**
- Modify: `macos/TodoFocusMac/project.yml`
- Create: `macos/TodoFocusMac/WidgetExtension-Info.plist`
- Create: `macos/TodoFocusMac/TodoFocusWidgetExtension.entitlements`
- Create: `macos/TodoFocusMac/TodoFocusMac.entitlements`

- [ ] **Step 1: Update `project.yml` for shared sources and widget target**

Add a new macOS widget extension target that includes:
- widget sources under `Sources/WidgetExtension/**`
- shared review/domain files needed by the widget
- GRDB dependency if the widget store reads the database directly
- `INFOPLIST_FILE`
- `CODE_SIGN_ENTITLEMENTS`

Also exclude `Sources/WidgetExtension/**` from the main app target so the widget `@main` entry point is not compiled into the app binary.

- [ ] **Step 2: Add entitlements**

Create app and widget entitlements files that both include application group `group.com.todofocus`.

- [ ] **Step 3: Add widget Info.plist**

Create the widget extension Info.plist referenced by XcodeGen.

- [ ] **Step 4: Regenerate the Xcode project**

Run: `xcodegen generate`

Workdir: `macos/TodoFocusMac`

Expected: project generation succeeds with the new widget target.

### Task 6: Full verification and manual QA

**Files:**
- Verify all modified and created files above

- [ ] **Step 1: Run diagnostics on changed Swift sources**

Use language-server diagnostics on the changed Swift files and fix any new errors.

- [ ] **Step 2: Run the full app test suite**

Run: `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"`

Expected: `** TEST SUCCEEDED **`

- [ ] **Step 3: Run the release build**

Run: `xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -configuration Release -derivedDataPath "macos/TodoFocusMac/build/DerivedData" -destination "platform=macOS"`

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Execute manual QA for the widget**

Manual QA must show actual evidence:
- launch/build the app so the shared DB exists
- confirm the widget extension product is generated
- add or preview the widget and confirm it renders Daily Review preview content
- confirm the widget contains preview information only and no editing controls

- [ ] **Step 5: Read all changed files for final review**

Before completion, read the final changed files and confirm the implementation matches the requested scope exactly.
