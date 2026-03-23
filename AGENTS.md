# AGENTS.md

## Contributor Guidelines

- Keep changes focused and small; avoid unrelated refactors in the same PR.
- Follow existing stack and patterns: SwiftUI + Observation, GRDB + SQLite, native macOS APIs.
- Run checks before opening a PR: `xcodebuild test -project \"macos/TodoFocusMac/TodoFocusMac.xcodeproj\" -scheme \"TodoFocusMac\" -destination \"platform=macOS\"` and a quick local build.
- Do not commit secrets (`.env`, local DB files, signing credentials).
- For data model changes, include GRDB migration updates and verify app startup still applies migrations.
- For bug fixes, follow systematic debugging: reproduce -> collect evidence -> identify root cause -> then implement.
- For new features, follow this flow: issue -> branch -> implement -> PR.
- For non-trivial feature work, write a plan in `docs/superpowers/plans/` before implementation.

## Product Notes (Current Differentiators)

- Per-view time filtering is available across smart lists and custom lists.
- Context Launchpad Tasks (MVP): each task can store launch resources (`url`, `file`, `app`) and run Launch All.
- Launchpad UX includes native desktop pickers for file/app resources and a resizable detail panel for long values.
- Custom list colors: each list can have a user-selected color that appears as a left indicator on tasks.
- Collapsible completed panel: toggle to show/hide the completed tasks panel for full-screen active task view.
- Minimalist dark UI: Claude Code-inspired dark theme with terracotta accent (#C46849).
- Quick Capture (⌘⇧T): global hotkey for capturing thoughts; appends to Deep Focus task notes with timestamp, or creates new task in Inbox when no Deep Focus active.
- Deep Focus Stats: tracks cumulative focus time, session count, and distraction count from blocked app attempts.
- Theme toggle: dark/light/system persistence, dark by default.
- Window persistence: detail panel width persists across app launches.
- Search (⌘K): local search across task titles and notes.
- My Day smart list: shows tasks with `isMyDay == true` flag.

## Quick Capture Feature

- **Global hotkey**: ⌘⇧T works system-wide when app is running
- **Requires Accessibility permission**: On first use, macOS will prompt for Accessibility permission in System Settings > Privacy & Security > Accessibility
- **Behavior**: 
  - If Deep Focus is active: appends capture with timestamp to focus task's notes
  - If no Deep Focus: creates new task in Inbox (no list assigned)
- **Permission handling**: App shows orange warning in shortcut bar when permission not granted; clicking opens System Settings directly
- **Important**: Accessibility permission is tied to code signature; if app is rebuilt and re-signed, permission must be re-granted

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| ⌘⇧T | Quick Capture (global hotkey, requires Accessibility permission) |
| ⌘⇧F | Start Deep Focus on selected task (opens setup sheet to select blocked apps) |
| ⌘K | Search tasks by title and notes |
| ⌘⇧N | Add new task to current view |

## Security Guardrails (Launchpad)

- Never add shell/command execution for launch resources.
- Keep launch operations in native macOS service (`NSWorkspace`) with strict payload validation.
- Keep URL scheme allowlist restrictions and reject unsupported payloads.

## Packaging (TodoFocus Native macOS)

### Core Packaging Rules (Must Follow)

- Treat desktop packaging as a native app flow.
- Always package from **clean, updated main** when preparing release artifacts.
- Release assets must be produced by CI workflow (`release-macos-native`) by default.
- Do not manually upload local artifacts unless CI is unavailable and maintainers approve an emergency fallback.
- Primary release artifact is zipped `.app` plus SHA256 checksum.
- App Store distribution is out of scope.

### Build Requirements

- Xcode 16+ and macOS 14+.
- Install `xcodegen`.
- Generate project before build/test: `xcodegen generate` in `macos/TodoFocusMac`.

### Preflight Checklist (Before Release Upload)

1. Verify branch and workspace are correct (`main`, no accidental local-only changes).
2. Run:
   1. `xcodegen generate`
   2. `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"`
3. Build release app:
   - `xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -configuration Release -derivedDataPath "macos/TodoFocusMac/build/DerivedData" -destination "platform=macOS"`
4. Package zip and checksum:
   - `ditto -c -k --sequesterRsrc --keepParent "macos/TodoFocusMac/build/DerivedData/Build/Products/Release/TodoFocusMac.app" "dist-native/TodoFocus-macos-universal.zip"`
   - `shasum -a 256 "dist-native/TodoFocus-macos-universal.zip" > "dist-native/TodoFocus-macos-universal.zip.sha256"`

### Build Commands

- Generate project: `xcodegen generate`
- Run tests: `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"`
- Build Release: `xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -configuration Release -derivedDataPath "macos/TodoFocusMac/build/DerivedData" -destination "platform=macOS"`

### CI-First Release Flow (Required)

1. Start from clean, updated `main`.
2. Create and push the release tag:
   - `git checkout main && git pull`
   - `git tag vX.Y.Z`
   - `git push origin vX.Y.Z`
3. The workflow `release-macos-native` triggers automatically on tag push (`v*`).
4. Monitor until completion:
   - `gh run list --workflow release-macos-native --limit 5`
   - `gh run watch <run-id>`
5. Verify release assets were published:
   - `gh release view vX.Y.Z --json assets,url`
   - Confirm expected files are attached (`TodoFocus-macos-universal.zip` and checksum).

**Manual trigger (fallback):** `gh workflow run release-macos-native -f tag=vX.Y.Z`

### Workflow Failure: Retry / Rollback

1. Open failed run logs: `gh run view <run-id> --log`.
2. If failure is transient (runner/network/signing service), rerun failed jobs from Actions UI or run a new workflow run for the same tag.
3. If release assets are wrong/corrupt, delete only the bad assets and rerun workflow:
   - `gh release delete-asset vX.Y.Z <asset-name> -y`
4. If the tag itself is wrong, remove and recreate it:
   - `git tag -d vX.Y.Z`
   - `git push origin :refs/tags/vX.Y.Z`
   - Create the corrected tag and rerun `release-macos`.

### Emergency-Only Manual Upload (Exception)

- Use only when CI is unavailable and maintainers explicitly approve bypassing CI.
- Before upload, run local native build + test + zip/checksum and smoke test.
- Upload with: `gh release upload <tag> <file> --clobber`.

### Local Data Path

- macOS app data directory: `~/Library/Application Support/todofocus/`
- SQLite database file: `~/Library/Application Support/todofocus/todofocus.db`
- App is native SwiftUI and uses GRDB-backed SQLite in-process.

### Common Troubleshooting

- If build fails after file changes, rerun `xcodegen generate`.
- If runtime DB state is stale, remove `~/Library/Application Support/todofocus/todofocus.db` for clean local reset.
- If launch picker behavior fails, check macOS file access permissions.
