# UI/UX Polish Implementation Plan

> **For Claude:** REQUIRED: Use superpowers:subagent-driven-development to implement this plan task-by-task.

**Goal:** Polish TodoFocus UI/UX to achieve a warm, modern aesthetic (Craft/Arc inspired). Deep dark mode first, all hardcoded colors replaced with theme tokens.

**Architecture:** Keep existing three-panel layout. Add visual depth through layered backgrounds, refined shadows, and thoughtful motion. No structural changes.

**Tech Stack:** SwiftUI, existing ThemeTokens system, MotionTokens for animation timing.

---

## Chunk 1: TaskRowView — Completion Button & Hover States

**Files:**
- Modify: `macos/TodoFocusMac/Sources/Features/TaskList/TodoRowView.swift`

### Task 1: Replace hardcoded colors with theme tokens

- [ ] **Step 1: Audit current hardcoded colors**

Run in worktree:
```bash
grep -n "Color.white\|Color.green\|Color.yellow\|Color.red" macos/TodoFocusMac/Sources/Features/TaskList/TodoRowView.swift
```

Expected output: Lines with bare Color.white/green/yellow/red

- [ ] **Step 2: Replace Color.yellow with tokens.warning (importance star)**

Line ~39: `Color.yellow` → `tokens.warning`

- [ ] **Step 3: Replace Color.green in completion with tokens.success**

Lines ~54, 57: `Color.green` → `tokens.success`

- [ ] **Step 4: Replace Color.white in foregroundStyle with tokens.textPrimary**

Lines ~57, 69: `Color.white` → `tokens.textPrimary`

- [ ] **Step 5: Replace Color.white.opacity() with tokens.textPrimary.opacity()**

Line ~54: `Color.white.opacity(0.12)` → `tokens.textPrimary.opacity(0.10)`
Line ~60: `Color.white.opacity(...)` → `tokens.textPrimary.opacity(...)`

- [ ] **Step 6: Commit**
```bash
git add macos/TodoFocusMac/Sources/Features/TaskList/TodoRowView.swift
git commit -m "fix(theme): replace hardcoded colors in TodoRowView with tokens"
```

### Task 2: Completion button visual depth

- [ ] **Step 1: Refactor completion button to use gradient fill and inner glow**

Replace the completion button body with:

```swift
Button(action: onToggleComplete) {
    ZStack {
        // Outer circle
        Circle()
            .fill(todo.isCompleted
                ? tokens.accentTerracotta
                : tokens.bgFloating)
            .overlay {
                Circle()
                    .stroke(
                        todo.isCompleted
                            ? tokens.accentTerracotta.opacity(0.5)
                            : tokens.textTertiary.opacity(0.3),
                        lineWidth: 1.5
                    )
            }

        // Inner glow ring for completed
        if todo.isCompleted {
            Circle()
                .stroke(tokens.accentTerracotta.opacity(0.3), lineWidth: 2)
                .padding(3)
        }

        // Checkmark
        Image(systemName: todo.isCompleted ? "checkmark" : "circle")
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(todo.isCompleted ? .white : tokens.textTertiary)
    }
    .frame(width: 28, height: 28)
}
.buttonStyle(.plain)
.foregroundStyle(todo.isCompleted ? tokens.success : tokens.textPrimary)
.scaleEffect(todo.isCompleted ? 1.0 : 0.95)
.animation(MotionTokens.hoverEase, value: todo.isCompleted)
```

- [ ] **Step 2: Commit**
```bash
git add macos/TodoFocusMac/Sources/Features/TaskList/TodoRowView.swift
git commit -m "feat(ui): add visual depth to completion button with gradient and inner glow"
```

### Task 3: Hover/selected state motion refinements

- [ ] **Step 1: Add background color transition on hover**

Find `.appRowState(isHovered: isHovered, isSelected: isSelected)` and add after it:

```swift
.background {
    RoundedRectangle(cornerRadius: 8)
        .fill(isHovered ? tokens.bgFloating.opacity(0.4) : Color.clear)
        .animation(MotionTokens.hoverEase, value: isHovered)
}
```

- [ ] **Step 2: Add scale micro-animation on press**

In the main HStack, add:
```swift
.scaleEffect(isPressed ? 0.99 : 1.0)
.animation(.easeInOut(duration: 0.1), value: isPressed)
```

Note: `isPressed` state needs to be added via `@State private var isPressed = false`

- [ ] **Step 3: Refine selected row background**

Replace `.appRowState` with explicit styling that uses terracotta tint for selected:
```swift
.background {
    RoundedRectangle(cornerRadius: 8)
        .fill(isSelected
            ? tokens.accentTerracotta.opacity(0.08)
            : (isHovered ? tokens.bgFloating.opacity(0.4) : Color.clear))
}
```

