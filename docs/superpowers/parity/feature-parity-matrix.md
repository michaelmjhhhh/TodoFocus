# TodoFocus Electron -> SwiftUI Feature Parity Matrix

This document is the source of truth for rewrite parity.

- Scope: match current user-visible behavior in the Electron app.
- Pass rule: SwiftUI implementation must satisfy each required contract below.
- Non-goal: introducing new product behavior during parity phase.

## A. Smart Lists and Time Filters

### Smart list contracts

- [ ] A-SMART-001: default active view is `myday` on app launch.
- [ ] A-SMART-002: `myday` view shows only tasks where `isMyDay == true`.
- [ ] A-SMART-003: `important` view shows only tasks where `isImportant == true`.
- [ ] A-SMART-004: `planned` view shows only tasks where `dueDate != nil`.
- [ ] A-SMART-005: `all` view shows all tasks.
- [ ] A-SMART-006: custom list view shows only tasks where `task.listId == activeListId`.

### Time filter contracts

- [ ] A-TIME-001: default time filter is `all-dates`.
- [ ] A-TIME-002: `all-dates` matches all tasks, including `dueDate == nil`.
- [ ] A-TIME-003: `no-date` matches only tasks with `dueDate == nil`.
- [ ] A-TIME-004: `overdue` compares by local calendar day and excludes tasks due earlier today.
- [ ] A-TIME-005: `today` matches only tasks due on local current day.
- [ ] A-TIME-006: `tomorrow` matches only tasks due on local next day.
- [ ] A-TIME-007: `next-7-days` includes dayDiff `0...6` only.
- [ ] A-TIME-008: date-based filters (`overdue/today/tomorrow/next-7-days`) exclude `dueDate == nil`.
- [ ] A-TIME-009: changing sidebar view does not reset selected time filter.

### Composition contracts

- [ ] A-COMP-001: result set is intersection of active view filter and active time filter.
- [ ] A-COMP-002: `planned + no-date` returns empty list.

## B. Sidebar, Selection, and App Shell

- [ ] B-SHELL-001: navigating to a different view clears selected task.
- [ ] B-SHELL-002: selecting a task row opens detail panel for that task.
- [ ] B-SHELL-003: closing detail panel clears selected task only.
- [ ] B-SHELL-004: deleting currently active custom list routes active view to `all`.
- [ ] B-SHELL-005: row action taps (complete/star/delete) do not trigger row select/open detail.
- [ ] B-SHELL-006: if selected task no longer exists, detail panel closes.

## C. Quick Add Behavior

- [ ] C-ADD-001: empty or whitespace-only quick add is ignored.
- [ ] C-ADD-002: quick add in `myday` creates task with `isMyDay == true`.
- [ ] C-ADD-003: quick add in `important` creates task with `isImportant == true`.
- [ ] C-ADD-004: quick add in `planned` creates task with non-nil `dueDate`.
- [ ] C-ADD-005: quick add in custom list sets `listId = activeListId`.
- [ ] C-ADD-006: quick add in `all` does not auto-set smart-list flags.
- [ ] C-ADD-007: after successful submit, input clears and focus returns to input.

## D. Task Detail (Notes, Due Date, Steps)

### Notes contracts

- [ ] D-NOTE-001: notes text updates instantly in UI while typing.
- [ ] D-NOTE-002: notes persistence is debounced at ~500ms idle.
- [ ] D-NOTE-003: continued typing resets debounce timer (last value wins).
- [ ] D-NOTE-004: task prop change re-syncs local notes state.

### Due date contracts

- [ ] D-DUE-001: setting due date persists selected date value.
- [ ] D-DUE-002: removing due date persists `nil`.
- [ ] D-DUE-003: remove-due-date action appears only when due date exists.

### Steps contracts

