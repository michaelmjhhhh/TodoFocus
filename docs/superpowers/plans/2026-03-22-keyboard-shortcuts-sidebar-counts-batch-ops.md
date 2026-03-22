# Keyboard Shortcuts, Sidebar Counts & Batch Operations Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add keyboard shortcuts for power users, display task counts in sidebar, and enable multi-select batch operations on tasks.

**Architecture:** Three independent enhancements layered onto the existing app:
1. Keyboard shortcuts via SwiftUI `.keyboardShortcut()` and `@State` focus management
2. Sidebar counts computed from `store.todos` filtered per list
3. Multi-select via `@State var selectedTodoIDs: Set<String>` replacing single `selectedTodoID`

**Tech Stack:** SwiftUI, Observation (`@Observable`), GRDB, xcodebuild

---

## Chunk 1: Sidebar Task Counts

**Files:**
- Modify: `macos/TodoFocusMac/Sources/Features/Sidebar/SidebarView.swift` (lines 6, 44-55, 279-322)
- Modify: `macos/TodoFocusMac/Sources/App/TodoAppStore.swift` (add computed count accessors)

### Tasks:

- [ ] **Step 1: Add todo count accessors to TodoAppStore**

Modify `macos/TodoFocusMac/Sources/App/TodoAppStore.swift` after line 50 (after `var lists`):

```swift
var todoCount: Int { todos.count }
var completedCount: Int { todos.filter { $0.isCompleted }.count }
var importantCount: Int { todos.filter { $0.isImportant }.count }
var myDayCount: Int { todos.filter { $0.isMyDay }.count }
var todayCount: Int { todos.filter { $0.dueDate?.isToday ?? false }.count }
var overdueCount: Int { todos.filter { ($0.dueDate ?? .distantPast) < Date() && !$0.isCompleted }.count }
var plannedCount: Int { todos.filter { $0.dueDate != nil }.count }

func countForList(_ listId: String) -> Int {
    todos.filter { $0.listId == listId && !$0.isCompleted }.count
}
```

- [ ] **Step 2: Update SidebarRowButton to accept count**

Modify `SidebarView.swift` line 279, change the struct declaration:

```swift
private struct SidebarRowButton: View {
    let title: String
    let systemImage: String
    let listColor: Color?
    let count: Int?
    let isSelected: Bool
    let action: () -> Void
```

- [ ] **Step 3: Add count display in SidebarRowButton body**

Modify `SidebarView.swift` around line 303 (before Spacer), add count display:

```swift
if let count {
    Text("\(count)")
        .font(.caption2.weight(.medium))
        .foregroundStyle(isSelected ? VisualTokens.textSecondary : VisualTokens.textTertiary)
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .background(VisualTokens.bgFloating.opacity(0.5), in: Capsule())
}
Spacer(minLength: 0)
Image(systemName: "checkmark")
```

- [ ] **Step 4: Update smartRow to pass counts**

Modify `SidebarView.swift` lines 44-55, update smartRow:

```swift
private func smartRow(_ title: String, systemImage: String, selection: SidebarSelection, count: Int? = nil) -> some View {
    SidebarRowButton(
        title: title,
        systemImage: systemImage,
        listColor: nil,
        count: count,
        isSelected: appModel.selection == selection,
        action: {
            withAnimation(MotionTokens.focusEase) {
                appModel.selectSidebar(selection)
            }
        }
    )
}
```

Update call sites (lines 18-22):
```swift
smartRow("My Day", systemImage: "sun.max", selection: .myDay, count: store.myDayCount)
smartRow("Important", systemImage: "star", selection: .important, count: store.importantCount)
smartRow("Planned", systemImage: "calendar", selection: .planned, count: store.plannedCount)
smartRow("All Tasks", systemImage: "tray.full", selection: .all, count: store.todoCount)
```

- [ ] **Step 5: Update listRow to pass counts**

Modify `SidebarView.swift` lines 58-69, update listRow:

```swift
private func listRow(_ list: TodoList) -> some View {
    SidebarRowButton(
        title: list.name,
        systemImage: "list.bullet",
        listColor: Color(hex: list.color),
        count: store.countForList(list.id),
        isSelected: appModel.selection == .customList(list.id),
        action: {
            withAnimation(MotionTokens.focusEase) {
                appModel.selectSidebar(.customList(list.id))
            }
        }
    )
```

- [ ] **Step 6: Build and test**

Run: `xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -configuration Debug -derivedDataPath "macos/TodoFocusMac/build/DerivedData" -destination "platform=macOS"`

