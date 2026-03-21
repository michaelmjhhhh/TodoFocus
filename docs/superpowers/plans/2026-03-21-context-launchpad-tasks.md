# Context Launchpad Tasks MVP Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a 1-2 week MVP that lets users attach launch resources (URL, file path, app/deep-link target) to a task and run them safely from desktop via Electron-only IPC.

**Architecture:** Store launch resources on each `Todo` as a normalized JSON string (`launchResources`) with strict validation in both renderer and Electron main process. Expose a minimal preload API (`launchAllForTask`) and implement all launch execution in Electron main using an allowlisted strategy (`url`, `file`, `app`) with explicit safety boundaries. Add a Task Detail editor for resource management and a `Launch All` action that executes valid resources sequentially and reports per-resource results without mutating task completion.

**Tech Stack:** Next.js App Router, React client components, Server Actions, Prisma + SQLite, Electron IPC/preload, Node test runner (`node:test`), Tailwind.

---

## Chunk 1: Scope, Contract, and Workflow Setup

### Task 1: Lock MVP behavior and start issue/branch workflow

**Files:**
- Modify: `docs/superpowers/plans/2026-03-21-context-launchpad-tasks.md`
- Reference: `AGENTS.md`

- [ ] **Step 1: Capture MVP scope boundaries (expected to fail in current app)**

Add explicit failing checklist in this plan:
- Task has no launch resource model.
- Task Detail has no launch resource management UI.
- Desktop app has no Electron-safe launch IPC.
- Web runtime can accidentally attempt unsupported launch behavior.

- [ ] **Step 2: Define launch resource contract (single source of truth)**

Document this exact shape and constraints:

```ts
type LaunchResourceType = "url" | "file" | "app";

type LaunchResource = {
  id: string; // cuid or nanoid
  type: LaunchResourceType;
  label: string; // 1..80 chars
  value: string; // URL or absolute path or app identifier/path
  createdAt: string; // ISO timestamp
};
```

Validation rules for MVP:
- `url`: allow only `https:` and `http:`.
- `file`: must be absolute path; reject traversal patterns and empty path.
- `app`: allow app bundle absolute path (`/Applications/X.app`) or known URI-style deep links (`obsidian://`, `notion://`, `raycast://`).
- Max resources per task: `12`.
- Max serialized payload length: `16_000` chars.

- [ ] **Step 3: Start issue -> branch workflow before implementation**

Run:

```bash
gh issue view <issue-number>
git checkout main && git pull
git checkout -b feat/context-launchpad-tasks-mvp-<issue-number>
```

Expected:
- Issue context is visible.
- Branch name clearly references feature + issue.

- [ ] **Step 4: Commit scope lock doc update**

```bash
git add docs/superpowers/plans/2026-03-21-context-launchpad-tasks.md
git commit -m "docs: lock context launchpad tasks MVP scope and contract"
```

---

## Chunk 2: Data Model and Server-Side Resource Serialization (TDD)

### Task 2: Add `launchResources` persistence and pure validation helpers

**Files:**
- Modify: `prisma/schema.prisma`
- Create: `prisma/migrations/<timestamp>_add_launch_resources_to_todo/migration.sql`
- Create: `src/lib/launchResources.ts`
- Create: `src/lib/launchResources.test.ts`
- Modify: `src/actions/todos.ts`
- Modify: `src/components/TodoList.tsx`
- Modify: `src/components/TaskDetail.tsx`

- [ ] **Step 1: Write failing unit tests for parser/validator/serializer**

Create `src/lib/launchResources.test.ts` with failing tests for:
- valid URL resource accepted,
- invalid protocol rejected,
- file path must be absolute,
- task payload trims to max count,
- malformed JSON returns safe empty array.

Example skeleton:

```ts
import test from "node:test";
import assert from "node:assert/strict";
import { parseLaunchResources, validateLaunchResource } from "./launchResources";

test("rejects javascript protocol", () => {
  const result = validateLaunchResource({ type: "url", label: "bad", value: "javascript:alert(1)" });
  assert.equal(result.ok, false);
});
```

