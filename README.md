# TodoFocus

<p align="center">
  <img src="https://via.placeholder.com/800x500/1C1C1E/C46849?text=TodoFocus" alt="TodoFocus" width="800"/>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-14%2B-blue" alt="macOS 14+"/>
  <img src="https://img.shields.io/badge/SwiftUI-orange" alt="SwiftUI"/>
  <img src="https://img.shields.io/badge/Database-SQLite-yellow" alt="SQLite"/>
  <img src="https://img.shields.io/badge/License-AGPL--3.0-green" alt="AGPL-3.0"/>
</p>

---

Local-first native macOS todo app for **focused execution**, not just list keeping.

---

## Why TodoFocus

| | |
|---|---|
| 💾 **Local-First** | Data lives on your machine in SQLite. No account, no cloud, no sync friction. |
| ⚡ **Launch Everything** | Attach URLs, files, and apps to any task. Click **Launch All** to open your entire context at once. |
| 🎯 **Smart Filters** | See exactly what matters today. Filter by Overdue, Today, Tomorrow, Next 7 days, or No date. |
| 🔥 **Deep Focus** | Track focus time, block distracting apps, and set a timer to auto-end sessions. |
| ⌨️ **Quick Capture** | Press **⌘⇧T** from anywhere to capture thoughts instantly. |

---

## Quick Start

```bash
# Download latest release
# → https://github.com/michaelmjhhhh/TodoFocus/releases

# Or build from source
brew install xcodegen
git clone https://github.com/michaelmjhhhh/TodoFocus.git
cd TodoFocus/macos/TodoFocusMac
xcodegen generate
xcodebuild build -project "TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"
```

**First launch:** Grant **Accessibility permission** when prompted (System Settings → Privacy & Security → Accessibility).

---

## Features

### 📋 Task Management
| | |
|---|---|
| **Smart Lists** | My Day, Important, Planned — filter automatically |
| **Custom Lists** | Create lists with 10 color options |
| **Subtasks** | Break tasks into smaller pieces |
| **Due Dates** | Relative display — "Today", "Tomorrow", "Overdue" |
| **Notes** | Per-task free-text notes with auto-save |
| **Search** | Press **⌘K** to search across all tasks |

### 🎯 Focus
| | |
|---|---|
| **Deep Focus Sessions** | Start a focus session on any task; tracks time and blocks distracting apps |
| **Deep Focus Timer** | Set custom duration (25/45/60/90 min or custom) or Infinite mode. Timer auto-ends session, shows notification, marks task complete |

### 🚀 Productivity
| | |
|---|---|
| **Context Launchpad** | Attach URLs, files, and apps to a task; launch all in one click |
| **Quick Capture** | Press **⌘⇧T** from any app to capture thoughts |
| **Collapsible Completed** | Hide completed tasks to focus on active work |

### 🎨 Customization
| | |
|---|---|
| **Dark / Light Theme** | Toggle with persistence; dark by default |
| **Resizable Panel** | Drag to adjust detail panel width |

---

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| <kbd>⌘</kbd><kbd>⇧</kbd><kbd>T</kbd> | Quick Capture (global hotkey) |
| <kbd>⌘</kbd><kbd>⇧</kbd><kbd>F</kbd> | Start Deep Focus on selected task |
| <kbd>⌘</kbd><kbd>⇧</kbd><kbd>N</kbd> | Add new task to current view |
| <kbd>⌘</kbd><kbd>K</kbd> | Search tasks |
| <kbd>⌘</kbd><kbd>W</kbd> | Close current window |
| <kbd>⌘</kbd><kbd>Q</kbd> | Quit app |

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| UI Framework | SwiftUI |
| State Management | Observation (`@Observable`) |
| Database | SQLite via GRDB |
| Build System | Xcode + xcodegen |
| Packaging | Zipped `.app` in GitHub Releases |

### Project Structure

```
macos/TodoFocusMac/
├── Sources/
│   ├── App/           # AppModel, TodoAppStore, DeepFocusService
│   ├── Core/          # Domain models (Todo, List, Step)
│   ├── Data/          # GRDB migrations, DTOs, repositories
│   └── Features/      # SwiftUI views
└── Tests/
```

### Building

```bash
# Generate project after file changes
xcodegen generate

# Build
xcodebuild build -project "TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"

# Test
xcodebuild test -project "TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"
```

### Releasing

```bash
git tag vX.Y.Z
git push origin vX.Y.Z
gh workflow run release-macos-native -f tag=vX.Y.Z
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Build fails after renaming files | Run `xcodegen generate` |
| Data looks stale | Delete `~/Library/Application Support/todofocus/todofocus.db` |
| Global hotkey doesn't work | Grant **Accessibility permission** in System Settings |
| App launch fails | Grant **Full Disk Access** or relevant permissions |

---

## Contributing

Issues and pull requests welcome.

---

## License

[AGPL-3.0](LICENSE) — See [LICENSE](LICENSE) for details.
