# TodoFocus Electron Bundle Size Reduction Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reduce TodoFocus packaged app size beyond current ~700MB while preserving startup reliability, local SQLite migrations, and current UX.

**Architecture:** Keep Next.js standalone as the runtime entry, then remove duplicate payloads introduced by `asarUnpack` scope and broad file inclusion. Validate each size optimization with a reproducible build + launch smoke test + DB migration check, then regenerate release artifacts.

**Tech Stack:** Electron 35, electron-builder, Next.js standalone, Prisma migrations, better-sqlite3, macOS packaging (`hdiutil`).

---

### Task 1: Establish Baseline and Duplication Map

**Files:**
- Modify: `docs/superpowers/plans/2026-03-21-electron-bundle-size-reduction.md`
- Inspect: `electron-builder.json`, `dist-electron/mac-arm64/TodoFocus.app`

- [ ] **Step 1: Build the current baseline package**

Run: `npm run build && npm run build:electron:assets && CSC_IDENTITY_AUTO_DISCOVERY=false npx electron-builder --mac dir --publish never`
Expected: `dist-electron/mac-arm64/TodoFocus.app` is produced.

- [ ] **Step 2: Record bundle size breakdown**

Run:
`du -sh dist-electron/mac-arm64/TodoFocus.app`
`du -sh dist-electron/mac-arm64/TodoFocus.app/Contents/Resources/app.asar`
`du -sh dist-electron/mac-arm64/TodoFocus.app/Contents/Resources/app.asar.unpacked`

Expected: baseline numbers captured in this plan file under a new “Baseline Metrics” section.

- [ ] **Step 3: Identify duplicated directories**

Run:
`npx asar list dist-electron/mac-arm64/TodoFocus.app/Contents/Resources/app.asar | rg "^/\.next/standalone|^/node_modules"`
`ls -la dist-electron/mac-arm64/TodoFocus.app/Contents/Resources/app.asar.unpacked/.next/standalone`

Expected: exact duplication sources listed (for example standalone in both asar and unpacked).

- [ ] **Step 4: Commit baseline notes only (if added)**

```bash
git add docs/superpowers/plans/2026-03-21-electron-bundle-size-reduction.md
git commit -m "docs: record Electron bundle size baseline metrics"
```

### Task 2: Tighten Packaging Inputs and Unpack Scope

**Files:**
- Modify: `electron-builder.json`
- Verify: `electron/main.js`

- [ ] **Step 1: Write failing verification criteria (size + runtime)**

Add a short checklist section in plan named “Acceptance Gates”:
- App size target (e.g. below current baseline by at least 20%)
- Launch success gate
- Migration success gate

- [ ] **Step 2: Minimize `files` and `asarUnpack` entries**

Update `electron-builder.json` to avoid unpacking large trees when only native binaries are required.

Rules:
- Keep `asar: true`
- Keep unpack to native runtime necessities (`*.node`, `better-sqlite3` native payload)
- Avoid whole `.next/standalone/**` in `asarUnpack` unless strictly required by verified startup behavior

- [ ] **Step 3: Ensure `electron/main.js` resolves runtime server path consistently**

Validate server entry path matches actual packaged location after Task 2 Step 2.

- [ ] **Step 4: Commit packaging config update**

```bash
git add electron-builder.json electron/main.js
git commit -m "build: reduce Electron payload by tightening asar unpack scope"
```

### Task 3: Verify Functionality After Size Optimization

**Files:**
- Verify artifact: `dist-electron/mac-arm64/TodoFocus.app`

- [ ] **Step 1: Rebuild optimized app**

Run: `rm -rf dist-electron && npm run build && npm run build:electron:assets && CSC_IDENTITY_AUTO_DISCOVERY=false npx electron-builder --mac dir --publish never`

- [ ] **Step 2: Validate startup behavior**

Run:
`open "dist-electron/mac-arm64/TodoFocus.app"`
`osascript -e 'tell application "System Events" to exists process "TodoFocus"'`

Expected: process exists and window renders with styles.

- [ ] **Step 3: Validate database migration behavior**

Run:
`rm -rf ~/Library/Application\ Support/todofocus`
`open "dist-electron/mac-arm64/TodoFocus.app"`
`sqlite3 ~/Library/Application\ Support/todofocus/todofocus.db ".tables"`

Expected: includes `List`, `Todo`, `Step`, `_zen_migrations`.

- [ ] **Step 4: Re-measure and compare size**

Run: `du -sh dist-electron/mac-arm64/TodoFocus.app`

Expected: meets acceptance gate and is recorded in plan under “Optimized Metrics”.

- [ ] **Step 5: Commit verification notes (if changed)**

```bash
git add docs/superpowers/plans/2026-03-21-electron-bundle-size-reduction.md
git commit -m "docs: capture post-optimization Electron size results"
```

### Task 4: Regenerate Release Artifact and Update Docs

**Files:**
- Modify: `README.md` (if command changes)
- Modify: `AGENTS.md` (if command changes)
- Generate: `dist-electron/TodoFocus-mac-arm64.dmg`

- [ ] **Step 1: Rebuild DMG from optimized app**

Run:
`hdiutil create -volname "TodoFocus" -srcfolder "dist-electron/mac-arm64/TodoFocus.app" -ov -format UDZO "dist-electron/TodoFocus-mac-arm64.dmg"`

- [ ] **Step 2: Confirm artifact size and launch**

Run:
`ls -lh dist-electron/TodoFocus-mac-arm64.dmg`
`open dist-electron/mac-arm64/TodoFocus.app`

- [ ] **Step 3: Keep docs aligned with real commands**

If build commands or caveats changed, update `README.md` and `AGENTS.md` packaging sections.

- [ ] **Step 4: Commit docs + build workflow update**

```bash
git add README.md AGENTS.md
git commit -m "docs: align packaging instructions with optimized Electron build"
```

### Task 5: Release Update

**Files:**
- Release asset: GitHub Release `v0.1.0`

- [ ] **Step 1: Replace existing release asset**

Run:
`gh release upload v0.1.0 dist-electron/TodoFocus-mac-arm64.dmg --clobber --repo michaelmjhhhh/TodoFocus`

- [ ] **Step 2: Verify release URL and asset listing**

Run:
`gh release view v0.1.0 --repo michaelmjhhhh/TodoFocus`

Expected: updated DMG is listed.

---

## Baseline Metrics

- Current app size baseline: ~700MB (to be re-measured each run).

## Acceptance Gates

- App size is materially reduced vs baseline (target >=20% reduction).
- App launches reliably without timeout/blank-window regressions.
- Local DB initialization and migrations still succeed on first launch.

## Note

- As requested by the product owner: _“能继续降，我已经把这个任务留作下一步（你刚说先不做），后续可再做一轮精简。”_  
  This plan formalizes that next optimization round.