- [ ] **Step 2: Run tests to verify failure first**

Run:

```bash
node --test src/lib/launchResources.test.ts
```

Expected: FAIL with missing module/functions.

- [ ] **Step 3: Implement minimal helper module to satisfy tests**

In `src/lib/launchResources.ts`, implement:

```ts
export function parseLaunchResources(raw: string | null | undefined): LaunchResource[];
export function serializeLaunchResources(items: LaunchResource[]): string;
export function validateLaunchResource(input: Partial<LaunchResource>):
  | { ok: true; value: LaunchResource }
  | { ok: false; error: string };
```

Implementation constraints:
- pure functions only,
- deterministic trimming/sanitization,
- no filesystem/network calls in this module.

- [ ] **Step 4: Add DB field and migration**

Schema change in `Todo`:

```prisma
launchResources String @default("[]")
```

Generate migration and verify SQL is additive only.

Run:

```bash
npx prisma migrate dev --name add_launch_resources_to_todo
```

Expected:
- migration folder created,
- `ALTER TABLE "Todo" ADD COLUMN "launchResources" TEXT NOT NULL DEFAULT '[]';` present.

- [ ] **Step 5: Wire server actions + view types for new field**

In `src/actions/todos.ts` and type consumers:
- include `launchResources` in read/write paths,
- parse + validate before save,
- reject invalid payload with safe no-op or typed error return,
- keep existing todo creation/edit behavior unchanged when resources omitted.

- [ ] **Step 6: Re-run tests and sanity checks**

Run:

```bash
node --test src/lib/launchResources.test.ts
npm run build
```

Expected: PASS.

- [ ] **Step 7: Commit model + helper + action integration**

```bash
git add prisma/schema.prisma prisma/migrations src/lib/launchResources.ts src/lib/launchResources.test.ts src/actions/todos.ts src/components/TodoList.tsx src/components/TaskDetail.tsx
git commit -m "feat: add task launch resource model and validation helpers"
```

---

## Chunk 3: Electron-Safe Launch APIs (IPC + Preload + Main Safety)

### Task 3: Implement secure desktop launch pipeline with strict boundaries

**Files:**
- Modify: `electron/main.js`
- Modify: `electron/preload.js`
- Create: `electron/launchpad.js`
- Create: `electron/launchpad.test.js`
- Modify: `src/app/page.tsx`
- Create: `src/types/electron.d.ts`

- [ ] **Step 1: Write failing Electron launch tests (TDD-first for pure/safe units)**

Create `electron/launchpad.test.js` covering:
- `sanitizeUrl` accepts `https://example.com` and rejects `javascript:`.
- `sanitizeFilePath` accepts absolute path and rejects relative traversal.
- `sanitizeAppTarget` accepts `/Applications/Slack.app` and `obsidian://open?...`.
- `launchAll` skips invalid resources and returns per-item result summary.

Example skeleton:

```js
test("launchAll rejects dangerous URL protocol", async () => {
  const result = await launchAll([{ type: "url", value: "javascript:alert(1)", label: "x", id: "1", createdAt: new Date().toISOString() }], deps);
  assert.equal(result.results[0].status, "rejected");
});
```

- [ ] **Step 2: Run failing tests**

Run:

```bash
node --test electron/launchpad.test.js
```

Expected: FAIL before implementation.

- [ ] **Step 3: Implement main-process launch module with dependency injection**

In `electron/launchpad.js` implement:

```js
function validateResource(resource) { /* strict runtime validation */ }
async function launchOne(resource, deps) { /* shell.openExternal / shell.openPath */ }
async function launchAll(resources, deps) { /* sequential, bounded, aggregated result */ }
module.exports = { validateResource, launchAll };
```

Safety boundaries:
- never execute arbitrary shell commands,
- no `child_process.exec` in MVP,
- no renderer-trusted input without revalidation,
- cap launched item count to `12` even if renderer sends more.

- [ ] **Step 4: Register IPC handler in `electron/main.js`**

Add:
- `ipcMain.handle("launchpad:launch-all", async (_event, payload) => ...)`
- resolve task resources from payload only after validation.
- return structured response:

