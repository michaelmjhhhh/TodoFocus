# TodoFocus

<p align="center">
  <img src="assets/overdue-screenshot.png" alt="TodoFocus Screenshot" width="980" />
</p>

<p align="center">
  <a href="https://github.com/michaelmjhhhh/TodoFocus/releases"><img src="https://img.shields.io/badge/Download-Latest%20Release-0A84FF?style=for-the-badge" alt="Download Latest Release" /></a>
  <a href="https://github.com/michaelmjhhhh/TodoFocus"><img src="https://img.shields.io/badge/GitHub-Star%20Project-111111?style=for-the-badge" alt="Star Project" /></a>
  <a href="#build-from-source"><img src="https://img.shields.io/badge/Build-From%20Source-2F855A?style=for-the-badge" alt="Build from Source" /></a>
</p>

<p align="center">
  <img src="https://img.shields.io/github/v/release/michaelmjhhhh/TodoFocus?label=latest%20release" alt="Latest Release" />
  <img src="https://img.shields.io/badge/macOS-14%2B-0A84FF" alt="macOS 14+" />
  <img src="https://img.shields.io/badge/SwiftUI-Native-F2994A" alt="SwiftUI" />
  <img src="https://img.shields.io/badge/Data-Local%20SQLite-4F8A3D" alt="Local SQLite" />
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-2D2D2D" alt="License" /></a>
</p>

<p align="center">
  <strong>Turn tasks into execution sessions, not endless lists.</strong>
</p>

<p align="center">
  TodoFocus is a native, local-first macOS app for deep work: capture quickly, attach context, focus deeply, and review work with fewer interruptions.
</p>

## At a Glance

| Area | Current behavior |
|---|---|
| Capture | Global Quick Capture opens with <code>Cmd+Shift+T</code>. Type a thought or use voice. |
| Voice | English-only recognition. Final results are committed on stop, with preview fallback if needed. |
| Focus | Deep Focus and Hard Focus help reduce distraction paths and track session stats. |
| Launch | Attach <code>url</code>, <code>file</code>, and <code>app</code> resources to a task and open them with Launch All. |
| Review | Daily Review uses a lightweight kanban board with Open and Completed lanes. |
| Data | Local SQLite storage, with JSON import/export and URL launch resources as the portable form. |

## Core Features

- Local-first macOS app with no account required
- Smart views for `My Day`, `Important`, `Planned`, `Overdue`, `All Tasks`, and custom lists
- Search with `Cmd+K`
- Launchpad per task for `url`, `file`, and `app` resources
- Deep Focus and Hard Focus for distraction control
- Menu bar Deep Focus panel with lightweight glass styling
- Quick Capture with typed input and voice input
- Resizable task detail panel with persisted width
- Theme support for dark, light, and system appearance
- JSON import/export for local backup and device transfer

## Daily Review

Daily Review is the current cleanup workflow for the whole inbox.

- Open lane is split into `Overdue`, `Today`, `Tomorrow`, `Later`, and `No Date`
- Completed lane is present and collapsed by default
- Each card keeps the existing actions: `Done`, `My Day`, and `Reschedule`
- The board is intentionally lightweight and does not use drag-and-drop yet
- `No Date` tasks are kept separate from `Later` so dated work stays easier to scan

## Quick Capture

- Open it anywhere with `Cmd+Shift+T`
- If Deep Focus is active, captures append to the current focus task notes with a timestamp
- If Deep Focus is not active, captures create a new Inbox task
- Voice mode is English-only (`en-US`)
- Partial speech is preview-only; the best final transcript is committed when recording stops
- After a short silence, recording auto-finalizes

## Launchpad

- Add `url`, `file`, and `app` resources to a task
- Use `Launch All` to open the saved context in one action
- Launch actions use native `NSWorkspace`
- No shell command execution path is used for launch resources
- Unsupported payloads are rejected by validation

## Deep Focus

- Start Deep Focus from task detail or with `Cmd+Shift+F`
- The menu bar panel shows active status, countdown, and current task context
- Session stats track focus time, session count, and distraction attempts
- Hard Focus is available for stronger in-app enforcement
- Ending a session can require a passphrase depending on the active flow

## Quick Start

1. Download the latest release from GitHub, or build from source.
2. Move `TodoFocusMac.app` to `Applications`.
3. Open the app once and grant permissions when macOS asks.
4. Create one task, add one URL in Launchpad, start a Deep Focus session, and test Quick Capture.

If those four steps work, the setup is ready.

## Key Shortcuts

| Shortcut | Action |
|---|---|
| `Cmd+Shift+T` | Global Quick Capture |
| `Cmd+Shift+F` | Start Deep Focus on the selected task |
| `Cmd+K` | Search tasks |
| `Cmd+Shift+N` | Add a new task |
| `Cmd+Shift+L` | Toggle theme |

## Permissions

- Accessibility is required for the global Quick Capture hotkey
- Microphone and Speech Recognition are required for voice capture
- Permissions are tied to the app signature, so you may need to grant them again after rebuilding or re-signing
- Open the relevant page in `System Settings -> Privacy & Security` if macOS does not prompt automatically

## Data and Portability

### Local storage

- Data is stored locally in SQLite
- Database path: `~/Library/Application Support/todofocus/todofocus.db`
- No account or cloud sync is required

### Import and export

- Open `Settings -> General -> Data Import & Export`
- Export and import use JSON
- Portable data includes lists, tasks, steps, and URL launch resources
- File and app launch resources are intentionally skipped for cross-device portability
- Import can merge or replace data and may create a backup before applying changes

Why file and app resources are skipped:

- File paths and app paths are device-local and often invalid on another Mac

## Build From Source

### Requirements

- macOS 14+
- Xcode 16+
- `xcodegen`

### Build and test

```bash
brew install xcodegen
git clone https://github.com/michaelmjhhhh/TodoFocus.git
cd TodoFocus
cd macos/TodoFocusMac
xcodegen generate
xcodebuild test -project "TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"
xcodebuild build -project "TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -configuration Release -derivedDataPath "build/DerivedData" -destination "platform=macOS"
```

## Troubleshooting

### App is blocked by macOS

- Open the app from `Applications` once
- Go to `System Settings -> Privacy & Security`
- Click `Open Anyway` if needed

### Quick Capture hotkey does not trigger

- Re-check Accessibility permission
- Relaunch the app after granting permission
- Re-grant permission if the app was rebuilt or re-signed

### Voice feels inaccurate or slow

- Speak complete phrases and allow a short pause for finalization
- Confirm both Microphone and Speech permissions are granted
- Reduce background noise and use a stable input device

## Demo

<p align="center">
  <img src="assets/demo.gif" alt="TodoFocus Quick Demo" width="980" />
</p>

## Contributor Workflow

For non-trivial changes:

1. Create or update an issue
2. Create a fix or feature branch from `main`
3. Implement focused changes
4. Run verification gates:
   - `xcodebuild test ...`
   - `xcodebuild build ...`
5. Open a PR with the linked issue and verification output

See project rules in [AGENTS.md](AGENTS.md).

## Roadmap Snapshot

- Better onboarding and first-run guidance
- Continued Deep Focus and Hard Focus reliability hardening
- Ongoing import/export and UI polish improvements

## Support and Feedback

If TodoFocus helps your workflow:

1. Star the repo: <https://github.com/michaelmjhhhh/TodoFocus>
2. Share it with one macOS deep-work user
3. Open issues with clear repro steps and environment details

Issue tracker: <https://github.com/michaelmjhhhh/TodoFocus/issues>

## License

[MIT](LICENSE)
