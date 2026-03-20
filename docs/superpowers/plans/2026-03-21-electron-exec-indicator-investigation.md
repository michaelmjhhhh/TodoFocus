# Electron Exec Indicator Investigation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Explain and resolve the persistent "exec" activity indicator next to TodoFocus by identifying whether it is expected Electron child-process behavior or a process lifecycle bug.

**Architecture:** Treat this as a process-lifecycle debugging task. First capture concrete process evidence while app is running, then map expected vs actual process tree for Electron + Next standalone, then implement the minimal change that removes noisy/incorrect indicator behavior without regressing startup, styling, or DB migration.

**Tech Stack:** Electron main process, Node child_process spawn model, Next.js standalone server, macOS process inspector tools (`ps`, `pgrep`, `lsof`).

---

### Task 1: Reproduce and Capture Process Evidence

**Files:**
- Create/Update notes: `docs/superpowers/plans/2026-03-21-electron-exec-indicator-investigation.md`

- [ ] **Step 1: Launch packaged app from clean state**

Run:
`pkill -f "TodoFocus.app/Contents/MacOS/TodoFocus" || true`
`open "dist-electron/mac-arm64/TodoFocus.app"`

Expected: app runs and indicator can be observed.

- [ ] **Step 2: Snapshot process tree for TodoFocus**

Run:
`ps -axo pid,ppid,comm,args | rg -i "TodoFocus|ELECTRON_RUN_AS_NODE|standalone/server\.js|child_process|exec"`

Expected: capture exact parent/child relationships and command lines.

- [ ] **Step 3: Confirm port owner and runtime role**

Run:
`lsof -iTCP -sTCP:LISTEN -nP | rg "TodoFocus|127\.0\.0\.1"`

Expected: identify which PID is serving local HTTP.

- [ ] **Step 4: Record findings in this plan under "Evidence"**

Expected: explicit statement whether "exec" is (a) this app's child process, (b) shell/login artifact, or (c) unrelated system process.

### Task 2: Define Root Cause and Decision

**Files:**
- Update: `docs/superpowers/plans/2026-03-21-electron-exec-indicator-investigation.md`

- [ ] **Step 1: Document root-cause hypothesis**

Write one clear hypothesis in the plan:
- why the indicator appears,
- why it persists,
- whether behavior is expected or buggy.

- [ ] **Step 2: Define acceptance criteria for fix/no-fix decision**

Add checklist:
- no misleading extra process indicator,
- app window appears reliably,
- internal server still starts,
- first-run migration still succeeds.

- [ ] **Step 3: Choose one strategy**

Document exactly one chosen strategy:
1) Keep child process but adjust spawn method/options and cleanup lifecycle, or
2) Run server in-process and remove child process entirely, or
3) Keep as-is and document as expected behavior if truly benign.

### Task 3: Implement Minimal Fix (only after Task 2 evidence)

**Files:**
- Modify: `electron/main.js`
- Optional docs: `README.md`, `AGENTS.md`

- [ ] **Step 1: Write failing verification script/checklist**

Create command checklist in plan for pre-fix failure signal (indicator/process artifact present).

- [ ] **Step 2: Apply minimal code change in `electron/main.js`**

Limit scope strictly to process lifecycle/startup strategy selected in Task 2.

- [ ] **Step 3: Verify app behavior after change**

Run:
`npm run build && npm run build:electron:assets && CSC_IDENTITY_AUTO_DISCOVERY=false npx electron-builder --mac dir --publish never`
`open "dist-electron/mac-arm64/TodoFocus.app"`

Verify:
- no misleading "exec" indicator issue,
- window shows,
- CSS loads,
- DB migration works.

- [ ] **Step 4: Update docs only if behavior contract changed**

If process model changes, update docs section in `README.md` and `AGENTS.md`.

- [ ] **Step 5: Commit fix**

```bash
git add electron/main.js README.md AGENTS.md docs/superpowers/plans/2026-03-21-electron-exec-indicator-investigation.md
git commit -m "fix: resolve TodoFocus exec process indicator behavior"
```

---

## Evidence

- To be filled during Task 1 with concrete process snapshots and interpretation.

## Acceptance Gates

- The "exec" indicator cause is explained with evidence (not guesswork).
- Final behavior is intentional and documented.
- No regression to startup, styling, or local migration flow.
