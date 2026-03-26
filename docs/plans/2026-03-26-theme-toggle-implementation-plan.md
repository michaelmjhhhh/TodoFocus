# Dark/Light Theme Toggle Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add light theme alongside existing dark theme, with toggle UI in sidebar footer and Settings, persisted via UserDefaults.

**Architecture:** `ThemeTokens` is an `@Observable` class injected via SwiftUI `@Environment`. All views access `VisualTokens` via `environment(\.themeTokens)` which resolves colors based on current theme. `ThemeStore` (existing) manages persistence and provides `ColorScheme?` to window.

**Tech Stack:** SwiftUI `@Environment`, `@Observable`, SwiftUI `ColorScheme`

---

## Key Design Decision

Since `VisualTokens` uses **static properties** (188 references across 11 files), and Swift's static properties cannot access `@Environment`, we introduce `ThemeTokens` — an `@Observable` class provided via `@Environment(\.themeTokens)`.

**Pattern in all views:**
```swift
// OLD
Text("Hello").foregroundStyle(VisualTokens.textPrimary)

// NEW
@Environment(\.themeTokens) private var tokens
Text("Hello").foregroundStyle(tokens.textPrimary)
```

The `@Observable` `ThemeTokens` class is initialized with a `Theme` (from `ThemeStore`) and computes all color values dynamically.

---

## Task 1: Create `ThemeEnvironment.swift`

**Files:**
- Create: `macos/TodoFocusMac/Sources/Features/Common/ThemeEnvironment.swift`

Defines the `@Environment` key for theme mode and the `Theme` type alias (aliased from `ThemeStore.Theme`).

```swift
import SwiftUI

// Expose ThemeStore.Theme through environment
private struct ThemeModeKey: EnvironmentKey {
    static let defaultValue: ThemeStore.Theme = .dark
}

extension EnvironmentValues {
    var themeMode: ThemeStore.Theme {
        get { self[ThemeModeKey.self] }
        set { self[ThemeModeKey.self] = newValue }
    }
}

extension View {
    func themeMode(_ theme: ThemeStore.Theme) -> some View {
        environment(\.themeMode, theme)
    }
}
```

**Step 1: Create the file**

```swift
import SwiftUI

// Expose ThemeStore.Theme through environment
private struct ThemeModeKey: EnvironmentKey {
    static let defaultValue: ThemeStore.Theme = .dark
}

extension EnvironmentValues {
    var themeMode: ThemeStore.Theme {
        get { self[ThemeModeKey.self] }
        set { self[ThemeModeKey.self] = newValue }
    }
}

extension View {
    func themeMode(_ theme: ThemeStore.Theme) -> some View {
        environment(\.themeMode, theme)
    }
}
```

**Step 2: Commit**

```bash
git add macos/TodoFocusMac/Sources/Features/Common/ThemeEnvironment.swift
git commit -m "feat(theme): add ThemeEnvironment with @Environment key for theme mode"
```

---

## Task 2: Create `ThemeTokens.swift`

**Files:**
- Create: `macos/TodoFocusMac/Sources/Features/Common/ThemeTokens.swift`

`ThemeTokens` is an `@Observable` class that computes all color values based on the current theme. Views get it via `@Environment(\.themeTokens)`.

