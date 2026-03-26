# Overdue Tasks Design

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan.

**Goal:** Add a dedicated "Overdue" sidebar item that displays incomplete tasks past their due date, showing time debt (elapsed time since deadline) and total debt across all overdue tasks.

**Architecture:**
- Extend `SmartList` enum with `.overdue` case
- Extend `SidebarItem` enum with `.overdue` case
- Add computed `debtSeconds` property to `Todo` domain model
- Create `OverdueTasksView` as a dedicated view
- Overdue section shows in `TaskListView` when Overdue sidebar item is selected
- Time debt = `max(0, now - dueDate)` in seconds
- Total debt = sum of all individual overdue task debts
- Tasks sorted by oldest deadline first (highest debt first)
- Completing a task resolves its overdue status

**Tech Stack:** SwiftUI + Observation (`@Observable`) + GRDB/SQLite

---

## Design Details

### 1. Domain Model Changes

**File:** `macos/TodoFocusMac/Sources/Core/Todo.swift`

Add `debtSeconds` computed property:

```swift
var debtSeconds: Int? {
    guard let due = dueDate, !isCompleted else { return nil }
    let diff = Date().timeIntervalSince(due)
    return diff > 0 ? Int(diff) : nil
}

var isOverdue: Bool {
    debtSeconds != nil
}
```

### 2. Sidebar Changes

**File:** `macos/TodoFocusMac/Sources/Core/SidebarItem.swift`

Add overdue case:

```swift
enum SidebarItem: String, CaseIterable, Identifiable {
    case all, myDay, important, planned, overdue  // ← add overdue
    // ...
}
```

### 3. SmartList Changes

**File:** `macos/TodoFocusMac/Sources/Core/Filters/SmartList.swift`

Already has `overdue` filter. Confirm it applies to incomplete tasks only:

```swift
case overdue:
    return !todo.isCompleted && dayDiff < 0
```

### 4. AppModel Changes

**File:** `macos/TodoFocusMac/Sources/App/AppModel.swift`

Add overdue selection handling:

```swift
case .overdue:
    appState.selectedTimeFilter = .overdue
```

### 5. TodoAppStore Changes

**File:** `macos/TodoFocusMac/Sources/App/TodoAppStore.swift`

Add computed property for total overdue debt:

```swift
var totalOverdueDebtSeconds: Int {
    todos
        .filter { $0.isOverdue }
        .compactMap { $0.debtSeconds }
        .reduce(0, +)
}

var overdueCount: Int {
    todos.filter { $0.isOverdue }.count
}
```

Add `formatDebt` helper:

```swift
func formatDebt(_ seconds: Int) -> String {
    if seconds < 60 {
        return "\(seconds)s"
    } else if seconds < 3600 {
        let minutes = seconds / 60
        return "\(minutes)m"
    } else {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(hours)h"
        }
    }
}
```

### 6. TaskListView Changes

**File:** `macos/TodoFocusMac/Sources/Features/TaskList/TaskListView.swift`

When `appModel.selection == .overdue`:
- Show overdue section header: "Overdue · {totalDebt} total debt"
- Sort overdue tasks by oldest due date first
- Each task row shows debt badge: "Overdue 2h 30m"
- Show empty state if no overdue tasks

For non-overdue views:
- No change (keep existing behavior)

### 7. Sidebar View Changes

**File:** `macos/TodoFocusMac/Sources/Features/Sidebar/SidebarView.swift`

Add Overdue item with count badge:

```swift
SidebarItemRow(item: .overdue, count: store.overdueCount)
```

### 8. Task Row Overdue Badge

**File:** `macos/TodoFocusMac/Sources/Features/TaskList/TaskRowView.swift`

Add debt badge for overdue tasks:

```swift
if let debt = todo.debtSeconds {
    DebtBadge(timeString: store.formatDebt(debt))
}
```

Create new component:

```swift
struct DebtBadge: View {
    let timeString: String

    var body: some View {
        Text("Overdue \(timeString)")
            .font(.caption2)
            .foregroundColor(.red)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.red.opacity(0.1))
            .cornerRadius(4)
    }
}
```

---

## Implementation Order

1. Domain model — add `debtSeconds` and `isOverdue` to `Todo`
2. Sidebar — add `overdue` case to `SidebarItem`
3. AppModel — handle `.overdue` selection
4. TodoAppStore — add `totalOverdueDebtSeconds`, `overdueCount`, `formatDebt()`
5. SidebarView — add Overdue row with count
6. TaskRowView — add `DebtBadge` component
7. TaskListView — integrate Overdue view with header and sorted tasks
8. Empty state — handle no overdue tasks case

---

## Edge Cases

- **No due date set:** Task cannot be overdue, `debtSeconds = nil`
- **Task completed:** Even if past due date, not shown in Overdue
- **Multiple overdue tasks:** All shown, sorted by oldest deadline first
- **Due date in future:** Not overdue, `debtSeconds = nil` (dayDiff >= 0)
- **Due date exactly now:** Not overdue (must be strictly past)