- [ ] **Step 4: Commit**
```bash
git add macos/TodoFocusMac/Sources/Features/TaskList/TodoRowView.swift
git commit -m "feat(ui): refine hover/selected states with smooth transitions"
```

---

## Chunk 2: QuickAddView — Floating Card Style

**Files:**
- Modify: `macos/TodoFocusMac/Sources/Features/TaskList/QuickAddView.swift`

### Task 4: Replace roundedBorder with custom floating card

- [ ] **Step 1: Audit current QuickAddView structure**

Read current QuickAddView and identify the `.roundedBorder` text field

- [ ] **Step 2: Replace with custom styled floating card**

```swift
var body: some View {
    HStack(spacing: 10) {
        // Plus icon
        Image(systemName: "plus")
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(tokens.textTertiary)

        TextField("Add a task...", text: $text)
            .textFieldStyle(.plain)
            .font(.system(size: 14))
            .foregroundStyle(tokens.textPrimary)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(tokens.bgBase.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(tokens.sectionBorder, lineWidth: 1)
            }
            .focused($isInputFocused)
            .onSubmit(submit)

        Button("Add") {
            submit()
        }
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(tokens.accentTerracotta, in: Capsule())
        .buttonStyle(.plain)
        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
    .padding(12)
    .background(tokens.bgElevated, in: RoundedRectangle(cornerRadius: 14))
    .overlay {
        RoundedRectangle(cornerRadius: 14)
            .stroke(tokens.sectionBorder.opacity(0.8), lineWidth: 1)
    }
    .shadow(color: Color.black.opacity(0.18), radius: 10, y: 4)
    .background {
        Button("") {
            isInputFocused = true
        }
        .keyboardShortcut("n", modifiers: [.command, .shift])
        .opacity(0)
        .allowsHitTesting(false)
    }
}
```

- [ ] **Step 3: Commit**
```bash
git add macos/TodoFocusMac/Sources/Features/TaskList/QuickAddView.swift
git commit -m "feat(ui): replace roundedBorder with floating card style"
```

---

## Chunk 3: TaskDetailView — Visual Hierarchy

**Files:**
- Modify: `macos/TodoFocusMac/Sources/Features/TaskDetail/TaskDetailView.swift`
- Modify: `macos/TodoFocusMac/Sources/Features/Common/MotionTokens.swift`

### Task 5: Refine title and section headers

- [ ] **Step 1: Audit current title size and section spacing**

Read TaskDetailView body, find title and section implementations

- [ ] **Step 2: Make title larger and more prominent**

Find where title Text is set (around line 31 header section), refine:
```swift
Text(todo.title)
    .font(.system(size: 24, weight: .semibold, design: .default))
    .foregroundStyle(tokens.textPrimary)
    .lineLimit(2)
```

- [ ] **Step 3: Add section header styling**

Find all section labels (dateSection, focusTimeSection, notesSection, etc.) and wrap header text:
```swift
private func sectionHeader(_ title: String) -> some View {
    Text(title)
        .font(.system(size: 11, weight: .semibold, design: .default))
        .foregroundStyle(tokens.textTertiary)
        .textCase(.uppercase)
        .tracking(0.5)
}
```

- [ ] **Step 4: Add subtle dividers between sections**

In the VStack of sections, add between each:
```swift
Divider()
    .background(tokens.sectionBorder.opacity(0.5))
    .padding(.vertical, 12)
```

- [ ] **Step 5: Increase section spacing from 16 to 24**

Line ~48: `.padding(16)` → `.padding(.horizontal, 16).padding(.vertical, 20)`

- [ ] **Step 6: Commit**
```bash
git add macos/TodoFocusMac/Sources/Features/TaskDetail/TaskDetailView.swift
git commit -m "feat(ui): refine TaskDetail visual hierarchy with larger title and section headers"
```

### Task 6: Deep Focus button with terracotta gradient

- [ ] **Step 1: Find Deep Focus button in header**

Read header section of TaskDetailView

- [ ] **Step 2: Refine button styling**

Replace plain button with gradient terracotta:
```swift
Button {
    showDeepFocusSheet = true
} label: {
    HStack(spacing: 6) {
        Image(systemName: "flame.fill")
            .font(.system(size: 12))
        Text("Deep Focus")
            .font(.system(size: 13, weight: .semibold))
    }
    .foregroundStyle(.white)
    .padding(.horizontal, 14)
    .padding(.vertical, 8)
    .background(
        LinearGradient(
            colors: [tokens.accentTerracotta, tokens.accentTerracotta.opacity(0.8)],
            startPoint: .leading,
            endPoint: .trailing
        ),
        in: Capsule()
    )
}
.buttonStyle(.plain)
```

- [ ] **Step 3: Commit**
```bash
git add macos/TodoFocusMac/Sources/Features/TaskDetail/TaskDetailView.swift
git commit -m "feat(ui): add terracotta gradient to Deep Focus button"
```

---

