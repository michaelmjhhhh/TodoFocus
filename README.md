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
  TodoFocus is a native, local-first macOS app for deep work: capture quickly, launch context instantly, and finish meaningful tasks with fewer interruptions.
</p>

## Why TodoFocus

| Capture Fast | Focus Deep | Launch Context |
|---|---|---|
| Use Quick Add and global Quick Capture (`⌘⇧T`) to save thoughts without breaking flow. | Start Deep Focus or Hard Focus to reduce distraction paths while you execute. | Attach `url`, `file`, and `app` resources to each task and open all with one action. |

### Before vs After

| Before | With TodoFocus |
|---|---|
| Tasks pile up and stay abstract | One task becomes one focused execution block |
| Constant tab/app switching | Context opens in one click via Launchpad |
| Notes and ideas get lost | Quick Capture routes ideas back into your workflow |

## Quick Start (3 Minutes)

### 1. Install
1. Open releases: <https://github.com/michaelmjhhhh/TodoFocus/releases>
2. Download `TodoFocus-macos-universal.zip`
3. Move `TodoFocusMac.app` to `Applications`

### 2. Launch Once
1. Open `TodoFocusMac.app`
2. If macOS warns, open `System Settings -> Privacy & Security`
3. Click `Open Anyway`

### 3. Enable Permissions (for full experience)
- Accessibility: required for global Quick Capture hotkey (`⌘⇧T`)
- Microphone + Speech Recognition: required for voice capture in Quick Capture

Paths:
- `System Settings -> Privacy & Security -> Accessibility`
- `System Settings -> Privacy & Security -> Microphone`
- `System Settings -> Privacy & Security -> Speech Recognition`

### 4. Verify First Success
- Create one task
- Add one URL in Launchpad
- Click `Launch All`
- Start a Deep Focus session

If these work, your setup is complete.

## Core Workflows

### Workflow A: Plan -> Launch -> Focus
1. Select a task in `My Day` / `All Tasks` / custom list.
2. Open task detail and add Launchpad resources.
3. Click `Launch All` to open your work context.
4. Start `Deep Focus` (optionally with timer).
5. Finish, then close the loop in one place.

### Workflow B: Quick Capture (Typing + Voice)
1. Press `⌘⇧T` from anywhere.
2. Type a thought or use voice capture.
3. Voice behavior:
- English is primary (`en-US`)
- Chinese is fallback (`zh-CN`)
- Final transcript is prioritized for commit
- Partial transcript is preview-only
4. After short silence, voice capture auto-finalizes.

### Workflow C: Import / Export Safely
1. Open Settings -> Data.
2. Export data snapshot.
3. Import with merge/replace mode based on your goal.
4. Portability note: only URL launch resources are imported/exported across devices.

## Feature Highlights

- Smart views: `My Day`, `Important`, `Planned`, `Overdue`, `All Tasks`
- Search with `⌘K`
- Deep Focus and Hard Focus for distraction control
- Launchpad per task with `url`, `file`, `app`
- Global Quick Capture (`⌘⇧T`)
- Voice capture with bilingual recognition strategy
- Resizable task detail panel
- Polished filter bar, sidebar alignment, and Launchpad editor UI
- Theme support: dark / light / system (dark by default)

## Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| `⌘⇧T` | Global Quick Capture |
| `⌘⇧F` | Start Deep Focus on selected task |
| `⌘⇧N` | Add new task |
| `⌘K` | Search tasks by title and notes |

## Data, Privacy, and Portability

### Local-First Storage
- No account required
- Data is stored locally in SQLite
- Database path: `~/Library/Application Support/todofocus/todofocus.db`

### Import / Export Scope
- Included: lists, tasks, steps, settings, URL launch resources
- Excluded from cross-device import/export: file/app launch resources

Why excluded:
- File paths and app paths are device-local and often invalid on another machine.

### Security Guardrails
- Launch resources are opened through native `NSWorkspace`
- No shell command execution path is used for Launchpad actions
- Unsupported payloads are rejected by validation

## Build From Source

### Requirements
- macOS 14+
- Xcode 16+
- `xcodegen`

### Build and Test
```bash
brew install xcodegen
git clone https://github.com/michaelmjhhhh/TodoFocus.git
cd TodoFocus/macos/TodoFocusMac
xcodegen generate
xcodebuild test -project "TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"
xcodebuild build -project "TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"
```

## Contributor Workflow

For non-trivial changes, follow:
1. Create/update issue
2. Create fix/feat branch from `main`
3. Implement focused changes
4. Run verification gates:
- `xcodebuild test ...`
- `xcodebuild build ...`
5. Open PR with linked issue and verification output

See project rules in [AGENTS.md](AGENTS.md).

## Troubleshooting

### App Is Blocked by macOS
- Open from `Applications` once
- Go to `System Settings -> Privacy & Security`
- Click `Open Anyway`
- If needed, right-click app -> `Open`

### Quick Capture Hotkey Does Not Trigger
- Re-check Accessibility permission
- Relaunch app after granting permission
- If app signature changed after rebuild, grant again

### Voice Input Feels Inaccurate or Slow
- Speak complete phrases and allow a short pause for finalization
- Confirm both Microphone and Speech permissions are granted
- Use a stable input device and reduce background noise

## Demo

<p align="center">
  <img src="assets/demo.gif" alt="TodoFocus Quick Demo" width="980" />
</p>

## Roadmap Snapshot

- Better onboarding and first-run guidance
- Continued Deep Focus / Hard Focus reliability hardening
- Ongoing import/export and UI polish improvements

## Support and Feedback

If TodoFocus helps your workflow:
1. Star the repo: <https://github.com/michaelmjhhhh/TodoFocus>
2. Share it with one macOS deep-work user
3. Open issues with clear repro steps and environment details

Issue tracker: <https://github.com/michaelmjhhhh/TodoFocus/issues>

## License

[MIT](LICENSE)
