# TodoFocus

<p align="center">
  <img src="assets/overdue-screenshot.png" alt="TodoFocus Screenshot" width="980" />
</p>

<p align="center">
  <a href="https://github.com/michaelmjhhhh/TodoFocus/releases"><img src="https://img.shields.io/github/v/release/michaelmjhhhh/TodoFocus?label=latest%20release" alt="Latest Release" /></a>
  <img src="https://img.shields.io/badge/macOS-14%2B-0A84FF" alt="macOS 14+" />
  <img src="https://img.shields.io/badge/SwiftUI-Native-F2994A" alt="SwiftUI" />
  <img src="https://img.shields.io/badge/Data-Local%20SQLite-4F8A3D" alt="Local SQLite" />
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-AGPL--3.0-2D2D2D" alt="License" /></a>
</p>

<p align="center">
  <strong>From "I should do this" to "done" with fewer distractions.</strong>
</p>

<p align="center">
  Pick a task. Launch your context. Enter focus mode. Finish.
</p>

## The Story

You sit down to work on one task.
Five minutes later, your browser has 14 tabs, Slack popped up twice, and the original task is still untouched.

TodoFocus exists to close that gap between intention and execution.

## Before vs After

| Before | After with TodoFocus |
|---|---|
| Task list grows, execution stalls | Select one task and start a focus run |
| Context switching burns energy | `Launch All` opens task resources in one shot |
| Distractions break momentum | Deep/Hard Focus reduces interruption paths |
| Ideas get lost mid-session | `⌘⇧T` captures thoughts instantly |

## How It Works

### 1. Pick What Matters
- Use My Day, smart filters, and search (`⌘K`) to choose the next task

### 2. Restore Context Fast
- Attach `url`, `file`, and `app` resources to each task
- Hit `Launch All` to set up your workspace in seconds

### 3. Lock In
- Start `Deep Focus` (timed or infinite)
- Enable `Hard Focus` when you need stricter blocking

### 4. Keep Flow
- Use global quick capture (`⌘⇧T`) without leaving your current app
- Session stats track focus time and progress

## Feature Highlights

### Focus Engine
- `Deep Focus`: timer or infinite session mode
- `Hard Focus`: stronger anti-distraction mode
- Session completion and focus stats tracking

### Task System
- Smart views: overdue, today, tomorrow, next 7 days, no date
- Custom lists with color indicators
- Notes and subtasks support

### Local-First by Design
- No account required
- SQLite database on your machine
- Import/Export with backup-safe replace and merge

## Install

### Fastest Path (Recommended)
1. Open Releases: <https://github.com/michaelmjhhhh/TodoFocus/releases>
2. Download `TodoFocus-macos-universal.zip`
3. Move `TodoFocusMac.app` to `Applications`

### Build From Source

```bash
brew install xcodegen
git clone https://github.com/michaelmjhhhh/TodoFocus.git
cd TodoFocus/macos/TodoFocusMac
xcodegen generate
xcodebuild build -project "TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"
```

## First-Run Permissions

Quick Capture uses a global shortcut, so macOS requires Accessibility permission:
`System Settings -> Privacy & Security -> Accessibility`

## Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| `⌘⇧T` | Quick Capture (global) |
| `⌘⇧F` | Start Deep Focus |
| `⌘⇧N` | Add new task |
| `⌘K` | Search tasks |

## Builder Log

A transparent solo-builder timeline:
- `2026-03-28`: import/export upgrade with preflight, merge mode, and safer replace path
- `2026-03-28`: hard-focus/deep-focus sync fixes and release flow hardening
- `Ongoing`: docs cleanup, onboarding clarity, and edge-case stability fixes

## Project Status

Actively maintained.

If something breaks, open an issue with:
- steps to reproduce
- expected behavior
- actual behavior
- macOS version

Issues: <https://github.com/michaelmjhhhh/TodoFocus/issues>

## If You Want To Support This Project

1. Star the repo: <https://github.com/michaelmjhhhh/TodoFocus>
2. Share it with one friend who uses macOS for deep work
3. Report one friction point from your daily workflow

## License

[AGPL-3.0](LICENSE)
