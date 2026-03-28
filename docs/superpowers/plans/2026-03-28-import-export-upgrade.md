# Import/Export Upgrade Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade TodoFocus data import/export so it is safer (preflight + backup), more compatible (version-aware decode), and clearer for users (explicit import mode + result summary).

**Architecture:** Keep `ExportService` as the core boundary for serialization/import logic, add a preflight + report layer, and expose explicit import options in `SettingsView`. Use a two-phase import flow: validate first, then transactional apply. Backward compatibility remains for existing `1.0` exports while introducing a richer `1.1` payload.

**Tech Stack:** Swift 6, GRDB/SQLite, SwiftUI (macOS), Codable, NSSavePanel/NSOpenPanel, XCTest.

---

## File Structure

- `macos/TodoFocusMac/Sources/Data/Export/ExportModels.swift`
Responsibility: export/import payload schema, versioned metadata, and Codable defaults for backward compatibility.

- `macos/TodoFocusMac/Sources/Data/Export/ExportService.swift`
Responsibility: export generation, import preflight, transactional import execution, import mode handling (`replace` / `merge`), and structured import result.

- `macos/TodoFocusMac/Sources/Features/Settings/SettingsView.swift`
Responsibility: import/export UI actions, import mode selection, preflight confirmation UX, and showing summary/error output.

- `macos/TodoFocusMac/Tests/DataTests/ExportServiceTests.swift` (new)
Responsibility: core round-trip, version compatibility, replace vs merge semantics, and invalid payload behavior.

- `macos/TodoFocusMac/Tests/CoreTests/SettingsImportExportFlowTests.swift` (new, lightweight)
Responsibility: UI-level state behavior for import mode and preflight/result alerts (without file panel integration).

- `docs/superpowers/issues/2026-03-28-import-export-upgrade-notes.md` (new)
Responsibility: behavior changes, migration notes, and known constraints for users/maintainers.

---

## Chunk 1: Data Contract + Service Core

### Task 1: Introduce versioned export schema (`1.1`) with backward compatibility

**Files:**
- Modify: `macos/TodoFocusMac/Sources/Data/Export/ExportModels.swift`
- Test: `macos/TodoFocusMac/Tests/DataTests/ExportServiceTests.swift`

- [ ] **Step 1: Write failing compatibility tests first (@superpowers:test-driven-development)**
```swift
func testDecodeV1_0PayloadStillWorks() throws
func testDecodeV1_1PayloadIncludesMetadata() throws
```

- [ ] **Step 2: Run test to verify failures**
Run: `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS" -only-testing:DataTests/ExportServiceTests`
Expected: FAIL with missing fields / decode path not implemented.

- [ ] **Step 3: Add schema updates in `ExportModels.swift`**
- Add `ExportFormatVersion` constants (`1.0`, `1.1`, current = `1.1`).
- Add optional `meta` block (app version, platform, importHints).
- Keep decoding compatible with `1.0` by making new fields optional/defaulted.

- [ ] **Step 4: Re-run targeted tests**
Run same command as Step 2.
Expected: PASS for compatibility decode tests.

- [ ] **Step 5: Commit**
```bash
git add macos/TodoFocusMac/Sources/Data/Export/ExportModels.swift macos/TodoFocusMac/Tests/DataTests/ExportServiceTests.swift
git commit -m "feat(export): add versioned schema with backward-compatible decoding"
```

### Task 2: Add import preflight and structured import report

**Files:**
- Modify: `macos/TodoFocusMac/Sources/Data/Export/ExportService.swift`
- Test: `macos/TodoFocusMac/Tests/DataTests/ExportServiceTests.swift`

- [ ] **Step 1: Write failing tests for preflight/report**
```swift
func testPreflightRejectsUnsupportedVersion() throws
func testPreflightReturnsCountsAndWarnings() throws
func testImportReturnsStructuredReport() throws
```

- [ ] **Step 2: Run tests to verify failures**
Run: same `-only-testing:DataTests/ExportServiceTests`
Expected: FAIL for missing APIs/types.

- [ ] **Step 3: Implement preflight + report types**
- Add `ImportMode` enum (`replace`, `merge`).
- Add `ImportPreflightResult` (version, counts, warnings, blockingErrors).
- Add `ImportExecutionReport` (created/updated/skipped/errors per entity type).
- Split `importFromJSON` into:
  - `preflightImportJSON(_:)`
  - `executeImportJSON(_:mode:)`

- [ ] **Step 4: Keep import transactional and deterministic**
- `replace`: clear existing data then import.
- `merge`: upsert by IDs (list/todo/step), preserve unrelated existing rows.
- Ensure launch resources decoding failures are counted and skipped instead of hard crash when possible.

- [ ] **Step 5: Re-run tests**
Expected: PASS for new report/preflight tests.

- [ ] **Step 6: Commit**
```bash
git add macos/TodoFocusMac/Sources/Data/Export/ExportService.swift macos/TodoFocusMac/Tests/DataTests/ExportServiceTests.swift
git commit -m "feat(import): add preflight validation and execution report"
```

