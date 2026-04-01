# TodoFocus

<p align="center">
  <img src="assets/readme-logo.png" alt="TodoFocus Icon" width="108" />
</p>

<p align="center">
  <strong>A native, local-first macOS task app for deep work.</strong><br/>
  Capture quickly, launch context in one click, focus with fewer distractions, and review your day in kanban form.
</p>

<p align="center">
  <a href="https://github.com/michaelmjhhhh/TodoFocus/releases"><img src="https://img.shields.io/badge/Download-Latest%20Release-0A84FF?style=for-the-badge" alt="Download Latest Release" /></a>
  <a href="#build-from-source"><img src="https://img.shields.io/badge/Build-From%20Source-2F855A?style=for-the-badge" alt="Build from Source" /></a>
</p>

<p align="center">
  <img src="https://img.shields.io/github/v/release/michaelmjhhhh/TodoFocus?label=latest%20release" alt="Latest Release" />
  <img src="https://img.shields.io/badge/macOS-14%2B-0A84FF" alt="macOS 14+" />
  <img src="https://img.shields.io/badge/SwiftUI-Native-F2994A" alt="SwiftUI Native" />
  <img src="https://img.shields.io/badge/Data-Local%20SQLite-4F8A3D" alt="Local SQLite" />
</p>

<p align="center">
  <img src="assets/overdue-screenshot.png" alt="TodoFocus Main UI" width="980" />
</p>

## Why TodoFocus

TodoFocus is designed for people who want one lightweight desktop workspace for:

- fast thought capture
- task context launch (`url`, `file`, `app`)
- distraction-resistant focus sessions
- end-of-day review and cleanup

No account required. No cloud dependency required. Data stays on your Mac.

## Feature Overview

| Area | What you get |
|---|---|
| Quick Capture | Global shortcut `⌘⇧T` to capture from anywhere. |
| Voice Capture | English (`en-US`) speech recognition, partial preview, final-first commit. |
| Deep Focus | Focus sessions with timer, menu bar controls, and stats. |
| Hard Focus | Stronger enforcement mode with app blocking and passphrase-based exit flow. |
| Launchpad | Attach URL/file/app resources, use native pickers, run Launch All. |
| Daily Review | Kanban review with Open/Completed lanes and time buckets. |
| Task List UX | Custom list colors, row color indicators, collapsible completed panel. |
| Detail Panel | Drag-resizable task detail panel with persisted width across launches. |
| Smart Views | `My Day`, `Important`, `Planned`, `Overdue`, `All Tasks`, and custom lists. |
| Search | `⌘K` local search across task titles and notes. |
| Portability | JSON import/export for lists, todos, steps, and URL launch resources (file/app are skipped). |

## Daily Review

Daily Review is built for manual cleanup and planning.

- Open and Completed both use: `Overdue`, `Today`, `Tomorrow`, `Later`, `No Date`
- Completed lane is collapsed by default
- Each column has independent collapse/expand state
- Cards are sorted by due date then title
- Card actions include `Done`, `My Day`, and `Reschedule` (`Today`, `Tomorrow`, `Next 7 Days`, `No Date`)

> [!NOTE]
> Daily Review uses page-level scrolling with lane/column collapse controls to keep rendering lightweight while still handling large task sets.

## Quick Capture and Voice

- Open Quick Capture globally with `⌘⇧T`
- If Deep Focus is active, capture appends a timestamped line to focus-task notes
- If no Deep Focus is active, capture creates a new Inbox task from the captured text
- Voice mode is English-only (`en-US`)
- Partial transcript is preview-only; final transcript is prioritized for commit
- Short silence auto-finalizes recording (~1.6s)
- If voice permissions are denied, typing still works

### Quick Capture permission matrix

- Global hotkey (`⌘⇧T`): Accessibility permission
- Voice capture: Microphone + Speech Recognition permissions
- In-app permission warning opens macOS Settings directly

## Launchpad and Safety

Launchpad lets each task carry execution context:

- `url` resources
- `file` resources
- `app` resources

Security model:

