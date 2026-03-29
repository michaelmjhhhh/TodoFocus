# TodoFocus

<p align="center">
  <img src="assets/overdue-screenshot.png" alt="TodoFocus Screenshot" width="980" />
</p>

<p align="center">
  <a href="https://github.com/michaelmjhhhh/TodoFocus/releases"><img src="https://img.shields.io/badge/Download-Latest%20Release-0A84FF?style=for-the-badge" alt="Download Latest Release" /></a>
  <a href="https://github.com/michaelmjhhhh/TodoFocus"><img src="https://img.shields.io/badge/GitHub-Star%20Project-111111?style=for-the-badge" alt="Star Project" /></a>
</p>

<p align="center">
  <img src="https://img.shields.io/github/v/release/michaelmjhhhh/TodoFocus?label=latest%20release" alt="Latest Release" />
  <img src="https://img.shields.io/badge/macOS-14%2B-0A84FF" alt="macOS 14+" />
  <img src="https://img.shields.io/badge/SwiftUI-Native-F2994A" alt="SwiftUI" />
  <img src="https://img.shields.io/badge/Data-Local%20SQLite-4F8A3D" alt="Local SQLite" />
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-2D2D2D" alt="License" /></a>
</p>

<p align="center">
  <strong>Finish meaningful work with less context switching.</strong>
</p>

<p align="center">
  TodoFocus is a local-first macOS task app built for execution: choose one task, launch its context, enter focus mode, and close it.
</p>

## Why It Feels Different

| Focus Faster | Block Distractions | Launch Context Instantly |
|---|---|---|
| Move from list to execution in seconds with My Day, smart filters, and one-click focus start. | Deep Focus and Hard Focus reduce interruption paths when you need protected work blocks. | Attach `url`, `file`, and `app` resources to a task and open everything with `Launch All`. |

## Quick Demo

<p align="center">
  <img src="assets/demo.gif" alt="TodoFocus Quick Demo" width="980" />
</p>

What to look for in this demo:
- One selected task becomes an execution session, not another list item.
- `Launch All` restores work context without tab hunting.
- `⌘⇧T` captures thoughts without breaking flow.

## Before vs After

| Before | After with TodoFocus |
|---|---|
| Task list keeps growing | One task turns into one focused run |
| Context switching drains attention | Work context opens in one action |
| Distractions reset momentum | Focus modes preserve deep-work blocks |

## How It Works

1. Pick what matters with My Day, Smart Lists, and search (`⌘K`).
2. Open context via task resources (`url`, `file`, `app`) and `Launch All`.
3. Start `Deep Focus` (timed or infinite), enable `Hard Focus` when needed.
4. Capture ideas globally with `⌘⇧T`, then keep shipping.

## Built for Local-First Users

- No account required.
- SQLite lives on your machine.
- Import/Export supports backup-safe replace and merge.
- Database path: `~/Library/Application Support/todofocus/todofocus.db`.

## Install

### Fastest Path
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

## First-Run Permission

For global quick capture (`⌘⇧T`), grant Accessibility permission:
`System Settings -> Privacy & Security -> Accessibility`

## Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| `⌘⇧T` | Quick Capture (global) |
| `⌘⇧F` | Start Deep Focus for selected task |
| `⌘⇧N` | Add new task |
| `⌘K` | Search tasks |

## Roadmap Snapshot

- Improve onboarding clarity and first-run guidance.
- Continue Deep Focus / Hard Focus edge-case hardening.
- Keep import/export reliability and UX polished.

## Report Issues

If something is off, open an issue with:
- steps to reproduce
- expected behavior
- actual behavior
- macOS version

Issues: <https://github.com/michaelmjhhhh/TodoFocus/issues>

## Support

If TodoFocus helps your workflow:
1. Star the repo: <https://github.com/michaelmjhhhh/TodoFocus>
2. Share it with one macOS deep-work friend.
3. Open one issue describing your biggest friction point.

## License

[MIT](LICENSE)
