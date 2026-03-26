# TodoFocus

Local-first native macOS todo app for focused execution, not just list keeping.

## Why TodoFocus

- **Local-first by default** — Data lives on your machine in SQLite. No account, no cloud, no sync friction.
- **Start work instantly** — Attach URLs, files, and apps to any task. Click **Launch All** to open your entire work context at once.
- **Focus filters** — See exactly what matters today. Filter any view by Overdue, Today, Tomorrow, Next 7 days, or No date.
- **Deep Focus sessions** — Track cumulative focus time and block distracting apps while you work.

---

## Getting Started

### Install

Download the latest release from the [GitHub Releases page](https://github.com/michaelmjhhhh/TodoFocus/releases). Unzip and move `TodoFocusMac.app` to your Applications folder.

### Build from source

```bash
git clone https://github.com/michaelmjhhhh/TodoFocus.git
cd TodoFocus/macos/TodoFocusMac
brew install xcodegen
xcodegen generate
xcodebuild build -project "TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"
```

### First launch

On first launch, the app will prompt for **Accessibility permission** to enable the global hotkey (⌘⇧T) for Quick Capture. Go to **System Settings > Privacy & Security > Accessibility** and enable TodoFocus.

---

## Features

| Feature | Description |
|---------|-------------|
| **Smart lists** | My Day, Important, Planned — filter automatically |
| **Per-view time filters** | Overdue / Today / Tomorrow / Next 7 days / No date |
| **Custom lists with colors** | Create lists with 10 color options; color appears as a left indicator on tasks |
| **Context Launchpad Tasks** | Attach URL, File, and App resources to a task; launch all in one click |
| **Subtasks (Steps)** | Break tasks into smaller pieces |
| **Due dates** | Relative display — "Today", "Tomorrow", "Overdue" |
| **Notes** | Per-task free-text notes with auto-save |
| **Deep Focus** | Start a focus session on any task; tracks time and blocks distracting apps |
| **Quick Capture (⌘⇧T)** | Global hotkey captures thoughts from anywhere; appends to Deep Focus task notes or creates an Inbox task |
| **Search (⌘K)** | Local search across task titles and notes |
| **Dark / Light theme** | Toggle with persistence; dark by default |
| **Collapsible completed** | Hide completed tasks to focus on active work |
| **Resizable detail panel** | Drag to widen or narrow the right panel |

---

## How to Use

### Create a task

1. Select a list in the sidebar (or use **Inbox**).
2. Press **⌘⇧N** or click the **+** button.
3. Type your task title and press Enter.

### Set a due date

1. Select a task.
2. In the detail panel, click the **date field**.
3. Choose a date from the picker, or type "today", "tomorrow", or a date.

### Attach resources (URL, file, app)

1. Select a task.
2. In the detail panel, click **Add URL**, **Add File**, or **Add App**.
3. Use the native picker to select your resource.
4. Click **Launch All** to open everything at once.

### Start a Deep Focus session

1. Select a task.
2. Press **⌘⇧F** or click **Start Focus** in the detail panel.
3. The session timer begins. If you have blocklist apps configured, the app will enforce focus by closing them if opened.

### Filter tasks by time

- Click the **time filter bar** at the top of the task list.
- Choose **Overdue**, **Today**, **Tomorrow**, **Next 7 days**, or **No date**.
- The filter applies to the current view.

### Search tasks

1. Press **⌘K**.
2. Type your search query.
3. Results show matching tasks from all lists.

### Quick Capture

1. Press **⌘⇧T** from any application.
2. Type your thought and press Enter.
3. If a Deep Focus session is active, the note is appended to that task. Otherwise, a new Inbox task is created.

---

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| ⌘⇧T | Quick Capture (global hotkey) |
| ⌘⇧F | Start Deep Focus on selected task |
| ⌘⇧N | Add new task to current view |
| ⌘K | Search tasks |
| ⌘W | Close current window |
| ⌘Q | Quit app |

---

## For Developers

### Tech Stack

| Layer | Technology |
|-------|------------|
| App Framework | SwiftUI |
| State Management | Observation (`@Observable`) |
| Database | SQLite via GRDB |
| Build | Xcode + xcodegen |
| Packaging | Zipped `.app` in GitHub Releases |

### Requirements

- **Xcode** 16+
- **macOS** 14+
- **xcodegen**

### Project Structure

```
macos/TodoFocusMac/
  Sources/
    App/           # AppModel, TodoAppStore, DeepFocusService, LaunchpadService, QuickCaptureService
    Core/          # Domain models (Todo, List, Step, LaunchResource) and filters
    Data/          # GRDB migrations, DTOs (Record types), and repositories
    Features/      # SwiftUI views organized by feature (Sidebar, TaskList, TaskDetail, Common, QuickCapture)
  Tests/
    CoreTests/     # Domain and behavior tests
    DataTests/     # Migration and repository tests
```

### Build & Test

```bash
# Generate Xcode project (after adding/removing/renaming files)
xcodegen generate

# Build
xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"

# Test
xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"

# Run a single test file
xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS" -only-testing:CoreTests/TodoAppStoreTests
```

### Architecture

**State Management:**
- `@Observable @MainActor TodoAppStore` is the central state holder — owns lists and todos, coordinates CRUD via repositories, and computes visible todos through `AppModel.query()`.
- `AppModel` holds UI state: selected sidebar item, selected todo ID, time filter, sort order, theme, and window size.

**Data Flow:**
```
GRDB Records (TodoRecord, ListRecord, StepRecord)
    ↓ Record extensions map to domain models (Todo, TodoList, TodoStep)
    ↓ Repositories fetch and store records
    ↓ TodoAppStore orchestrates and exposes state to views
    ↓ SwiftUI Views observe TodoAppStore
```

**Key Patterns:**
- Views only handle UI; `TodoAppStore` handles business logic; repositories handle persistence.
- Notes auto-save with 0.5s debounce via `DispatchWorkItem`.
- Launch resources are validated via `LaunchResourceValidation` before persistence and launched via `NSWorkspace` only (no shell execution).
- GRDB migrations run automatically on first launch via `DatabaseManager.makeMigrator()`.

### Releasing

Releases use the `release-macos-native` GitHub Actions workflow, triggered by version tags:

```bash
git checkout main && git pull
git tag vX.Y.Z
git push origin vX.Y.Z
gh workflow run release-macos-native -f tag=vX.Y.Z
```

---

## Troubleshooting

**Build fails after renaming files.**
Run `xcodegen generate` and rebuild.

**App data looks stale or corrupted.**
Delete `~/Library/Application Support/todofocus/todofocus.db` for a clean local reset. The database is rebuilt on next launch.

**Global hotkey (⌘⇧T) doesn't work.**
Verify that TodoFocus has **Accessibility permission** in **System Settings > Privacy & Security > Accessibility**.

**File or app launch fails.**
Check that TodoFocus has **Full Disk Access** or the relevant file access permissions in **System Settings > Privacy & Security**.

**Picker dialogs don't open.**
Verify macOS file and app permissions for TodoFocus.

---

## Contributing

Issues and pull requests are welcome. Please read the existing code and tests before submitting PRs.

## License

MIT