- Launch operations use native `NSWorkspace`
- Payload validation rejects invalid or unsupported launch resources
- URL handling enforces safe payload constraints
- No shell command execution path is used for launch resources

## Data and Import/Export

TodoFocus uses local SQLite storage:

- App data dir: `~/Library/Application Support/todofocus/`
- DB file: `~/Library/Application Support/todofocus/todofocus.db`

Import/export behavior:

- Format: JSON (`1.0`, `1.1`, `1.2` supported)
- Portable entities: lists, todos, steps, URL launch resources
- Non-portable `file`/`app` launch resources are skipped and reported
- Import `merge`: upserts matching IDs and keeps unrelated local data
- Import `replace`: clears app data then imports, with automatic backup snapshot
- Replace backups are written to `~/Library/Application Support/todofocus/backups/`
- Preflight validation checks version compatibility and duplicate IDs

> [!TIP]
> File and app paths are machine-local. URL-only portability avoids broken resources when moving to another Mac.

## Keyboard Shortcuts

### Global

| Shortcut | Action |
|---|---|
| `⌘⇧T` | Open Quick Capture |

### In-app

| Shortcut | Action |
|---|---|
| `⌘⇧F` | Start Deep Focus for selected task |
| `⌘K` | Search tasks (title + notes) |
| `⌘⇧N` | Add task to current view |
| `⌘⇧L` | Toggle theme |
| `Return` | Confirm Quick Capture Add |
| `Esc` | Cancel Quick Capture |

> [!NOTE]
> The in-app shortcut hint bar mirrors the current bindings: `⌘⇧T`, `⌘⇧F`, `⌘K`, `⌘⇧L`, `⌘⇧N`.

## Build From Source

### Requirements

- macOS 14+
- Xcode 16+
- `xcodegen` 2.38.0+
- Git submodules initialized (GRDB is vendored as a submodule)

### Build and test

```bash
brew install xcodegen
git clone --recurse-submodules https://github.com/michaelmjhhhh/TodoFocus.git
cd TodoFocus/macos/TodoFocusMac

xcodegen generate
xcodebuild test -project "TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"
xcodebuild build -project "TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -configuration Release -derivedDataPath "build/DerivedData" -destination "platform=macOS"
```

If you cloned without submodules:

```bash
git submodule update --init --recursive
```

## Native Release Flow (CI-first)

Release assets are produced by GitHub Actions workflow `release-macos-native`.

1. Start from updated `main`
2. Create and push tag `vX.Y.Z`
3. Wait for `release-macos-native` to finish
4. Verify release assets (`TodoFocus-macos-universal.zip` + `.sha256`)

```bash
git checkout main && git pull
git tag vX.Y.Z
git push origin vX.Y.Z

gh run list --workflow release-macos-native --limit 5
gh run watch <run-id>
gh release view vX.Y.Z --json assets,url
```

> [!IMPORTANT]
> `release-macos-native` is the native release path. The legacy `release-macos` workflow is not the primary flow for current native packaging.

## Quick Start

1. Download the latest release from GitHub.
2. Move `TodoFocusMac.app` to `Applications`.
3. Open once and grant requested permissions.
4. Create one task, add one URL resource, then run one Deep Focus session.
5. Trigger `⌘⇧T` and verify Quick Capture flow.
6. Open Daily Review and run one manual cleanup pass.

## Troubleshooting

### Quick Capture shortcut does not trigger

- Re-check Accessibility permission
- Relaunch app after granting permission
- Re-grant permission after app re-sign/rebuild

### Voice capture is inaccurate or feels slow

- Confirm Microphone + Speech Recognition permissions
- Use short complete phrases and pause briefly for finalization
- Reduce background noise and prefer stable audio input

### Build fails after project changes

Run:

```bash
cd macos/TodoFocusMac
xcodegen generate
```

## Demo

<p align="center">
  <img src="assets/demo.gif" alt="TodoFocus Demo" width="980" />
</p>

## Feedback

Issues and feature requests:

- https://github.com/michaelmjhhhh/TodoFocus/issues

If this project helps your workflow, starring the repository is appreciated.