### Task 3: Add safe backup snapshot before destructive replace import

**Files:**
- Modify: `macos/TodoFocusMac/Sources/Data/Export/ExportService.swift`
- Modify: `macos/TodoFocusMac/Sources/Data/Database/DatabaseManager.swift` (only if needed for path helper)
- Test: `macos/TodoFocusMac/Tests/DataTests/ExportServiceTests.swift`

- [ ] **Step 1: Write failing test for backup on replace import**
```swift
func testReplaceImportCreatesBackupSnapshotBeforeMutation() throws
```

- [ ] **Step 2: Run test to verify failure**
Run: same DataTests command.
Expected: FAIL because backup file is not generated.

- [ ] **Step 3: Implement backup path and write flow**
- Create timestamped backup json before `replace` mutation.
- Return backup path in `ImportExecutionReport`.
- Ensure write failure aborts replace import (no partial mutation).

- [ ] **Step 4: Re-run tests**
Expected: PASS for backup behavior.

- [ ] **Step 5: Commit**
```bash
git add macos/TodoFocusMac/Sources/Data/Export/ExportService.swift macos/TodoFocusMac/Sources/Data/Database/DatabaseManager.swift macos/TodoFocusMac/Tests/DataTests/ExportServiceTests.swift
git commit -m "fix(import): create backup snapshot before replace import"
```

---

## Chunk 2: Settings UX + Documentation

### Task 4: Add explicit import mode and preflight confirmation UI

**Files:**
- Modify: `macos/TodoFocusMac/Sources/Features/Settings/SettingsView.swift`
- Test: `macos/TodoFocusMac/Tests/CoreTests/SettingsImportExportFlowTests.swift`

- [ ] **Step 1: Write failing UI-state tests first**
```swift
func testImportModeDefaultsToReplace() throws
func testPreflightSummaryShownBeforeExecuteImport() throws
func testImportResultAlertShowsCountsAndBackupPath() throws
```

- [ ] **Step 2: Run tests to verify failures**
Run: `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS" -only-testing:CoreTests/SettingsImportExportFlowTests`
Expected: FAIL for missing state/handlers.

- [ ] **Step 3: Implement UI flow in `SettingsView`**
- Add import mode control (`Replace existing data`, `Merge into existing data`).
- On file pick: call preflight and show confirmation dialog before execution.
- On execute: show success alert with counts + backup path when present.
- Keep existing export path unchanged except better error text.

- [ ] **Step 4: Re-run tests**
Expected: PASS for new flow tests.

- [ ] **Step 5: Commit**
```bash
git add macos/TodoFocusMac/Sources/Features/Settings/SettingsView.swift macos/TodoFocusMac/Tests/CoreTests/SettingsImportExportFlowTests.swift
git commit -m "feat(settings): add import mode and preflight confirmation flow"
```

### Task 5: Round-trip + regression verification

**Files:**
- Modify: `macos/TodoFocusMac/Tests/DataTests/ExportServiceTests.swift`

- [ ] **Step 1: Add comprehensive round-trip tests**
- Export from populated DB, import to empty DB (`replace`) and compare entities.
- Import legacy `1.0` payload and verify no crash + expected defaults.
- Merge import should update matching IDs and keep unrelated local rows.

- [ ] **Step 2: Run DataTests target slice**
Run: `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS" -only-testing:DataTests/ExportServiceTests`
Expected: PASS.

- [ ] **Step 3: Run app build sanity check**
Run: `xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"`
Expected: BUILD SUCCEEDED.

- [ ] **Step 4: Commit**
```bash
git add macos/TodoFocusMac/Tests/DataTests/ExportServiceTests.swift
git commit -m "test(export): add round-trip and merge/compat regression coverage"
```

### Task 6: Docs and release notes for behavior changes

**Files:**
- Create: `docs/superpowers/issues/2026-03-28-import-export-upgrade-notes.md`
- Modify: `README.md` (if import/export behavior section exists)

- [ ] **Step 1: Write behavior-change notes**
- Explain new import modes.
- Explain preflight validation and backup-on-replace.
- Explain `1.0` compatibility and `1.1` current format.

- [ ] **Step 2: Add short user-facing docs snippet**
- Settings > Import/Export quick guide.

- [ ] **Step 3: Commit**
```bash
git add docs/superpowers/issues/2026-03-28-import-export-upgrade-notes.md README.md
git commit -m "docs(import-export): document preflight, backup, and mode semantics"
```

---

## Final Verification Checklist

- [ ] `DataTests/ExportServiceTests` passes.
- [ ] `CoreTests/SettingsImportExportFlowTests` passes.
- [ ] Full app build passes.
- [ ] Legacy `1.0` import still works.
- [ ] Replace import creates backup and reports path.
- [ ] Merge import does not delete unrelated local data.

Plan complete and saved to `docs/superpowers/plans/2026-03-28-import-export-upgrade.md`. Ready to execute?
