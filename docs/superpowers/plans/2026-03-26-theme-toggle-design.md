# Dark/Light Theme Toggle — Design

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add light theme alongside existing dark theme, with toggle UI in sidebar footer and Settings, persisted via UserDefaults.

**Architecture:** `ThemeStore` (existing) provides `ColorScheme?` to window. `VisualTokens` provides static color access resolved via SwiftUI `@Environment`. Light theme uses warm off-white palette with same accent colors but adjusted for light backgrounds.

---

## 1. Architecture

```
ThemeStore (existing, no changes)
  ├── theme: Theme (.system/.light/.dark)
  ├── UserDefaults persistence (key: "todofocus-theme")
  └── preferredColorScheme: ColorScheme?
       ↓
TodoFocusMacApp
  └── .preferredColorScheme(themeStore.preferredColorScheme)
       ↓
ThemeEnvironment Key
  └── @Environment(\.themeMode) -> Theme
       ↓
VisualTokens (refactored)
  ├── dark: colors (current values)
  └── light: colors (new warm off-white palette)
       ↓
Views reference VisualTokens.bgElevated etc. (resolved by theme)
```

## 2. Light Theme Color Palette

| Token | Dark (current) | Light (new) |
|---|---|---|
| `bgBase` | `#0A0A0A` | `#F5F3EE` (warm off-white) |
| `bgElevated` | `#1C1C1C` | `#FFFFFF` |
| `bgFloating` | `#262626` | `#FAFAFA` |
| `textPrimary` | `#FAFAFA` | `#1A1A1A` |
| `textSecondary` | `#8C8C8C` | `#6B6B6B` |
| `textTertiary` | `#666666` | `#9B9B9B` |
| `accentBlue` | `#66B5F5` | `#3B82F6` |
| `accentViolet` | `#9987F2` | `#8B5CF6` |
| `accentAmber` | `#F2A44D` | `#F59E0B` |
| `accentTerracotta` | `#C46849` | `#EA580C` |
| `success` | `#5FCF9C` | `#10B981` |
| `warning` | `#F7BA50` | `#F59E0B` |
| `danger` | `#F06878` | `#EF4444` |
| `sectionBorder` | `white.opacity(0.06)` | `black.opacity(0.08)` |

**Design rationale**: Light theme uses warm off-white (`#F5F3EE`) instead of pure white — feels less clinical. Shadows are soft and diffused.

## 3. Files to Create

### `macos/TodoFocusMac/Sources/Features/Common/ThemeEnvironment.swift`
```swift
import SwiftUI

private struct ThemeModeKey: EnvironmentKey {
    static let defaultValue: Theme = .dark
}

extension EnvironmentValues {
    var themeMode: Theme {
        get { self[ThemeModeKey.self] }
        set { self[ThemeModeKey.self] = newValue }
    }
}

extension View {
    func themeMode(_ theme: Theme) -> some View {
        environment(\.themeMode, theme)
    }
}
```

### `macos/TodoFocusMac/Sources/Features/Common/VisualTokens+Light.swift`
```swift
import SwiftUI

extension VisualTokens {
    static let light = LightTokens()
}

struct LightTokens {
    let bgBase = Color(red: 0.961, green: 0.953, blue: 0.933)       // #F5F3EE
    let bgElevated = Color.white                                       // #FFFFFF
    let bgFloating = Color(red: 0.980, green: 0.980, blue: 0.980)    // #FAFAFA
    let textPrimary = Color(red: 0.102, green: 0.102, blue: 0.102)   // #1A1A1A
    let textSecondary = Color(red: 0.420, green: 0.420, blue: 0.420) // #6B6B6B
    let textTertiary = Color(red: 0.608, green: 0.608, blue: 0.608) // #9B9B9B
    let success = Color(red: 0.063, green: 0.725, blue: 0.506)      // #10B981
    let warning = Color(red: 0.961, green: 0.620, blue: 0.043)      // #F59E0B
    let danger = Color(red: 0.937, green: 0.267, blue: 0.267)        // #EF4444
    let accentBlue = Color(red: 0.231, green: 0.510, blue: 0.965)   // #3B82F6
    let accentViolet = Color(red: 0.545, green: 0.361, blue: 0.965)  // #8B5CF6
    let accentAmber = Color(red: 0.961, green: 0.620, blue: 0.043)  // #F59E0B
    let accentTerracotta = Color(red: 0.918, green: 0.345, blue: 0.047) // #EA580C
    let appBackground = LinearGradient(...)
    let accent = LinearGradient(...)
    let panelBackground = bgElevated
    let sectionBackground = bgElevated
    let sectionBorder = Color.black.opacity(0.08)
}
```

## 4. Files to Modify

### `VisualTokens.swift`
Refactor to use a static `current` computed property that returns appropriate tokens based on `@Environment(\.themeMode)`.

### `TodoFocusMacApp.swift`
Inject theme environment: `RootView(...).themeMode(themeStore.theme)`

### `SidebarView.swift`
Add theme toggle button at bottom of sidebar — cycles: dark → light → system. Uses moon/sun/cloud icons.

### `SettingsView.swift` / `GeneralSettingsView.swift`
Add "Appearance" section with segmented picker: Dark | Light | System.

## 5. UI Details

### Sidebar Footer Toggle
- Position: Bottom of sidebar, above list items or in footer area
- Icon: Cycles through `moon.fill` (dark) → `sun.max.fill` (light) → `circle.lefthalf.filled` (system)
- Size: Small (16x16 or 20x20)
- Tooltip: Shows current theme name

### Settings Appearance Section
```
Section("Appearance") {
    Picker("Theme", selection: $themeStore.theme) {
        Text("Dark").tag(ThemeStore.Theme.dark)
        Text("Light").tag(ThemeStore.Theme.light)
        Text("System").tag(ThemeStore.Theme.system)
    }
    .pickerStyle(.segmented)
}
```

## 6. Technical Notes

- `VisualTokens` usage remains unchanged in views — colors come from the static token struct
- Theme switching applies via `preferredColorScheme` on window + `@Environment` for token resolution
- No database changes required
- No migration needed — UserDefaults key already exists

## 7. Tasks (for implementation plan)

1. Create `ThemeEnvironment.swift`
2. Refactor `VisualTokens.swift` to support light/dark
3. Create `VisualTokens+Light.swift` with light palette
4. Update `TodoFocusMacApp.swift` to inject theme environment
5. Add theme toggle to sidebar footer
6. Add Appearance section to Settings
7. Verify build succeeds
8. Commit
