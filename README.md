# TodoFocus

Local-first native macOS todo app for focused execution, not just list keeping.

TodoFocus combines familiar task management with a launch-oriented workflow:
- capture and organize tasks quickly
- filter by time per view
- open the exact work context (URLs, files, apps) from each task

## Why TodoFocus

Most todo apps stop at "remember this." TodoFocus helps you "start now."

- Local-first by default (SQLite, no account required)
- Fast desktop workflow with SwiftUI + native pickers
- Context Launchpad Tasks: one task can launch all related resources
- Clean focus-oriented UI with animated interactions

## What Makes It Different

1. Context Launchpad Tasks
   - Attach `url`, `file`, and `app` resources to a task
   - Click `Launch All` to open your work context instantly
2. Per-view Time Filters
   - Apply date windows in every view (`Overdue`, `Today`, `Tomorrow`, `Next 7 days`, `No date`)
3. Local-first Desktop Runtime
   - Data lives on your machine
   - Native desktop interactions (file/app picker, launch actions)

## Features

- **My Day / Important / Planned** -- smart lists that filter automatically
- **Smart-list quick add** -- adding inside Important/Planned now preserves the list intent automatically
- **Per-view time filters** -- filter any list by `Overdue`, `Today`, `Tomorrow`, `Next 7 days`, or `No date`
- **Custom lists** -- create, rename, delete with color coding
- **Subtasks (Steps)** -- break tasks into smaller pieces
- **Due dates** -- with relative display (Today, Tomorrow, Overdue)
- **Notes** -- per-task free-text notes with auto-save
- **Context Launchpad Tasks (MVP)** -- attach `URL`, `File`, and `App` resources to a task and launch all in one click
- **Native file/app pickers** -- pick launch targets from desktop dialogs instead of manually typing paths
- **Resizable detail panel** -- drag to widen/narrow right panel for long resource values
- **Dark / Light theme** -- toggle with persistence, dark by default
- **Smooth native animations** -- SwiftUI transitions throughout
- **Local SQLite** -- all data stays on your machine, zero cloud dependency

## Screens and UX

- Three-panel app shell (lists, tasks, detail)
- Resizable detail panel for dense task metadata
- Native file/app picker buttons for launch resources
- Smooth task/list transitions with Framer Motion

## Quick Start

```bash
git clone https://github.com/michaelmjhhhh/TodoFocus.git
cd TodoFocus/macos/TodoFocusMac
brew install xcodegen
xcodegen generate
xcodebuild build -project "TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"
```

For tests:

```bash
xcodebuild test -project "TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"
```

## Requirements

- **Xcode** 16+
- **macOS** 14+
- **xcodegen**

No external database needed. No API keys. No accounts.

## Tech Stack

| Layer | Tech |
|-------|------|
| App Framework | SwiftUI |
| State | Observation (`@Observable`) |
| Database | SQLite via GRDB |
| Build | Xcode + xcodebuild |
| Packaging | zipped `.app` in GitHub Releases |

## Project Structure

```
macos/TodoFocusMac/
  Sources/
    App/                # app model, stores, launch services
    Core/               # pure domain models and filters
    Data/               # GRDB migrations and repositories
    Features/           # Sidebar, TaskList, TaskDetail
  Tests/
    CoreTests/          # domain and behavior tests
    DataTests/          # migration and repository tests
```

## Development

```bash
xcodegen generate
xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"
xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"
```

## Delivery Workflow

- For bugs, follow evidence-first debugging (root cause before code changes).
- For new features, we use: `issue -> branch -> implement -> PR`.
- Prefer a short implementation plan for non-trivial features before coding.

## Open Source Notes

- License: MIT
- Contributions: Issues and PRs are welcome
- Security baseline: launch actions are validated and executed via native macOS APIs (no shell execution)

## Desktop Packaging (Native macOS)

### Build rules we follow

- Release artifact is zipped `.app` uploaded to GitHub Releases.
- App Store distribution is out of scope.
- Build and test from a clean, updated `main`.
- Generate checksum (`sha256`) for each uploaded zip.

### Commands

```bash
xcodegen generate
xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"
xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -configuration Release -derivedDataPath "macos/TodoFocusMac/build/DerivedData" -destination "platform=macOS"
APP_PATH="macos/TodoFocusMac/build/DerivedData/Build/Products/Release/TodoFocusMac.app"
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "dist-native/TodoFocus-macos-universal.zip"
shasum -a 256 "dist-native/TodoFocus-macos-universal.zip" > "dist-native/TodoFocus-macos-universal.zip.sha256"
```

### CI Release (Required, CI-first)

Release artifacts should come from GitHub Actions workflow `release-macos-native`.
Do not manually upload local assets unless CI is unavailable and maintainers approve an emergency fallback.

1. Start from clean, updated `main`:
   - `git checkout main && git pull`
2. Create and push the release tag:
   - `git tag vX.Y.Z`
   - `git push origin vX.Y.Z`
3. Trigger release workflow for that tag:
   - `gh workflow run release-macos-native -f tag=vX.Y.Z`
4. Monitor the run:
   - `gh run list --workflow release-macos-native --limit 5`
   - `gh run watch <run-id>`
5. Verify assets on the release page:
   - `gh release view vX.Y.Z --json assets,url`
    - Confirm expected files are attached (`TodoFocus-macos-universal.zip` and checksum file).

### If Workflow Fails (Retry / Rollback)

1. Inspect logs: `gh run view <run-id> --log`.
2. Retry workflow for transient failures (runner/network/signing issues).
3. If assets are bad, remove only broken assets and rerun:
   - `gh release delete-asset vX.Y.Z <asset-name> -y`
4. If tag was incorrect, recreate it:
   - `git tag -d vX.Y.Z`
   - `git push origin :refs/tags/vX.Y.Z`
   - Create correct tag and run `release-macos` again.

### Quick DMG creation (fast path)

When `dist-electron/mac-arm64/TodoFocus.app` already exists and works, create/replace a DMG directly:

```bash
hdiutil create -volname "TodoFocus" \
  -srcfolder "dist-electron/mac-arm64/TodoFocus.app" \
  -ov -format UDZO "dist-electron/TodoFocus-mac-arm64.dmg"
```

Use local packaging only for validation or emergency-only release recovery, not as the normal release path.

### Runtime and local data

- App is native SwiftUI and uses GRDB-backed SQLite locally.
- On first launch, GRDB migrations are applied automatically.
- Local database path on macOS:
  - `~/Library/Application Support/todofocus/todofocus.db`

### Launchpad Safety Model

- Launch actions are executed with native macOS APIs (`NSWorkspace`), not shell commands.
- Resource payloads are validated before persistence and before launch.
- URL schemes are allowlisted and invalid payloads are rejected.

### Common issue and fix

- If build fails after file moves, run `xcodegen generate` and rebuild.
- If app data looks stale, remove `~/Library/Application Support/todofocus/todofocus.db` for a clean local reset.
- If picker/launch behavior fails, verify app has macOS file access permissions.

## License

MIT
