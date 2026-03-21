# Electron Exec Indicator Investigation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Explain and resolve the persistent "exec" activity indicator next to TodoFocus by identifying whether it is expected Electron child-process behavior or a process lifecycle bug.

**Architecture:** Treat this as a process-lifecycle debugging task. First capture concrete process evidence while app is running, then map expected vs actual process tree for Electron + Next standalone, then implement the minimal change that removes noisy/incorrect indicator behavior without regressing startup, styling, or DB migration.

**Tech Stack:** Electron main process, Node child_process spawn model, Next.js standalone server, macOS process inspector tools (`ps`, `pgrep`, `lsof`).

---

### Task 1: Reproduce and Capture Process Evidence

**Files:**
- Create/Update notes: `docs/superpowers/plans/2026-03-21-electron-exec-indicator-investigation.md`

- [x] **Step 1: Launch packaged app from clean state**

Run:
`pkill -f "TodoFocus.app/Contents/MacOS/TodoFocus" || true`
`open "dist-electron/mac-arm64/TodoFocus.app"`

Expected: app runs and indicator can be observed.

- [x] **Step 2: Snapshot process tree for TodoFocus**

Run:
`ps -axo pid,ppid,comm,args | rg -i "TodoFocus|ELECTRON_RUN_AS_NODE|standalone/server\.js|child_process|exec"`

Expected: capture exact parent/child relationships and command lines.

- [x] **Step 3: Confirm port owner and runtime role**

Run:
`lsof -iTCP -sTCP:LISTEN -nP | rg "TodoFocus|127\.0\.0\.1"`

Expected: identify which PID is serving local HTTP.

- [x] **Step 4: Record findings in this plan under "Evidence"**

Expected: explicit statement whether "exec" is (a) this app's child process, (b) shell/login artifact, or (c) unrelated system process.

### Task 2: Define Root Cause and Decision

**Files:**
- Update: `docs/superpowers/plans/2026-03-21-electron-exec-indicator-investigation.md`

- [x] **Step 1: Document root-cause hypothesis**

Write one clear hypothesis in the plan:
- why the indicator appears,
- why it persists,
- whether behavior is expected or buggy.

- [x] **Step 2: Define acceptance criteria for fix/no-fix decision**

Add checklist:
- no misleading extra process indicator,
- app window appears reliably,
- internal server still starts,
- first-run migration still succeeds.

- [x] **Step 3: Choose one strategy**

Document exactly one chosen strategy:
1) Keep child process but adjust spawn method/options and cleanup lifecycle, or
2) Run server in-process and remove child process entirely, or
3) Keep as-is and document as expected behavior if truly benign.

### Task 3: Implement Minimal Fix (only after Task 2 evidence)

**Files:**
- Modify: `electron/main.js`
- Optional docs: `README.md`, `AGENTS.md`

- [x] **Step 1: Write failing verification script/checklist**

Create command checklist in plan for pre-fix failure signal (indicator/process artifact present).

- [x] **Step 2: Apply minimal code change in `electron/main.js`**

Limit scope strictly to process lifecycle/startup strategy selected in Task 2.

- [x] **Step 3: Verify app behavior after change**

Run:
`npm run build && npm run build:electron:assets && CSC_IDENTITY_AUTO_DISCOVERY=false npx electron-builder --mac dir --publish never`
`open "dist-electron/mac-arm64/TodoFocus.app"`

Verify:
- no misleading "exec" indicator issue,
- window shows,
- CSS loads,
- DB migration works.

- [x] **Step 4: Update docs only if behavior contract changed**

If process model changes, update docs section in `README.md` and `AGENTS.md`.

- [ ] **Step 5: Commit fix**

```bash
git add electron/main.js README.md AGENTS.md docs/superpowers/plans/2026-03-21-electron-exec-indicator-investigation.md
git commit -m "fix: resolve TodoFocus exec process indicator behavior"
```

---

## Evidence

- Pre-fix packaged launch command used:
  - `pkill -f "TodoFocus.app/Contents/MacOS/TodoFocus" || true`
  - `open "dist-electron/mac-arm64/TodoFocus.app"`
- Pre-fix process snapshot showed an Electron-spawned standalone server child:
  - Parent: `TodoFocus` PID `99618`
  - Child: PID `99625` command `TodoFocus .../.next/standalone/server.js`
  - Utility/GPU helpers were also present and expected.
- Port ownership evidence:
  - `lsof -Pan -p 99625 -iTCP -sTCP:LISTEN` -> `TodoFocus 99625 ... TCP 127.0.0.1:3000 (LISTEN)`
- Interpretation:
  - The observed extra process tied to TodoFocus is the app's own spawned Next standalone runtime (not a random unrelated daemon).
  - The separate `/usr/bin/login ... exec -l /bin/zsh` line comes from shell session bootstrap and is unrelated to TodoFocus lifecycle.

## Root-Cause Hypothesis

- The persistent/jumping "exec" indicator is caused by the explicit `child_process.spawn(process.execPath, [serverPath], ...)` model in `electron/main.js`.
- Because the internal Next server is launched as a separate child process, macOS can surface additional process activity that users interpret as a suspicious "exec" companion.
- This is functionally valid but UX-noisy for a desktop app expected to appear as a single cohesive process.

## Decision Acceptance Criteria

- [x] No misleading extra process indicator attributable to app-owned standalone server child.
- [x] App window appears reliably.
- [x] Internal server still starts and serves UI.
- [x] First-run migration path still succeeds.

## Chosen Strategy

- Strategy selected: **(2) Run server in-process and remove child process entirely.**
- Rationale: smallest behavioral change that directly removes the extra app-owned child process while preserving existing standalone server code path and migration flow.

## Pre-Fix Failing Verification Checklist

Run while packaged app is open:

1. `ps -axo pid,ppid,comm,args | rg -i "TodoFocus|standalone/server\.js"`
2. `lsof -iTCP -sTCP:LISTEN -nP | rg "TodoFocus|127\.0\.0\.1"`

Failure signal (pre-fix):

- A dedicated child process under `TodoFocus` is running `.../.next/standalone/server.js` and owning the localhost listener.

## Post-Fix Verification Results

- Build/package verification command completed:
  - `npm run build && npm run build:electron:assets && CSC_IDENTITY_AUTO_DISCOVERY=false npx electron-builder --mac dir --publish never`
- Process model after fix (`open dist-electron/mac-arm64/TodoFocus.app` + `ps`/`lsof`):
  - No separate `.../standalone/server.js` child process appears under TodoFocus.
  - Main app process is now `next-server (v16.2.0)` and directly owns `127.0.0.1:3000` listener.
- Runtime endpoint checks:
  - `GET /` status `200`
  - CSS asset discovered from HTML and fetched with status `200`
- Migration/data checks:
  - DB exists at `~/Library/Application Support/todofocus/todofocus.db`
  - Required tables found: `List`, `Todo`, `Step`, `_zen_migrations`
- Conclusion:
  - The extra app-owned standalone child process artifact is removed while startup, styling, and migration behavior remain intact.

## Acceptance Gates

- The "exec" indicator cause is explained with evidence (not guesswork).
- Final behavior is intentional and documented.
- No regression to startup, styling, or local migration flow.
