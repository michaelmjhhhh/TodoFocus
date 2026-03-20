# TodoFocus

A mindful todo app. Dark by default. Local-first with SQLite.

Inspired by Microsoft Todo's feature set and Linear's aesthetic.

## Features

- **My Day / Important / Planned** -- smart lists that filter automatically
- **Custom lists** -- create, rename, delete with color coding
- **Subtasks (Steps)** -- break tasks into smaller pieces
- **Due dates** -- with relative display (Today, Tomorrow, Overdue)
- **Notes** -- per-task free-text notes with auto-save
- **Dark / Light theme** -- toggle with persistence, dark by default
- **Smooth animations** -- Framer Motion layout transitions throughout
- **Local SQLite** -- all data stays on your machine, zero cloud dependency

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
    ThemeProvider.tsx    # Dark/light theme context
    ThemeToggle.tsx     # Theme switch button
  lib/
    cn.ts              # clsx + tailwind-merge utility
    db.ts              # Prisma client singleton
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

## Desktop Packaging (Electron)

### Build rules we follow

- Use **Next standalone output** only for packaging.
- Keep `asar` enabled for smaller artifacts and faster distribution.
- Unpack only native runtime files (`*.node`, `better-sqlite3`) via `asarUnpack`.
- Include Prisma SQL migrations in the packaged app (`prisma/migrations/**/*`).
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
```

### Quick DMG creation (fast path)

When `dist-electron/mac-arm64/TodoFocus.app` already exists and works, create/replace a DMG directly:

```bash
hdiutil create -volname "TodoFocus" \
  -srcfolder "dist-electron/mac-arm64/TodoFocus.app" \
  -ov -format UDZO "dist-electron/TodoFocus-mac-arm64.dmg"
```

### Runtime and local data

- App starts an internal Next.js server from `.next/standalone/server.js`.
- On first launch, SQL migrations from `prisma/migrations` are applied automatically.
- Local database path on macOS:
  - `~/Library/Application Support/todofocus/todofocus.db`

### Common issue and fix

- If UI looks unstyled (plain HTML buttons/text), verify CSS endpoint is reachable from the app's internal port.
- Typical root cause is stale app process/port conflict; restart app after killing old processes.

## License

MIT