- [ ] **Step 7: Commit**

```bash
git add macos/TodoFocusMac/Sources/Features/Sidebar/SidebarView.swift macos/TodoFocusMac/Sources/App/TodoAppStore.swift
git commit -m "feat: add task counts to sidebar lists"
```

---

## Chunk 2: Keyboard Shortcuts

**Files:**
- Modify: `macos/TodoFocusMac/Sources/Features/TaskList/TaskListView.swift` (lines 96-130, add commands)
- Modify: `macos/TodoFocusMac/Sources/RootView.swift` (lines 1-20, add focused state)

### Tasks:

- [ ] **Step 1: Add focus state and selected task tracking to TaskListView**

Modify `TaskListView.swift` lines 3-9, add:

```swift
struct TaskListView: View {
    @Bindable var appModel: AppModel
    @Bindable var store: TodoAppStore
    @State private var commandText: String = ""
    @State private var isCompletedCollapsed: Bool = false
    @State private var showClearCompletedConfirmation: Bool = false
    @State private var focusedTaskId: String?
    @FocusState private var isCommandFocused: Bool
```

- [ ] **Step 2: Add keyboard shortcut modifiers to root buttons**

Modify `TaskListView.swift` around line 45 (add task button area). Find the QuickAddView section and add shortcuts:

```swift
QuickAddView { title in
    do {
        try store.quickAdd(...)
    } catch {}
}
.padding(10)
.background(...)
// Wrap in a toolbar or add key equivalent
.keyboardShortcut("n", modifiers: .command)  // Cmd+N for new task (focus quick add)
```

- [ ] **Step 3: Add completion shortcut to TodoRowView**

Modify `TodoRowView.swift` around line 22 (completion button), add:

```swift
Button(action: onToggleComplete) {
    Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
        .font(.system(size: 17, weight: .semibold))
        .padding(5)
        .background(todo.isCompleted ? Color.green.opacity(0.22) : Color.white.opacity(0.12), in: Circle())
}
.keyboardShortcut("d", modifiers: .command)  // Cmd+D to toggle done
.buttonStyle(.plain)
```

- [ ] **Step 4: Add navigation shortcuts to TaskListView body**

Modify `TaskListView.swift` after line 80 (after HStack closing brace of columns), add:

```swift
.onKeyPress(.upArrow) {
    navigateUp()
    return .handled
}
.onKeyPress(.downArrow) {
    navigateDown()
    return .handled
}
.onKeyPress(.return) {
    if let focusedTaskId {
        try? store.toggleComplete(todoId: focusedTaskId)
    }
    return .handled
}
.onKeyPress(.delete) {
    if let focusedTaskId {
        try? store.deleteTodo(todoId: focusedTaskId)
        focusedTaskId = nil
    }
    return .handled
}
```

- [ ] **Step 5: Add navigation helper methods**

Add to bottom of TaskListView (before colorForList):

```swift
private func navigateUp() {
    let allTodos = filteredVisibleTodos
    guard !allTodos.isEmpty else { return }
    if let current = focusedTaskId, let idx = allTodos.firstIndex(where: { $0.id == current }), idx > 0 {
        focusedTaskId = allTodos[idx - 1].id
    } else {
        focusedTaskId = allTodos.last?.id
    }
}

private func navigateDown() {
    let allTodos = filteredVisibleTodos
    guard !allTodos.isEmpty else { return }
    if let current = focusedTaskId, let idx = allTodos.firstIndex(where: { $0.id == current }), idx < allTodos.count - 1 {
        focusedTaskId = allTodos[idx + 1].id
    } else {
        focusedTaskId = allTodos.first?.id
    }
}
```

- [ ] **Step 6: Highlight focused row**

Modify `TodoRowView.swift` to accept isFocused parameter and show highlight:

```swift
struct TodoRowView: View {
    let todo: Todo
    let listColor: Color?
    let isSelected: Bool
    let isFocused: Bool  // NEW
    ...
}
```

Add to body overlay:
```swift
.overlay(alignment: .leading) {
    if showIndicator {
        RoundedRectangle(cornerRadius: 8)
            .fill(indicatorColor)
            .frame(width: 3)
    }
}
.overlay {
    if isFocused {
        RoundedRectangle(cornerRadius: 8)
            .stroke(Color.blue.opacity(0.5), lineWidth: 2)
    }
}
```

Update TodoRowView call sites in TaskListView to pass `isFocused: todo.id == focusedTaskId`.

- [ ] **Step 7: Build and test**

