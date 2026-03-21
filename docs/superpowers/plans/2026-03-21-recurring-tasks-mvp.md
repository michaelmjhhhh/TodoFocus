# Recurring Tasks MVP Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a no-surprise recurring-task MVP that automatically carries tasks forward by schedule while preserving existing My Day / Important / Planned behavior.

**Architecture:** Extend the Todo data model with recurrence metadata and completion bookkeeping, then apply recurrence advancement in server actions where task completion is handled. Keep UX minimal in MVP: recurrence can be set in task detail and existing lists continue to work. Follow systematic debugging for known list-creation bug paths and recurrence edge cases before implementation.

**Tech Stack:** Next.js App Router, Server Actions, Prisma + SQLite, Electron runtime, Tailwind UI.

---

## Chunk 1: Scope Lock + Debug Evidence

### Task 1: Confirm recurring semantics and bug context

**Files:**
- Modify: `docs/superpowers/plans/2026-03-21-recurring-tasks-mvp.md`
- Reference: `src/actions/todos.ts`, `src/components/AppShell.tsx`, `src/components/TodoInput.tsx`

- [ ] **Step 1: Record bug root-cause evidence snapshot**

Document in this plan:
- why Important/Planned quick-add previously lost intended flags,
- where data dropped (form hidden fields -> server action parse -> create payload),
- what fix now exists.

- [ ] **Step 2: Lock recurring MVP behavior matrix**

Write explicit rules:
- Frequency options in MVP (e.g., daily / weekly / monthly).
- Completion behavior (complete recurring instance -> next due instance appears).
- What happens if due date missing.
- How recurrence interacts with Important/My Day/List placement.

- [ ] **Step 3: Add acceptance gates for recurrence + regression**

Add checklist:
- Important/Planned quick-add regression test.
- Recurrence advancement test.
- Non-recurring tasks unaffected.

- [ ] **Step 4: Commit plan scope update**

```bash
git add docs/superpowers/plans/2026-03-21-recurring-tasks-mvp.md
git commit -m "docs: define recurring task MVP behavior and debug acceptance gates"
```

---

## Chunk 2: Data Model + Migration

### Task 2: Add recurrence fields to Todo model

**Files:**
- Modify: `prisma/schema.prisma`
- Create: `prisma/migrations/<timestamp>_add_recurrence_fields/migration.sql`

- [ ] **Step 1: Write failing schema-level test case or checklist**

Create a reproducible check (SQL/Prisma query checklist) that fails before migration because recurrence fields do not exist.

- [ ] **Step 2: Add minimal recurrence columns to schema**

Add fields to `Todo` (MVP-safe):
- recurrence rule/frequency enum or string
- recurrence interval (default 1)
- recurrence anchor/nextDueAt as needed by chosen algorithm
- completedAt (for deterministic next-instance calculation)

- [ ] **Step 3: Generate migration SQL**

Run migration generation and verify SQL is additive, backward compatible, no destructive changes.

- [ ] **Step 4: Verify migration applies on clean and existing DB**

Run migration flow and validate app still starts.

- [ ] **Step 5: Commit schema + migration**

```bash
git add prisma/schema.prisma prisma/migrations
git commit -m "feat: add recurring task fields to todo schema"
```

---

## Chunk 3: Server Action Logic (TDD)

### Task 3: Implement recurrence advancement on completion

**Files:**
- Modify: `src/actions/todos.ts`
- Create/Modify Test: `src/actions/todos.recurrence.test.ts` (or closest existing test location)

- [ ] **Step 1: Write failing test for recurring completion flow**

Test should prove:
- completing recurring task advances next due instance correctly,
- original completion state is persisted as intended,
- no duplicate runaway creation.

- [ ] **Step 2: Write failing regression test for Important/Planned quick-add**

Cover form-driven add path to ensure smart-list context flags persist.

- [ ] **Step 3: Implement minimal recurrence helper + integration**

In `todos.ts`:
- isolate date calculation helper,
- call helper only for recurring tasks in completion path,
- keep non-recurring path unchanged.

- [ ] **Step 4: Run targeted tests and fix edge cases**

Run tests for recurrence + todo actions until green.

- [ ] **Step 5: Commit server logic + tests**

```bash
git add src/actions/todos.ts src/actions/todos.recurrence.test.ts
git commit -m "feat: advance recurring tasks when completing todos"
```

---

## Chunk 4: Minimal UI for Recurrence

### Task 4: Add recurrence controls in Task Detail

**Files:**
- Modify: `src/components/TaskDetail.tsx`
- Optional: `src/components/TodoItem.tsx` (small recurrence indicator)

- [ ] **Step 1: Add recurrence field UI (MVP-simple)**

Add a compact control in detail panel:
- None / Daily / Weekly / Monthly
- optional interval input only if needed by chosen model.

- [ ] **Step 2: Wire UI to update action**

Use existing `updateTodo` action payload extension for recurrence fields.

- [ ] **Step 3: Preserve current interaction quality**

No regressions to notes auto-save, due date editing, important/my day toggles.

- [ ] **Step 4: Commit UI updates**

```bash
git add src/components/TaskDetail.tsx src/components/TodoItem.tsx
git commit -m "feat: add recurring schedule controls to task detail"
```

---

## Chunk 5: End-to-End Verification + Docs + PR Readiness

### Task 5: Verify behavior and document workflow

**Files:**
- Modify: `README.md`
- Modify: `AGENTS.md`

- [ ] **Step 1: Run verification checklist**

Verify:
- Important quick-add creates `isImportant=true`.
- Planned quick-add creates planned semantics per MVP rule.
- Completing recurring task advances next scheduled item.
- Packaging startup and migration still pass for desktop flow.

- [ ] **Step 2: Update docs for recurrence behavior**

Document:
- how recurrence works in MVP,
- known limitations,
- how to test locally.

- [ ] **Step 3: Commit docs + final polish**

```bash
git add README.md AGENTS.md
git commit -m "docs: add recurring task MVP behavior and verification notes"
```

- [ ] **Step 4: Open/Update issue and prepare PR summary**

Include:
- problem statement,
- approach,
- migration notes,
- verification evidence.

---

## Acceptance Gates

- Root cause and regression for smart-list quick-add are explicitly covered.
- Recurrence logic is test-backed and deterministic.
- Existing non-recurring task behavior remains unchanged.
- SQLite migration is additive and safe on existing user data.
- Desktop startup/migration flow remains healthy after schema changes.

## Open Questions for Product Owner (Resolved before implementation)

- Should recurring completion create a new task row or mutate due date on same row?
- For monthly recurrence, how should day overflow be handled (e.g., Jan 31 -> Feb)?
- Should recurring tasks remain in My Day automatically after rollover?
- Should completed recurring instances remain visible in history and counts?
