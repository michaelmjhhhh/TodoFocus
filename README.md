# TodoFocus

<p align="center">
  <img src="assets/overdue-screenshot.png" alt="TodoFocus" width="900"/>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-14%2B-blue" alt="macOS 14+"/>
  <img src="https://img.shields.io/badge/SwiftUI-orange" alt="SwiftUI"/>
  <img src="https://img.shields.io/badge/Local--First-SQLite-yellow" alt="Local-first SQLite"/>
  <img src="https://img.shields.io/github/v/release/michaelmjhhhh/TodoFocus" alt="Latest Release"/>
  <img src="https://img.shields.io/github/license/michaelmjhhhh/TodoFocus" alt="License"/>
</p>

A local-first native macOS task app built for focused execution.

TodoFocus is designed for people who want to stay in flow: pick a task, launch context, block distractions, and finish.

## Why It Exists

Most todo apps are good at storing tasks but weak at helping you execute.

TodoFocus prioritizes execution speed:
- Start a focus session directly from a task
- Launch all related resources with one click
- Keep everything local and fast (no account, no sync setup)

## Core Features

- `Deep Focus`: timed or infinite focus sessions with blocked apps and session stats
- `Hard Focus`: stricter lock mode for stronger distraction control
- `Quick Capture` (`⌘⇧T`): capture ideas globally while working in other apps
- `Context Launchpad`: attach URL/file/app resources to any task and launch all
- `Per-view filtering`: overdue, today, tomorrow, next 7 days, no date
- `Search` (`⌘K`): find tasks by title and notes
- `My Day`: daily intent list for high-priority execution

## Quick Start

### Option 1: Use Release Build (recommended)

1. Open Releases: <https://github.com/michaelmjhhhh/TodoFocus/releases>
2. Download latest `TodoFocus-macos-universal.zip`
3. Unzip and move `TodoFocusMac.app` to Applications

### Option 2: Build From Source

```bash
brew install xcodegen
git clone https://github.com/michaelmjhhhh/TodoFocus.git
cd TodoFocus/macos/TodoFocusMac
xcodegen generate
xcodebuild build -project "TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"
```

First launch may require Accessibility permission for global quick capture:
`System Settings -> Privacy & Security -> Accessibility`

## Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| `⌘⇧T` | Quick Capture (global hotkey) |
| `⌘⇧F` | Start Deep Focus on selected task |
| `⌘⇧N` | Add new task |
| `⌘K` | Search tasks |

## Data and Privacy

- Local-first by default
- SQLite database path: `~/Library/Application Support/todofocus/todofocus.db`
- Import/Export supports backup-safe replace and merge workflows

## Project Status

Actively maintained.

If you test it and something feels off, open an issue with:
- what you did
- what you expected
- what actually happened
- your macOS version

Issue tracker: <https://github.com/michaelmjhhhh/TodoFocus/issues>

## Roadmap (Short Term)

- Improve import/export UX and reliability
- Continue hard-focus/deep-focus edge-case hardening
- Polish onboarding and first-run clarity

## Contributing

PRs and issue reports are welcome.

If this project helps your workflow, starring the repo is the easiest way to support it:
<https://github.com/michaelmjhhhh/TodoFocus>

## License

[AGPL-3.0](LICENSE)
