# UI/UX Polish Design Specification

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Polish TodoFocus UI/UX to achieve a warm, modern aesthetic (Craft/Arc inspired) while preserving all functionality. Deep dark mode first.

**Architecture:** Keep existing three-panel layout (Sidebar + TaskList + Detail). Add visual depth through layered backgrounds, refined shadows, and thoughtful motion. No structural changes.

**Tech Stack:** SwiftUI, existing ThemeTokens system, MotionTokens for animation timing.

---

## 1. TaskRowView — Refined Interactions

**Files:**
- `macos/TodoFocusMac/Sources/Features/TaskList/TodoRowView.swift`

### 1a. Completion Button — Add Texture and Depth

**Current:**
```swift
Button(action: onToggleComplete) {
    Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
        .font(.system(size: 17, weight: .semibold))
        .padding(5)
        .background(todo.isCompleted ? Color.green.opacity(0.22) : Color.white.opacity(0.12), in: Circle())
}
.buttonStyle(.plain)
.foregroundStyle(todo.isCompleted ? Color.green : Color.white.opacity(0.94))
```

**Refined:**
- Uncompleted: Circle with subtle inner shadow, light stroke, terracotta fill on hover
- Completed: Circle with terracotta gradient fill + checkmark, inner glow ring
- Use `tokens.accentTerracotta` for hover/completed states (theme-aware)
- Replace hardcoded `Color.white`, `Color.green`, `Color.yellow` with theme tokens
- Subtle scale animation (0.95 → 1.0) on tap

### 1b. Hover/Selected State — Smoother Motion

**Current:**
```swift
.appRowState(isHovered: isHovered, isSelected: isSelected)
.opacity(isSecondaryControlsVisible ? 1 : 0.001)
.offset(x: isSecondaryControlsVisible ? 0 : 4)
.animation(MotionTokens.hoverEase, value: isSecondaryControlsVisible)
```

**Refined:**
- Add background color transition on hover: transparent → `tokens.bgFloating.opacity(0.5)`
- Add subtle left-border reveal on hover (the color indicator animates in)
- Selected row gets a subtle terracotta-tinted background instead of pure white
- Scale micro-animation on row: 1.0 → 0.99 → 1.0 on press

### 1c. Overall Refinement

- Importance star: use `tokens.warning` (warm yellow) instead of bare `Color.yellow`
- Foreground text: use `tokens.textPrimary` for selected state instead of bare `Color.white`
- Muted text for due dates: already uses `tokens.mutedText` — verify

---

## 2. QuickAddView — Floating Card Style

**Files:**
- `macos/TodoFocusMac/Sources/Features/TaskList/QuickAddView.swift`

**Current:** Uses `.roundedBorder` text field, no visual separation from list.

**Refined:**
- Replace `.roundedBorder` with custom styled TextField:
  - Background: `tokens.bgElevated`
  - Border: 1px `tokens.sectionBorder`, corner radius 12
  - Inner shadow (subtle inset look)
  - Placeholder: "Add a task..." in `tokens.textTertiary`
- Wrap in a floating card:
  - Background: `tokens.bgElevated`
  - Corner radius: 14
  - Shadow: soft, warm-toned (not pure black) — `Color.black.opacity(0.20)` radius 12, y: 4
  - Border: 1px subtle lighter border on dark, none on light
- Add a small "+" icon to the left of the text field
- Add button: "Add" in terracotta accent, pill-shaped
- Overall card has slight warm tint to match aesthetic

---

## 3. TaskDetailView — Visual Hierarchy

**Files:**
- `macos/TodoFocusMac/Sources/Features/TaskDetail/TaskDetailView.swift`

**Current:** Functional but flat — basic section spacing.

**Refined:**
- Title: larger font (24pt), semibold, `tokens.textPrimary`
- Section headers: 12pt, uppercase or small caps, `tokens.textTertiary`, extra letter-spacing
- Sections separated by subtle 1px divider line: `tokens.sectionBorder.opacity(0.5)`
- Increase section spacing: 24pt between sections (was 16pt)
- Notes section: slightly lighter background card (bgFloating) to elevate it
- Focus time badge: warm gradient pill instead of plain text
- Deep Focus button: terracotta gradient fill, white text, spring animation on hover

---

## 4. TaskListView — Overall Polish

**Files:**
- `macos/TodoFocusMac/Sources/Features/TaskList/TaskListView.swift`

### 4a. Section Cards

- Active/Completed columns: slightly more rounded corners (12px)
- Shadow: warm-toned shadow color (not pure black) for depth
- Background: `tokens.sectionBackground`

### 4b. Quick Add Card Placement

- QuickAdd card already has shadow — refine shadow to be warmer (opacity 0.18 instead of 0.12)

### 4c. Completed Column

- Collapse/expand chevron animation already good
- "Clear" button: already terracotta — verify theme token usage

---

## 5. SidebarView — Refinement

**Files:**
- `macos/TodoFocusMac/Sources/Features/Sidebar/SidebarView.swift`

- List items: refine hover background transition (150ms, ease-out)
- Selected state: warm terracotta tint in background
- Theme toggle button: already functional — verify animation smoothness
- Section dividers: subtle, barely visible

---

## 6. Motion & Animation System

**Files:**
- `macos/TodoFocusMac/Sources/Features/Common/MotionTokens.swift`

**Refined timing:**
- All transitions: 200ms base (Linear or ease-out)
- Hover states: 150ms
- Panel animations: 280ms spring
- Keep existing spring definitions but ensure all views use them consistently

---

## 7. Color System Verification

Verify all hardcoded colors replaced with theme tokens across all view files:

```bash
grep -rn "Color.white\|Color.black\|Color.green\|Color.yellow\|Color.red" \
  macos/TodoFocusMac/Sources/Features/ \
  --include="*.swift"
```

Replace any remaining bare colors:
- `Color.white` → `tokens.textPrimary` or `Color.white.opacity(...)` carefully
- `Color.yellow` → `tokens.warning`
- `Color.green` → `tokens.success`
- `Color.red` → `tokens.danger`

---

## Implementation Order

1. TaskRowView — completion button + hover/selected
2. QuickAddView — floating card style
3. TaskDetailView — visual hierarchy
4. TaskListView — section polish
5. SidebarView — refine hover/selected
6. MotionTokens — ensure consistent timing
7. Color audit — replace all bare colors
8. Build and verify

---

## Success Criteria

- [ ] All hardcoded colors replaced with theme tokens
- [ ] Deep mode feels warm and layered, not flat
- [ ] Task completion button has visual depth (gradient, inner glow)
- [ ] QuickAdd floats above list with warm shadow
- [ ] Task Detail sections clearly separated with visual hierarchy
- [ ] Hover/selected states animate smoothly (150-200ms)
- [ ] No pure black or pure white used in foreground elements in dark mode
- [ ] Light mode is also warm and refined (secondary priority)