```ts
type LaunchAllResult = {
  ok: boolean;
  launchedCount: number;
  results: Array<{ id: string; status: "launched" | "rejected" | "failed"; reason?: string }>;
};
```

- [ ] **Step 5: Expose minimal preload API and type declarations**

In `electron/preload.js`:

```js
contextBridge.exposeInMainWorld("electronAPI", {
  isElectron: true,
  platform: process.platform,
  launchAllForTask: (resources) => ipcRenderer.invoke("launchpad:launch-all", { resources }),
});
```

In `src/types/electron.d.ts` declare `window.electronAPI` for TS-safe renderer calls.

- [ ] **Step 6: Re-run tests and desktop compile checks**

Run:

```bash
node --test electron/launchpad.test.js electron/database.test.js
npm run build
```

Expected: PASS.

- [ ] **Step 7: Commit Electron launch pipeline**

```bash
git add electron/main.js electron/preload.js electron/launchpad.js electron/launchpad.test.js src/types/electron.d.ts src/app/page.tsx
git commit -m "feat: add electron-safe launch IPC and preload API"
```

---

## Chunk 4: Task Detail Launchpad UI + Launch All Behavior

### Task 4: Build resource manager UI and deterministic Launch All UX

**Files:**
- Modify: `src/components/TaskDetail.tsx`
- Create: `src/components/LaunchResourceEditor.tsx`
- Modify: `src/components/TodoItem.tsx`
- Modify: `src/actions/todos.ts`
- Create: `src/lib/launchAllClient.ts`
- Create: `src/lib/launchAllClient.test.ts`

- [ ] **Step 1: Write failing client-side tests for Launch All orchestrator**

In `src/lib/launchAllClient.test.ts` test:
- non-Electron runtime returns graceful unsupported result,
- valid payload calls `window.electronAPI.launchAllForTask`,
- empty resources returns early no-op,
- response mapping preserves per-resource statuses.

- [ ] **Step 2: Run tests to confirm fail-first**

Run:

```bash
node --test src/lib/launchAllClient.test.ts
```

Expected: FAIL before utility exists.

- [ ] **Step 3: Implement `launchAllClient` utility**

Implement:

```ts
export async function launchAllForTask(resources: LaunchResource[]): Promise<LaunchAllResult | { ok: false; reason: string }>;
```

Rules:
- if `window.electronAPI?.launchAllForTask` missing, return `{ ok: false, reason: "desktop-only" }`.
- do not throw for expected validation failures; return structured result.

- [ ] **Step 4: Build Launch Resource management UI in Task Detail**

UI requirements (MVP):
- add `Launch resources` section in `TaskDetail`.
- add/edit/remove rows with fields: type, label, value.
- inline validation messages before save.
- save through existing `updateTodo` action (`launchResources` payload).
- show desktop-only helper text when not in Electron.

- [ ] **Step 5: Add `Launch All` button behavior in Task Detail**

Behavior contract:
- button visible when task has >=1 resource.
- click launches resources sequentially through preload API.
- disable button while launching; prevent double-submit.
- show result summary (`3 launched, 1 rejected`) inline in panel.
- failure of one resource does not block others.

- [ ] **Step 6: Add lightweight metadata indicator in task rows**

In `src/components/TodoItem.tsx`, show launchpad badge/count (e.g., `Launch x3`) when resources exist.

- [ ] **Step 7: Re-run targeted tests and local UX check**

Run:

```bash
node --test src/lib/launchAllClient.test.ts src/lib/launchResources.test.ts
npm run dev
```

Manual expected:
- resources editable in Task Detail,
- Launch All executes only in Electron runtime,
- no regressions to notes, due date, recurrence, steps.

- [ ] **Step 8: Commit UI + client launch orchestration**

```bash
git add src/components/TaskDetail.tsx src/components/LaunchResourceEditor.tsx src/components/TodoItem.tsx src/actions/todos.ts src/lib/launchAllClient.ts src/lib/launchAllClient.test.ts
git commit -m "feat: add task detail launch resource manager and launch all action"
```