```swift
import SwiftUI
import Observation

@Observable
final class ThemeTokens {
    let theme: ThemeStore.Theme

    init(theme: ThemeStore.Theme = .dark) {
        self.theme = theme
    }

    // MARK: - Backgrounds
    var bgBase: Color {
        theme == .light ? Color(red: 0.961, green: 0.953, blue: 0.933) : Color(red: 0.039, green: 0.039, blue: 0.039)
    }
    var bgElevated: Color {
        theme == .light ? Color.white : Color(red: 0.11, green: 0.11, blue: 0.11)
    }
    var bgFloating: Color {
        theme == .light ? Color(red: 0.980, green: 0.980, blue: 0.980) : Color(red: 0.15, green: 0.15, blue: 0.15)
    }

    // MARK: - Text
    var textPrimary: Color {
        theme == .light ? Color(red: 0.102, green: 0.102, blue: 0.102) : Color(red: 0.98, green: 0.98, blue: 0.98)
    }
    var textSecondary: Color {
        theme == .light ? Color(red: 0.420, green: 0.420, blue: 0.420) : Color(red: 0.55, green: 0.55, blue: 0.55)
    }
    var textTertiary: Color {
        theme == .light ? Color(red: 0.608, green: 0.608, blue: 0.608) : Color(red: 0.40, green: 0.40, blue: 0.40)
    }

    // MARK: - Semantic
    var success: Color {
        theme == .light ? Color(red: 0.063, green: 0.725, blue: 0.506) : Color(red: 0.37, green: 0.81, blue: 0.61)
    }
    var warning: Color {
        theme == .light ? Color(red: 0.961, green: 0.620, blue: 0.043) : Color(red: 0.97, green: 0.73, blue: 0.31)
    }
    var danger: Color {
        theme == .light ? Color(red: 0.937, green: 0.267, blue: 0.267) : Color(red: 0.94, green: 0.41, blue: 0.47)
    }

    // MARK: - Accents
    var accentBlue: Color {
        theme == .light ? Color(red: 0.231, green: 0.510, blue: 0.965) : Color(red: 0.40, green: 0.71, blue: 0.96)
    }
    var accentViolet: Color {
        theme == .light ? Color(red: 0.545, green: 0.361, blue: 0.965) : Color(red: 0.60, green: 0.53, blue: 0.95)
    }
    var accentAmber: Color {
        theme == .light ? Color(red: 0.961, green: 0.620, blue: 0.043) : Color(red: 0.95, green: 0.64, blue: 0.29)
    }
    var accentTerracotta: Color {
        theme == .light ? Color(red: 0.918, green: 0.345, blue: 0.047) : Color(red: 0.769, green: 0.408, blue: 0.286)
    }

    // MARK: - Gradients
    var appBackground: LinearGradient {
        if theme == .light {
            return LinearGradient(
                colors: [
                    Color(red: 0.961, green: 0.953, blue: 0.933),
                    Color(red: 0.961, green: 0.953, blue: 0.933),
                    Color(red: 0.95, green: 0.94, blue: 0.93)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            return LinearGradient(
                colors: [
                    Color(red: 0.039, green: 0.039, blue: 0.039),
                    Color(red: 0.039, green: 0.039, blue: 0.039),
                    Color(red: 0.05, green: 0.05, blue: 0.05)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    var accent: LinearGradient {
        LinearGradient(
            colors: [accentAmber, accentViolet],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    // MARK: - Aliases
    var panelBackground: Color { bgElevated }
    var sectionBackground: Color { bgElevated }
    var sectionBorder: Color {
        theme == .light ? Color.black.opacity(0.08) : Color.white.opacity(0.06)
    }
    var mutedText: Color { textSecondary }
    var violetAccent: Color { accentViolet }
    var cyanAccent: Color { accentBlue }
    var roseAccent: Color { danger }
}
```

---

## Task 3: Update `VisualTokens.swift` for backward compatibility

**Files:**
- Modify: `macos/TodoFocusMac/Sources/Features/Common/VisualTokens.swift`

Add an extension that provides a static `current(theme:)` method returning a `ThemeTokens` instance for places where `@Environment` is not available (tests, preview providers).

```swift
extension VisualTokens {
    /// Returns ThemeTokens for a given theme (for test/preview use)
    static func current(for theme: ThemeStore.Theme = .dark) -> ThemeTokens {
        ThemeTokens(theme: theme)
    }
}
```

---

## Task 4: Update `TodoFocusMacApp.swift` to inject `ThemeTokens`

**Files:**
- Modify: `macos/TodoFocusMac/Sources/TodoFocusMacApp.swift:1-70`

Add `ThemeTokens` environment injection and pass `themeStore` to `RootView`.

Changes:
- Pass `themeStore` to `RootView` so it can inject the environment
- In `RootView`, add `@Environment(\.themeTokens)` and set up the chain

Actually, since `RootView` is where the main content is rendered, we need to inject `ThemeTokens` there. But `TodoFocusMacApp` owns `ThemeStore`. The cleanest approach:

**In `TodoFocusMacApp.swift`:**
- Create a `@State private var themeTokens = ThemeTokens(theme: themeStore.theme)`
- Pass `themeStore` to `RootView`
- In `RootView`, observe `themeStore.theme` and create `ThemeTokens` from it

