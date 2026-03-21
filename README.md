# TodoFocus

Local-first desktop todo app for focused execution, not just list keeping.

TodoFocus combines familiar task management with a launch-oriented workflow:
- capture and organize tasks quickly
- filter by time per view
- open the exact work context (URLs, files, apps) from each task

## Why TodoFocus

Most todo apps stop at "remember this." TodoFocus helps you "start now."

- Local-first by default (SQLite, no account required)
- Fast desktop workflow with Electron + native pickers
- Context Launchpad Tasks: one task can launch all related resources
- Clean focus-oriented UI with animated interactions

## What Makes It Different

1. Context Launchpad Tasks
   - Attach `url`, `file`, and `app` resources to a task
   - Click `Launch All` to open your work context instantly
2. Per-view Time Filters
   - Apply date windows in every view (`Overdue`, `Today`, `Tomorrow`, `Next 7 days`, `No date`)
3. Local-first Desktop Runtime
   - Data lives on your machine
   - Native desktop interactions (file/app picker, launch actions)

## Features

- **My Day / Important / Planned** -- smart lists that filter automatically
- **Smart-list quick add** -- adding inside Important/Planned now preserves the list intent automatically
- **Per-view time filters** -- filter any list by `Overdue`, `Today`, `Tomorrow`, `Next 7 days`, or `No date`
- **Custom lists** -- create, rename, delete with color coding
- **Subtasks (Steps)** -- break tasks into smaller pieces
- **Due dates** -- with relative display (Today, Tomorrow, Overdue)
- **Notes** -- per-task free-text notes with auto-save
- **Context Launchpad Tasks (MVP)** -- attach `URL`, `File`, and `App` resources to a task and launch all in one click
- **Native file/app pickers** -- pick launch targets from desktop dialogs instead of manually typing paths
- **Resizable detail panel** -- drag to widen/narrow right panel for long resource values
- **Dark / Light theme** -- toggle with persistence, dark by default
- **Smooth animations** -- Framer Motion layout transitions throughout
- **Local SQLite** -- all data stays on your machine, zero cloud dependency

## Screens and UX

- Three-panel app shell (lists, tasks, detail)
- Resizable detail panel for dense task metadata
- Native file/app picker buttons for launch resources
- Smooth task/list transitions with Framer Motion

## Quick Start

```bash
git clone https://github.com/michaelmjhhhh/TodoFocus.git
cd TodoFocus
npm install
npm run setup
npm run dev
```