---

## Chunk 5: Integration Verification, Desktop Runtime Checks, and PR Readiness

### Task 5: Validate end-to-end MVP and prepare merge artifacts

**Files:**
- Modify: `README.md`
- Modify: `AGENTS.md` (only if contributor workflow notes need launchpad-specific additions)
- Modify: `docs/superpowers/plans/2026-03-21-context-launchpad-tasks.md` (checklist completion)

- [ ] **Step 1: Run full test/build/lint verification**

Run:

```bash
node --test src/lib/launchResources.test.ts src/lib/launchAllClient.test.ts electron/launchpad.test.js electron/database.test.js
npm run lint
npm run build
```

Expected:
- all new tests pass,
- no new lint errors,
- production build succeeds.

- [ ] **Step 2: Verify desktop runtime behavior (`electron:dev`)**

Run:

```bash
npm run electron:dev
```

Manual verification matrix:
- URL resource (`https://...`) opens in system browser.
- File resource opens with default OS app.
- App/deep-link resource launches target app/link handler.
- invalid resource is rejected with clear status, app remains stable.
- Launch All remains non-destructive (does not complete/delete task).

- [ ] **Step 3: Run packaged desktop safety checks for MVP readiness**

Run:

```bash
npm run build:electron:assets
npm run electron:rebuild-native
npm run sync:standalone:native
CSC_IDENTITY_AUTO_DISCOVERY=false npx electron-builder --mac dir --publish never
npm run verify:electron:abi
npm run verify:electron:smoke
```

Expected:
- packaged app starts,
- migrations apply including `launchResources`,
- Launch All works in packaged runtime with same safety behavior.

- [ ] **Step 4: Update docs for user behavior and safety boundaries**

In `README.md`, document:
- how to add launch resources,
- supported types and validation limits,
- desktop-only execution behavior,
- known MVP limitations (no background retry queue, no custom command execution).

- [ ] **Step 5: Prepare PR from issue branch with evidence**

Run:

```bash
git status
git log --oneline -n 10
gh pr create --title "feat: context launchpad tasks MVP" --body "$(cat <<'EOF'
## Summary
- add launch resources to tasks and task detail management UI
- add Electron-safe Launch All IPC/preload flow with strict validation
- add TDD coverage for launch resource parsing and desktop launch safety

## Verification
- node --test src/lib/launchResources.test.ts src/lib/launchAllClient.test.ts electron/launchpad.test.js electron/database.test.js
- npm run lint
- npm run build
- npm run electron:dev manual matrix completed
EOF
)"
```

- [ ] **Step 6: Commit docs/final polish**

```bash
git add README.md AGENTS.md docs/superpowers/plans/2026-03-21-context-launchpad-tasks.md
git commit -m "docs: add context launchpad usage and desktop verification workflow"
```

---

## Acceptance Gates

- Electron launch execution is only reachable through preload IPC and never through renderer direct shell access.
- Validation and safety checks run in both renderer (UX feedback) and main process (authoritative enforcement).
- `Todo` launch resources persist safely with additive migration and no break to existing tasks.
- Task Detail supports add/edit/delete of launch resources and deterministic `Launch All` results.
- URL/file/app safety boundaries are enforced and tested.
- Desktop runtime verification passes in both dev (`electron:dev`) and packaged smoke path.

## Out of Scope (MVP)

- Arbitrary shell commands or terminal scripts.
- Per-resource scheduling/automation triggers.
- Cross-task bulk launch from list views.
- Cloud sync/conflict resolution for launch resource metadata.

## Suggested Timeline (1-2 Weeks)

- Days 1-2: Chunk 1-2 (contract + model + helpers + migration).
- Days 3-5: Chunk 3 (IPC/preload/main launch safety + tests).
- Days 6-8: Chunk 4 (Task Detail resource UX + Launch All behavior).
- Days 9-10: Chunk 5 (desktop verification, docs, PR finalization).

Plan complete and saved to `docs/superpowers/plans/2026-03-21-context-launchpad-tasks.md`. Ready to execute?