Run: `xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -configuration Debug -derivedDataPath "macos/TodoFocusMac/build/DerivedData" -destination "platform=macOS"`

- [ ] **Step 8: Commit**

```bash
git add macos/TodoFocusMac/Sources/Features/TaskList/TaskListView.swift macos/TodoFocusMac/Sources/Features/TaskList/TodoRowView.swift
git commit -m "feat: add keyboard shortcuts for navigation and task actions"
```

---

## Chunk 3: Batch Operations (Multi-Select)

**Files:**
- Modify: `macos/TodoFocusMac/Sources/App/AppModel.swift` (change selectedTodoID)
- Modify: `macos/TodoFocusMac/Sources/Features/TaskList/TaskListView.swift` (selection logic)
- Modify: `macos/TodoFocusMac/Sources/Features/TaskList/TodoRowView.swift` (selection UI)

### Tasks:

- [ ] **Step 1: Change AppModel selection from single to multi**

Modify `macos/TodoFocusMac/Sources/App/AppModel.swift` line 8:

```swift
var selectedTodoIDs: Set<String> = []
```

Update method `selectTodo` to add/remove from set:

```swift
func selectTodo(todoId: String, exclusive: Bool = true) {
    if exclusive {
        selectedTodoIDs = [todoId]
    } else {
        if selectedTodoIDs.contains(todoId) {
            selectedTodoIDs.remove(todoId)
        } else {
            selectedTodoIDs.insert(todoId)
        }
    }
}
```

Update `clearSelection`:

```swift
func clearSelection() {
    selectedTodoIDs = []
}
```

- [ ] **Step 2: Update TodoRowView for multi-select**

Modify `TodoRowView.swift` to use `isSelected: selectedTodoIDs.contains(todo.id)`.

Add shift-click support in TaskListView ForEach:

```swift
ForEach(todos) { todo in
    TodoRowView(
        todo: todo,
        listColor: colorForList(listId: todo.listId),
        isSelected: store.selectedTodoIDs.contains(todo.id),  // Changed
        ...
    )
    .onTapGesture {
        // If shift key held, add to selection
        // This requires tracking lastSelectedId
    }
}
```

- [ ] **Step 3: Add batch action bar**

Modify `TaskListView.swift` after commandBar (around line 95), add:

```swift
if !appModel.selectedTodoIDs.isEmpty {
    HStack {
        Text("\(appModel.selectedTodoIDs.count) selected")
            .font(.caption)
        Spacer()
        Button("Complete") {
            for id in appModel.selectedTodoIDs {
                try? store.toggleComplete(todoId: id)
            }
            appModel.clearSelection()
        }
        Button(role: .destructive, "Delete") {
            for id in appModel.selectedTodoIDs {
                try? store.deleteTodo(todoId: id)
            }
            appModel.clearSelection()
        }
        Button("Cancel") {
            appModel.clearSelection()
        }
    }
    .padding(8)
    .background(VisualTokens.bgFloating, in: RoundedRectangle(cornerRadius: 8))
}
```

- [ ] **Step 4: Update TodoAppStore.selectedTodo**

Modify `TodoAppStore.swift` property:

```swift
var selectedTodoIDs: Set<String> = []

var selectedTodo: Todo? {
    guard let first = selectedTodoIDs.first else { return nil }
    return todos.first { $0.id == first }
}
```

- [ ] **Step 5: Build and test**

Run: `xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -configuration Debug -derivedDataPath "macos/TodoFocusMac/build/DerivedData" -destination "platform=macOS"`

- [ ] **Step 6: Commit**

```bash
git add macos/TodoFocusMac/Sources/App/AppModel.swift macos/TodoFocusMac/Sources/App/TodoAppStore.swift macos/TodoFocusMac/Sources/Features/TaskList/TaskListView.swift macos/TodoFocusMac/Sources/Features/TaskList/TodoRowView.swift
git commit -m "feat: add multi-select batch operations for tasks"
```

---

## Usage

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Cmd+N` | Focus quick-add bar |
| `Cmd+K` | Focus search |
| `Cmd+D` | Toggle completion of focused task |
| `↑/↓` | Navigate tasks |
| `Enter` | Complete focused task |
| `Delete` | Delete focused task |
| `Cmd+Click` | Add to selection |
| `Shift+Click` | Range select |

### Sidebar Counts
- Each list shows count of active (non-completed) tasks
- Smart lists show filtered counts (Important = important tasks, etc.)

### Batch Operations
- `Cmd+Click` or `Shift+Click` to select multiple tasks
- Action bar appears with Complete/Delete/Cancel options