- [ ] D-STEP-001: adding blank step is ignored.
- [ ] D-STEP-002: adding valid step trims title and persists it.
- [ ] D-STEP-003: new step default order is tail (`sortOrder = stepCountBeforeAdd`).
- [ ] D-STEP-004: steps display in ascending `sortOrder`.
- [ ] D-STEP-005: toggling step flips completion state only.
- [ ] D-STEP-006: deleting step removes it.
- [ ] D-STEP-007: deleting a step does not compact/rebalance remaining `sortOrder` values.

## E. Launch Resources and Launch All

### Resource model contracts

- [ ] E-RES-001: each task stores launch resources payload; empty default is `[]`.
- [ ] E-RES-002: supported resource types are `url`, `file`, `app`.
- [ ] E-RES-003: maximum resources per task is `12`.
- [ ] E-RES-004: serialized payload max length is `16000` chars.

### Validation contracts

- [ ] E-VAL-001: `url` accepts only `http` and `https`.
- [ ] E-VAL-002: `url` rejects dangerous schemes (for example `javascript:`).
- [ ] E-VAL-003: `file` requires absolute path.
- [ ] E-VAL-004: `app` accepts absolute `.app` path and allowlisted deep-link schemes.
- [ ] E-VAL-005: invalid resource blocks save and surfaces validation feedback.

### Editor contracts

- [ ] E-EDIT-001: add/edit/remove in editor are local until explicit save.
- [ ] E-EDIT-002: save success messaging matches current behavior (`saved N`, `cleared`).
- [ ] E-EDIT-003: add button disabled when resource count hits 12.
- [ ] E-EDIT-004: desktop-only helper text shown when runtime capability is unavailable.

### Launch All contracts

- [ ] E-LAUNCH-001: launch executes sequentially, one resource at a time.
- [ ] E-LAUNCH-002: one failed/rejected launch does not block remaining resources.
- [ ] E-LAUNCH-003: `launchedCount` includes only launched items.
- [ ] E-LAUNCH-004: no resources -> no-op with clear user feedback.
- [ ] E-LAUNCH-005: unavailable desktop integration -> clear user feedback.
- [ ] E-LAUNCH-006: result summary communicates mixed outcomes (`Launched X. Y failed`).
- [ ] E-LAUNCH-007: implementation does not execute shell commands for launch resources.

## F. Detail Panel Resize

- [ ] F-RESIZE-001: default detail width is restored from persisted value when valid.
- [ ] F-RESIZE-002: fallback default detail width is `380`.
- [ ] F-RESIZE-003: width is clamped to minimum `340`.
- [ ] F-RESIZE-004: width is clamped to maximum `min(760, windowWidth - 460Equivalent)`.
- [ ] F-RESIZE-005: drag resize updates width continuously.
- [ ] F-RESIZE-006: resize width is persisted and restored on relaunch.
- [ ] F-RESIZE-007: viewport resize re-clamps persisted/current width.

## G. Theme Persistence

- [ ] G-THEME-001: default theme is dark.
- [ ] G-THEME-002: toggling theme persists preference locally.
- [ ] G-THEME-003: saved light theme is applied on relaunch.
- [ ] G-THEME-004: dark mode uses default token set when light override is absent.

## H. Acceptance Examples (Input -> Expected)

1. A-TIME-004: `overdue` with due time earlier today returns false.
2. A-TIME-006: `tomorrow` with date +1 day returns true; +2 day returns false.
3. A-TIME-007: `next-7-days` includes day 6, excludes day 7.
4. A-COMP-002: planned + no-date returns empty set.
5. C-ADD-004: quick add in planned creates task with non-nil due date.
6. D-NOTE-002: rapid typing yields one debounced notes save call.
7. D-STEP-007: delete middle step keeps non-contiguous remaining sort orders.
8. E-VAL-002: `javascript:` launch URL is rejected.
9. E-LAUNCH-002: with 3 resources and one failure, 2 still launch.
10. F-RESIZE-006: resize to 520, relaunch, width restores to 520 (or clamped if viewport smaller).

## Status Tracking

- Rewrite branch: `feat/swiftui-rewrite-parity-15`
- Issue: #15
- Owner: rewrite execution session
