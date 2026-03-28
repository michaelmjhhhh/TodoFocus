# TodoFocus

<p align="center">
  <img src="assets/overdue-screenshot.png" alt="TodoFocus Screenshot" width="960" />
</p>

<p align="center">
  <a href="https://github.com/michaelmjhhhh/TodoFocus/releases"><img src="https://img.shields.io/github/v/release/michaelmjhhhh/TodoFocus?label=latest%20release" alt="Latest Release" /></a>
  <img src="https://img.shields.io/badge/macOS-14%2B-0A84FF" alt="macOS 14+" />
  <img src="https://img.shields.io/badge/Built%20With-SwiftUI-F2994A" alt="SwiftUI" />
  <img src="https://img.shields.io/badge/Storage-Local%20SQLite-4F8A3D" alt="Local SQLite" />
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-AGPL--3.0-2D2D2D" alt="License" /></a>
</p>

<p align="center">
  <strong>A local-first macOS task app for people who want to finish real work.</strong>
</p>

<p align="center">
  Pick a task. Launch your context. Block distractions. Ship.
</p>

## Why TodoFocus

Most todo apps are great at collecting tasks and weak at execution.

TodoFocus is built around one question: <strong>how fast can you move from "I should do this" to deep, uninterrupted execution?</strong>

- `No account, no cloud setup`: runs locally with SQLite
- `Focus-first workflow`: start Deep Focus from the selected task
- `Context Launchpad`: open URLs/files/apps tied to the task in one click
- `Quick Capture (⌘⇧T)`: capture ideas instantly without leaving current app

## What Makes It Different

| Typical Todo App | TodoFocus |
|---|---|
| Organize tasks | Execute tasks |
| Manual context switching | `Launch All` restores working context |
| Easy to get distracted | Deep/Hard Focus can block distraction paths |
| Notes live in one place | Quick Capture injects thoughts during active focus |

## Core Capabilities

### Execution
- `Deep Focus`: timed or infinite sessions with stats tracking
- `Hard Focus`: stronger lock mode for strict focus windows
- `Session completion`: timer-based session completion flow with task progress updates

### Tasking
- Smart views: overdue, today, tomorrow, next 7 days, no date
- Custom lists with color indicators
- My Day list for daily priorities
- Search (`⌘K`) across titles and notes

### Context Launchpad
- Attach `url`, `file`, `app` resources per task
- Click `Launch All` to restore work context instantly
- Native macOS launch behavior (no shell command execution)

## Install

### Recommended: Download Release

1. Open: <https://github.com/michaelmjhhhh/TodoFocus/releases>
2. Download `TodoFocus-macos-universal.zip`
3. Unzip and move `TodoFocusMac.app` to `Applications`

### Build From Source

```bash
brew install xcodegen
git clone https://github.com/michaelmjhhhh/TodoFocus.git
cd TodoFocus/macos/TodoFocusMac
xcodegen generate
xcodebuild build -project "TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"
```

## First-Run Permissions

For global quick capture (`⌘⇧T`), grant Accessibility permission:
`System Settings -> Privacy & Security -> Accessibility`

## Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| `⌘⇧T` | Quick Capture (global) |
| `⌘⇧F` | Start Deep Focus for selected task |
| `⌘⇧N` | Add new task |
| `⌘K` | Search |

## Data and Privacy

- Local-first by default
- Database path: `~/Library/Application Support/todofocus/todofocus.db`
- Import/Export includes backup-safe replace and merge modes

## Project Status

Actively maintained.

If you run into a bug, open an issue with:
- reproduction steps
- expected behavior
- actual behavior
- macOS version

Issues: <https://github.com/michaelmjhhhh/TodoFocus/issues>

## If This Helps You

- Star the repo: <https://github.com/michaelmjhhhh/TodoFocus>
- Share it with one macOS productivity nerd friend
- Open an issue with your workflow pain points

## License

[AGPL-3.0](LICENSE)