```swift
// In TodoFocusMacApp — modify the State and WindowGroup:

@State private var themeTokens = ThemeTokens(theme: ThemeStore().theme)  // updated after init

// Update RootView call to pass themeStore:
RootView(
    appModel: appModel,
    store: store,
    launchpadService: launchpadService,
    databasePath: databaseManager?.path ?? "",
    themeStore: themeStore  // ADD
)
.theme(\.themeTokens, themeTokens)  // ADD
```

**In `RootView.swift`:**
- Accept `themeStore: ThemeStore` as a parameter
- Create `ThemeTokens` from `themeStore.theme` and keep it updated with `onChange`

```swift
// Add to RootView:
let themeStore: ThemeStore
@State private var themeTokens: ThemeTokens

// In onAppear:
themeTokens = ThemeTokens(theme: themeStore.theme)

// onChange of themeStore.theme:
.onChange(of: themeStore.theme) { _, newTheme in
    themeTokens = ThemeTokens(theme: newTheme)
}
```

---

## Task 5: Update all views to use `@Environment(\.themeTokens)`

**Files to modify (188 references across 11 files):**
- `macos/TodoFocusMac/Sources/RootView.swift` — Inject into child views via `.environment(\.themeTokens, themeTokens)`
- `macos/TodoFocusMac/Sources/Features/Common/ImmersiveHeaderView.swift` — Add `@Environment(\.themeTokens)` and replace all `VisualTokens.*` with `tokens.*`
- `macos/TodoFocusMac/Sources/Features/Common/ShortcutHintBar.swift` — Same pattern
- `macos/TodoFocusMac/Sources/Features/Common/DeepFocusReportView.swift` — Same pattern
- `macos/TodoFocusMac/Sources/Features/Common/InteractiveStyles.swift` — Same pattern
- `macos/TodoFocusMac/Sources/Features/TaskList/TodoRowView.swift` — Same pattern
- `macos/TodoFocusMac/Sources/Features/TaskList/TaskListView.swift` — Same pattern
- `macos/TodoFocusMac/Sources/Features/TaskDetail/LaunchResourceEditorView.swift` — Same pattern
- `macos/TodoFocusMac/Sources/Features/TaskDetail/TaskDetailView.swift` — Same pattern
- `macos/TodoFocusMac/Sources/Features/Sidebar/SidebarView.swift` — Same pattern

**Pattern for each view:**
```swift
// Add property:
@Environment(\.themeTokens) private var tokens

// Replace all occurrences:
// VisualTokens.textPrimary → tokens.textPrimary
// VisualTokens.bgElevated → tokens.bgElevated
// etc.
```

**RootView special case**: Since `RootView` holds `themeTokens` state and passes environment down, all child views automatically receive it. `RootView` itself replaces `VisualTokens.*` with `themeTokens.*`.

**Important**: Also add `.themeMode(themeStore.theme)` to `RootView` in `TodoFocusMacApp` so the environment key is set correctly.

---

## Task 6: Add theme toggle to sidebar footer

**Files:**
- Modify: `macos/TodoFocusMac/Sources/Features/Sidebar/SidebarView.swift:1-382`

Add a theme toggle button at the bottom of `SidebarView`. The button cycles through: dark → light → system.

```swift
// In SidebarView, add:
@Environment(\.themeTokens) private var tokens

// At bottom of List (after the lists Section):
// Add a footer section or use a safe area button
Button {
    cycleTheme()
} label: {
    Image(systemName: themeIcon)
        .font(.system(size: 14))
        .foregroundStyle(tokens.textSecondary)
}
.buttonStyle(.plain)
.tooltip(themeTooltip)
```

The `cycleTheme()` function needs access to `ThemeStore`. Since `SidebarView` receives `store: TodoAppStore` and `appModel: AppModel` (which does NOT have theme), we need to also pass `themeStore: ThemeStore` to `SidebarView`.

**Add to `SidebarView` init parameters:**
```swift
let themeStore: ThemeStore
```

