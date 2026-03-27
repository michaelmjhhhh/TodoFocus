# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TodoFocus is a native macOS todo app built with SwiftUI + Observation + GRDB/SQLite. It features a three-panel layout (Sidebar, TaskList, TaskDetail), per-view time filtering, Context Launchpad Tasks (attach url/file/app resources), Deep Focus sessions with timer, and Quick Capture global hotkey.

## Build Commands

```bash
# Generate Xcode project (required after adding/removing/renaming files)
xcodegen generate

# Build
xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"

# Test
xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"

# Run a single test file (example)
xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS" -only-testing:CoreTests/TodoAppStoreTests
```

## Architecture

```
macos/TodoFocusMac/Sources/
  App/           # AppModel, TodoAppStore, DeepFocusService, LaunchpadService, QuickCaptureService
  Core/          # Domain models (Todo, List, Step, LaunchResource) and filters (SmartList, TimeFilter, TodoQuery)
  Data/          # GRDB database setup, migrations, DTOs (Record types), and repositories
  Features/      # SwiftUI views organized by feature (Sidebar, TaskList, TaskDetail, Common, QuickCapture)
```

### State Management

- **`@Observable @MainActor TodoAppStore`** is the central state holder - owns lists/todos, coordinates CRUD via repositories, applies `AppModel.query()` to compute visible todos
- **`AppModel`** holds UI state: selected sidebar item, selected todo ID, time filter, sort order, theme, window size
- **`DeepFocusService`** runs focus sessions with blocked-app enforcement and stats tracking

### Data Flow

```
GRDB Records (TodoRecord, ListRecord, StepRecord)
    ↓ Record extensions map to domain models (Todo, TodoList, TodoStep)
    ↓ Repositories fetch/store records
    ↓ TodoAppStore orchestrates and exposes to views
    ↓ SwiftUI Views observe TodoAppStore
```

### Key Patterns

- **Separation of concerns**: Views only handle UI; TodoAppStore handles business logic; repositories handle persistence
- **Debounced saves**: Notes update with 0.5s debounce via `DispatchWorkItem`
- **Launch resource security**: Validated via `LaunchResourceValidation` before persistence; launched via `NSWorkspace` only
- **GRDB migrations**: Applied automatically on first launch via `DatabaseManager` using `Migrations.makeMigrator()`

### Database

- Path: `~/Library/Application Support/todofocus/todofocus.db`
- Migrations v1: creates `list`, `todo`, `step` tables with indexes
- Migrations v2: adds `focusTimeSeconds` to `todo`
- Delete `todofocus.db` to reset local data

## Contributor Guidelines

- Keep changes focused and small; avoid unrelated refactors in the same PR.
- Follow existing stack: SwiftUI + Observation, GRDB + SQLite, native macOS APIs.
- Run checks before opening a PR: `xcodebuild test ...` and a quick local build.
- Do not commit secrets (`.env`, local DB files, signing credentials).
- For data model changes, include GRDB migration updates and verify app startup still applies migrations.
- For non-trivial feature work, write a plan in `docs/superpowers/plans/` before implementation.

## Security Guardrails (Launchpad)

- Never add shell/command execution for launch resources.
- Keep launch operations in native macOS service (`NSWorkspace`) with strict payload validation.
- URL scheme allowlist restrictions must reject unsupported payloads.

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| ⌘⇧T | Quick Capture (global hotkey, requires Accessibility permission) |
| ⌘⇧F | Start Deep Focus on selected task |
| ⌘⇧L | Toggle theme (Dark → Light → System) |
| ⌘⇧N | Add new task to current view |
| ⌘K | Search tasks by title and notes |

## Release Workflow

Releases use the `release-macos-native` GitHub Actions workflow triggered by `v*` tags:

```bash
git checkout main && git pull
git tag vX.Y.Z
git push origin vX.Y.Z
gh workflow run release-macos-native -f tag=vX.Y.Z
```

Do not manually upload local artifacts unless CI is unavailable and maintainers explicitly approve.

## Important Notes

- After file moves/renames, run `xcodegen generate` before building
- Quick Capture (⌘⇧T) requires macOS Accessibility permission; app will prompt on first use
- If picker/launch behavior fails, verify macOS file access permissions
- GRDB.swift is a git submodule at `vendor/GRDB.swift`; ensure submodules are initialized on clone
