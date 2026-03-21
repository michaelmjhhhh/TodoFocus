# Time Filter Per View Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a time-based filter control that works in every view (My Day, Important, Planned, All Tasks, and each custom list) so users can quickly narrow visible tasks by date window.

**Architecture:** Keep list selection and time filter state in `AppShell`, apply list filter first then time filter second, and render a small reusable filter bar in main content header. Date filtering logic lives in a dedicated utility module for deterministic behavior and easier testing. Use evidence-first debugging for date edge cases (timezone/day-boundary) before changing filter math.

**Tech Stack:** Next.js App Router, React client components, TypeScript, Prisma-backed Todo data, Tailwind CSS.

---

## Chunk 1: Scope Lock + Filter Semantics

### Task 1: Define filter contract and acceptance criteria

**Files:**
- Create: `docs/superpowers/plans/2026-03-21-time-filter-per-view.md` (this file, update sections)
- Reference: `src/components/AppShell.tsx`, `src/actions/todos.ts`

- [ ] **Step 1: Write failing behavior checklist (product-level)**

Add checklist in this plan for current missing behavior (all expected to fail before implementation):
- In `Important`, cannot filter to only `Today` tasks.
- In `Planned`, cannot filter to only `Next 7 days` tasks.
- In custom list, cannot filter `Overdue` tasks.

- [ ] **Step 2: Define exact filter options and matching rules**

Use MVP options:
- `all-dates`
- `overdue`
- `today`
- `tomorrow`
- `next-7-days`
- `no-date`

Matching rules:
- Date comparisons are local-day based (not raw timestamp).
- `overdue` excludes tasks due today.
- `next-7-days` includes today + next 6 days.
- `no-date` means `dueDate == null`.

- [ ] **Step 3: Define behavior for views without due dates**

Lock rule:
- Time filter applies to all views consistently.
- Views like `My Day` can return empty set if selected filter has no matching due-date pattern.

- [ ] **Step 4: Commit scope contract**

```bash
git add docs/superpowers/plans/2026-03-21-time-filter-per-view.md
git commit -m "docs: define per-view time filter semantics and acceptance criteria"
```

---

## Chunk 2: Date Filter Utility (TDD)

### Task 2: Implement reusable date-window predicate

**Files:**
- Create: `src/lib/timeFilter.ts`
- Create: `src/lib/timeFilter.test.ts`

- [ ] **Step 1: Write failing unit test for day-bucket matching**

Create tests for:
- overdue vs today boundary
- tomorrow match
- next-7-days inclusive behavior
- no-date behavior

Example test skeleton:

```ts
import { test } from "node:test";
import assert from "node:assert/strict";
import { matchesTimeFilter } from "./timeFilter";

test("today matches only local today", () => {
  const now = new Date("2026-03-21T10:00:00");
  const due = new Date("2026-03-21T23:30:00");
  assert.equal(matchesTimeFilter("today", due, now), true);
});
```

- [ ] **Step 2: Run test to verify failure**

Run:

```bash
node --test src/lib/timeFilter.test.ts
```

Expected: FAIL (missing module/function).

- [ ] **Step 3: Implement minimal utility**

In `src/lib/timeFilter.ts`, export:
- `type TimeFilter = "all-dates" | "overdue" | "today" | "tomorrow" | "next-7-days" | "no-date"`
- `matchesTimeFilter(filter, dueDate, now)`

Keep logic pure and side-effect free.

- [ ] **Step 4: Re-run tests to verify pass**

Run:

```bash
node --test src/lib/timeFilter.test.ts
```

Expected: PASS.

- [ ] **Step 5: Commit utility + tests**

```bash
git add src/lib/timeFilter.ts src/lib/timeFilter.test.ts
git commit -m "feat: add deterministic time filter utility"
```

---

## Chunk 3: UI Filter Control

### Task 3: Add reusable time filter bar component

**Files:**
- Create: `src/components/TimeFilterBar.tsx`
- Modify: `src/components/AppShell.tsx`

- [ ] **Step 1: Write failing UI checklist**

Manual failing checks before implementation:
- No date filter controls visible in header.
- Cannot switch date window while staying in same list.

- [ ] **Step 2: Implement `TimeFilterBar` component**

Render compact segmented buttons for all filter options.

Props:
- `value: TimeFilter`
- `onChange: (next: TimeFilter) => void`

- [ ] **Step 3: Integrate control in `AppShell` header**

Add `activeTimeFilter` state in `AppShell` and render `TimeFilterBar` below title/description.

- [ ] **Step 4: Verify UI interaction locally**

Run:

```bash
npm run dev
```

Expected:
- filter buttons render in every view
- selecting a button updates active visual state

- [ ] **Step 5: Commit UI changes**

```bash
git add src/components/TimeFilterBar.tsx src/components/AppShell.tsx
git commit -m "feat: add reusable time filter control in app header"
```

---

## Chunk 4: AppShell Filtering Integration

### Task 4: Apply list filter + time filter composition

**Files:**
- Modify: `src/components/AppShell.tsx`
- Modify: `src/components/TodoList.tsx` (only if typing changes needed)

- [ ] **Step 1: Write failing integration checklist**

Before code changes, verify these fail:
- `Important + Today` does not reduce list by due date.
- `All Tasks + Overdue` does not isolate overdue tasks.

- [ ] **Step 2: Compose filters in `useMemo`**

Implementation order in `AppShell`:
1. apply existing view/list filter (`myday`, `important`, `planned`, `all`, custom list)
2. apply `matchesTimeFilter(activeTimeFilter, t.dueDate, now)`

- [ ] **Step 3: Reset strategy on view switch**

MVP rule:
- Keep selected time filter when switching views (consistent cross-view exploration).

- [ ] **Step 4: Run build to verify TS and render integrity**

Run:

```bash
npm run build
```

Expected: PASS.

- [ ] **Step 5: Commit integration changes**

```bash
git add src/components/AppShell.tsx src/components/TodoList.tsx
git commit -m "feat: apply time filtering across all task views"
```

---

## Chunk 5: Verification, Debug Pass, and Docs

### Task 5: Validate edge cases and document feature

**Files:**
- Modify: `README.md`
- Modify: `AGENTS.md` (only if contributor workflow notes change)

- [ ] **Step 1: Run systematic-debugging edge-case checklist**

Verify with real data:
- overdue/today boundary at local midnight
- tasks with `dueDate = null` under each filter option
- planned list + no-date filter returns empty (expected)

- [ ] **Step 2: Run verification commands**

```bash
npm run build
npm run lint
```

Expected:
- build passes
- lint known scope issues only (no new feature-specific errors)

- [ ] **Step 3: Update feature docs**

Add to `README.md`:
- new time filter capability
- exact filter options and behavior notes.

- [ ] **Step 4: Commit docs + final polish**

```bash
git add README.md AGENTS.md
git commit -m "docs: add per-view time filter usage and behavior notes"
```

---

## Acceptance Gates

- Every view supports the same time filter options.
- Time filter behavior is deterministic and tested at day boundaries.
- Existing smart-list semantics (My Day / Important / Planned) remain intact.
- No regression in task creation, toggling, or detail panel behavior.

## Implementation Notes

- Keep filtering client-side in MVP (using already-fetched `todos`) to minimize DB/query complexity.
- If task volume grows later, move time filtering into `getTodos` query args as follow-up optimization.