## Chunk 4: TaskListView & SidebarView — Polish

**Files:**
- Modify: `macos/TodoFocusMac/Sources/Features/TaskList/TaskListView.swift`
- Modify: `macos/TodoFocusMac/Sources/Features/Sidebar/SidebarView.swift`

### Task 7: Warm shadows in TaskListView

- [ ] **Step 1: Audit shadow opacity values**

Read TaskListView and find all `.shadow()` calls

- [ ] **Step 2: Increase shadow opacity from 0.12 to 0.18 on section cards**

Line ~268: `.shadow(color: Color.black.opacity(0.12), radius: 6, y: 2)` → `.shadow(color: Color.black.opacity(0.18), radius: 8, y: 3)`

Line ~84 (QuickAdd shadow): `.shadow(color: Color.black.opacity(0.18), radius: 8, y: 3)` — already at 0.18, verify

- [ ] **Step 3: Commit**
```bash
git add macos/TodoFocusMac/Sources/Features/TaskList/TaskListView.swift
git commit -m "feat(ui): warm shadow values in TaskListView"
```

### Task 8: Sidebar hover transition refinement

- [ ] **Step 1: Find SidebarRowButton hover animation**

Read SidebarView, find `.onHover` block

- [ ] **Step 2: Verify hover uses 150ms ease-out**

Line ~275: `withAnimation(.easeInOut(duration: 0.12))` — this is 120ms, change to 150ms

- [ ] **Step 3: Add subtle terracotta tint to selected state**

In SidebarRowButton body, find the selected background and add:
```swift
.background(isSelected ? tokens.accentTerracotta.opacity(0.08) : Color.clear)
```

- [ ] **Step 4: Commit**
```bash
git add macos/TodoFocusMac/Sources/Features/Sidebar/SidebarView.swift
git commit -m "feat(ui): refine Sidebar hover/selected states"
```

---

## Chunk 5: MotionTokens & Color Audit

**Files:**
- Modify: `macos/TodoFocusMac/Sources/Features/Common/MotionTokens.swift`

### Task 9: Ensure consistent MotionTokens usage

- [ ] **Step 1: Audit all animation timings across views**

```bash
grep -rn "animation.*duration" macos/TodoFocusMac/Sources/Features/ --include="*.swift" | head -30
```

- [ ] **Step 2: Verify hoverEase is 150ms**

Read MotionTokens.swift, check `hoverEase` value

- [ ] **Step 3: Verify interactiveSpring and focusEase are appropriate**

Read MotionTokens.swift values, no changes needed if already sensible

- [ ] **Step 4: Commit (only if changes made)**
```bash
git add macos/TodoFocusMac/Sources/Features/Common/MotionTokens.swift
git commit -m "chore: verify consistent motion timing"
```

### Task 10: Full color audit — replace all hardcoded colors

- [ ] **Step 1: Find all bare colors across Features**

```bash
grep -rn "Color.white\|Color.green\|Color.yellow\|Color.red" \
  macos/TodoFocusMac/Sources/Features/ \
  --include="*.swift"
```

- [ ] **Step 2: For each file, replace with theme tokens**

Priority order:
1. `TodoRowView.swift` (already done in Task 1)
2. `DeepFocusOverlayView.swift` — hardcoded Color(hex:) and .secondary
3. Any remaining files

- [ ] **Step 3: DeepFocusOverlayView color fixes**

Lines ~13, 20, 21, 23, 27: Use theme tokens instead of hardcoded colors

- [ ] **Step 4: Commit**
```bash
git add [remaining files]
git commit -m "fix(theme): replace remaining hardcoded colors with theme tokens"
```

---

## Chunk 6: Build & Verify

### Task 11: Build and fix any issues

- [ ] **Step 1: Generate Xcode project**
```bash
cd macos/TodoFocusMac && xcodegen generate
```

- [ ] **Step 2: Build**
```bash
xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"
```

Expected: BUILD SUCCEEDED

- [ ] **Step 3: If errors, fix and rebuild**

Common issues:
- Missing `@Environment(\.themeTokens)` declarations in subviews
- Type mismatches after token replacements

- [ ] **Step 4: Commit if build-only changes**
```bash
git add -A
git commit -m "chore: build fixes for UI polish"
```

---

## Chunk 7: Light Mode Verification

### Task 12: Verify light mode looks warm and refined

- [ ] **Step 1: Switch to light mode in app**

- [ ] **Step 2: Check QuickAdd card**

Verify it has warm shadows, correct contrast

- [ ] **Step 3: Check TaskRow**

Verify completion button looks good in light mode

- [ ] **Step 4: Fix any issues found**

Common light mode issues:
- Shadows too dark
- Text contrast insufficient
- Borders invisible

- [ ] **Step 5: Commit**
```bash
git add [files fixed]
git commit -m "feat(ui): light mode refinements"
```

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