Open [http://localhost:3000](http://localhost:3000).

That's it. The `setup` script copies `.env.example` to `.env`, runs the database migration, and generates the Prisma client. The SQLite database file (`dev.db`) is created in the project root.

If Prisma client files are missing (e.g. in fresh CI/workspaces), run:

```bash
npm run prisma:generate
```

For desktop behavior (launch resources, native pickers), use:

```bash
npm run electron:dev
```

## Requirements

- **Node.js** >= 18
- **npm** >= 9

No external database needed. No API keys. No accounts.

## Tech Stack

| Layer | Tech |
|-------|------|
| Framework | Next.js 16 (App Router, Server Actions) |
| Styling | Tailwind CSS v4 |
| Animation | Framer Motion |
| Database | SQLite via Prisma v7 + better-sqlite3 |
| Icons | Lucide React |
| Font | Inter (via next/font) |

## Project Structure

```
src/
  app/
    globals.css        # Design tokens, dark/light theme
    layout.tsx         # Root layout with ThemeProvider
    page.tsx           # Server component, data fetching
  actions/
    todos.ts           # Server actions (all CRUD)
  components/
    AppShell.tsx        # 3-panel layout orchestrator
    Sidebar.tsx         # Navigation (smart + custom lists)
    TodoInput.tsx       # Task creation input
    TodoList.tsx        # Animated task list
    TodoItem.tsx        # Individual task row
    TaskDetail.tsx      # Right panel (steps, notes, due date)
    LaunchResourceEditor.tsx # Launch resource management UI
    ThemeProvider.tsx    # Dark/light theme context
    ThemeToggle.tsx     # Theme switch button
  lib/
    cn.ts              # clsx + tailwind-merge utility
    db.ts              # Prisma client singleton
    launchResources.ts # Launch resource validation/serialization
    launchAllClient.ts # Renderer launch orchestration
electron/
  main.js              # App bootstrap, secure IPC handlers
  preload.js           # Safe API bridge to renderer
  launchpad.js         # Launch resource runtime validation + launch logic
prisma/
  schema.prisma        # Data model (Todo, List, Step)
```

## Development

```bash
npm run dev            # Start dev server (localhost:3000)
npm run build          # Production build
npm run lint           # ESLint
npx prisma studio      # Browse database in browser
```

## Delivery Workflow

- For bugs, follow evidence-first debugging (root cause before code changes).
- For new features, we use: `issue -> branch -> implement -> PR`.
- Prefer a short implementation plan for non-trivial features before coding.

## Open Source Notes

- License: MIT
- Contributions: Issues and PRs are welcome
- Security baseline: launch actions are IPC-based and validated in Electron main process

## Desktop Packaging (Electron)

### Build rules we follow

- Use **Next standalone output** only for packaging.
- Keep `asar` enabled for smaller artifacts and faster distribution.
- Unpack only native runtime files (`*.node`, `better-sqlite3`) via `asarUnpack`.
- Include Prisma SQL migrations in the packaged app (`prisma/migrations/**/*`).
- Rebuild native dependencies for Electron target before release packaging:
  - `npx electron-builder install-app-deps`
- Sync rebuilt native binary into standalone output before packaging:
  - `npm run sync:standalone:native`
- Gate release uploads on:
  - ABI check (`npm run verify:electron:abi`)
  - Smoke check (`npm run verify:electron:smoke`)
- Before packaging, copy static assets into standalone:
  - `.next/static` -> `.next/standalone/.next/static`
  - `public` -> `.next/standalone/public`

These rules are encoded in `package.json` scripts and `electron-builder.json`.

### Commands

```bash
# Full build (mac targets configured in electron-builder)
npm run electron:build

# Fast local validation build (no full release workflow)
npm run build
npm run build:electron:assets
CSC_IDENTITY_AUTO_DISCOVERY=false npx electron-builder --mac dir --publish never

# CI-equivalent guarded local packaging
npm run electron:ci:package
```

### CI Release (Required, CI-first)

Release artifacts should come from GitHub Actions workflow `release-macos`.
Do not manually upload local DMG/ZIP files unless CI is unavailable and maintainers approve an emergency fallback.

1. Start from clean, updated `main`:
   - `git checkout main && git pull`
2. Create and push the release tag:
   - `git tag vX.Y.Z`
   - `git push origin vX.Y.Z`
3. Trigger release workflow for that tag:
   - `gh workflow run release-macos -f tag=vX.Y.Z`
4. Monitor the run:
   - `gh run list --workflow release-macos --limit 5`
   - `gh run watch <run-id>`
5. Verify assets on the release page:
   - `gh release view vX.Y.Z --json assets,url`
   - Confirm expected files are attached (typically macOS `.dmg` and `.zip`).

### If Workflow Fails (Retry / Rollback)

1. Inspect logs: `gh run view <run-id> --log`.
2. Retry workflow for transient failures (runner/network/signing issues).
3. If assets are bad, remove only broken assets and rerun:
   - `gh release delete-asset vX.Y.Z <asset-name> -y`
4. If tag was incorrect, recreate it:
   - `git tag -d vX.Y.Z`
   - `git push origin :refs/tags/vX.Y.Z`
   - Create correct tag and run `release-macos` again.

### Quick DMG creation (fast path)

When `dist-electron/mac-arm64/TodoFocus.app` already exists and works, create/replace a DMG directly:

```bash
hdiutil create -volname "TodoFocus" \
  -srcfolder "dist-electron/mac-arm64/TodoFocus.app" \
  -ov -format UDZO "dist-electron/TodoFocus-mac-arm64.dmg"
```

Use this local DMG path for validation or emergency-only release recovery, not as the normal release path.

### Runtime and local data

- App starts the Next.js standalone server in-process from `.next/standalone/server.js` (no separate spawned server child).
- On first launch, SQL migrations from `prisma/migrations` are applied automatically.
- Local database path on macOS:
  - `~/Library/Application Support/todofocus/todofocus.db`

### Launchpad Safety Model

- Launch actions are handled in Electron main process via IPC, not by executing shell commands.
- Resource payloads are validated in both renderer and main process before launch.
- External window opening is protocol-restricted (allowlisted) and top-level navigation is guarded.

### Common issue and fix

- If UI looks unstyled (plain HTML buttons/text), verify CSS endpoint is reachable from the app's internal port.
- Typical root cause is stale app process/port conflict; restart app after killing old processes.
- If packaged app fails with `better-sqlite3` `NODE_MODULE_VERSION` mismatch, rebuild Electron native deps (`npx electron-builder install-app-deps`) and repackage.
- If dev server fails with Prisma `P2022` missing column, apply local schema updates with `npx prisma migrate dev`.

## License

MIT
