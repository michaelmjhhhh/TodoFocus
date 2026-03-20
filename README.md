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

## License

MIT