**Update `cycleTheme()`:**
```swift
private func cycleTheme() {
    withAnimation(.easeInOut(duration: 0.2)) {
        switch themeStore.theme {
        case .dark:
            themeStore.theme = .light
        case .light:
            themeStore.theme = .system
        case .system:
            themeStore.theme = .dark
        }
    }
}

private var themeIcon: String {
    switch themeStore.theme {
    case .dark: return "moon.fill"
    case .light: return "sun.max.fill"
    case .system: return "circle.lefthalf.filled"
    }
}

private var themeTooltip: String {
    switch themeStore.theme {
    case .dark: return "Dark mode"
    case .light: return "Light mode"
    case .system: return "System mode"
    }
}
```

Also update the `RootView` call to `SidebarView`:
```swift
SidebarView(appModel: appModel, store: store, lists: store.lists, themeStore: themeStore)
```

---

## Task 7: Add Appearance section to Settings

**Files:**
- Modify: `macos/TodoFocusMac/Sources/Features/Settings/SettingsView.swift:92-151`

Add `Appearance` section to `GeneralSettingsView` with a theme store binding.

Since `GeneralSettingsView` is created by `SettingsView` which is created by `TodoFocusMacApp`, we need to thread `ThemeStore` through.

**Add to `SettingsView`:**
```swift
struct SettingsView: View {
    let databasePath: String
    let themeStore: ThemeStore  // ADD
    ...
    GeneralSettingsView(..., themeStore: themeStore)  // PASS
}
```

**Update `GeneralSettingsView`:**
```swift
struct GeneralSettingsView: View {
    ...
    let themeStore: ThemeStore  // ADD

    var body: some View {
        Form {
            Section("Appearance") {
                Picker("Theme", selection: $themeStore.theme) {
                    Text("Dark").tag(ThemeStore.Theme.dark)
                    Text("Light").tag(ThemeStore.Theme.light)
                    Text("System").tag(ThemeStore.Theme.system)
                }
                .pickerStyle(.segmented)
            }

            Section("Data Management") {
                ...
            }
        }
    }
}
```

**Update `TodoFocusMacApp.Settings`:**
```swift
Settings {
    SettingsView(databasePath: databaseManager?.path ?? "", themeStore: themeStore)
}
```

---

## Task 8: Update `InteractiveStyles.swift`

**Files:**
- Modify: `macos/TodoFocusMac/Sources/Features/Common/InteractiveStyles.swift`

This file likely references `VisualTokens` for button/input styles. Add `@Environment(\.themeTokens)` and update references.

---

## Task 9: Build and verify

Run:
```bash
xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"
```

Expected: BUILD SUCCEEDED

---

## Task 10: Commit

```bash
git add .
git commit -m "feat(theme): add light/dark theme toggle with persistence

- Add ThemeEnvironment with @Environment key for theme mode
- Add ThemeTokens @Observable class with theme-aware color properties
- Update all 11 view files to use @Environment(\.themeTokens)
- Add theme toggle cycling button to sidebar footer
- Add Appearance section to Settings with segmented picker
- Theme persists via UserDefaults, dark by default

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Summary of File Changes

**Created:**
- `macos/TodoFocusMac/Sources/Features/Common/ThemeEnvironment.swift`
- `macos/TodoFocusMac/Sources/Features/Common/ThemeTokens.swift`

**Modified (8 files, 188 VisualTokens references):**
- `macos/TodoFocusMac/Sources/TodoFocusMacApp.swift`
- `macos/TodoFocusMac/Sources/RootView.swift`
- `macos/TodoFocusMac/Sources/Features/Common/VisualTokens.swift`
- `macos/TodoFocusMac/Sources/Features/Sidebar/SidebarView.swift`
- `macos/TodoFocusMac/Sources/Features/Settings/SettingsView.swift`
- `macos/TodoFocusMac/Sources/Features/TaskList/TodoRowView.swift`
- `macos/TodoFocusMac/Sources/Features/TaskList/TaskListView.swift`
- `macos/TodoFocusMac/Sources/Features/TaskDetail/TaskDetailView.swift`
- `macos/TodoFocusMac/Sources/Features/TaskDetail/LaunchResourceEditorView.swift`
- `macos/TodoFocusMac/Sources/Features/Common/ImmersiveHeaderView.swift`
- `macos/TodoFocusMac/Sources/Features/Common/ShortcutHintBar.swift`
- `macos/TodoFocusMac/Sources/Features/Common/DeepFocusReportView.swift`
- `macos/TodoFocusMac/Sources/Features/Common/InteractiveStyles.swift`
