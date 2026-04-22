export const docsConfig = [
  {
    title: "Quick Start",
    slug: "quick-start",
    description: "Get up and running with TodoFocus in minutes.",
    order: 1,
  },
  {
    title: "Quick Capture",
    slug: "quick-capture",
    description: "Capture thoughts instantly from anywhere on macOS.",
    order: 2,
  },
  {
    title: "Deep Focus",
    slug: "deep-focus",
    description: "Built-in focus timer with session stats and menu bar controls.",
    order: 3,
  },
  {
    title: "Hard Focus",
    slug: "hard-focus",
    description: "Block distractions and commit to the work.",
    order: 4,
  },
  {
    title: "Launchpad",
    slug: "launchpad",
    description: "Attach links, files, and apps to tasks — launch everything in one click.",
    order: 5,
  },
  {
    title: "Daily Review",
    slug: "daily-review",
    description: "A fast, honest reset at the end of your day.",
    order: 6,
  },
  {
    title: "Smart Views & Search",
    slug: "smart-views",
    description: "Find tasks fast with My Day, filters, and ⌘K search.",
    order: 7,
  },
  {
    title: "Data & Privacy",
    slug: "data-privacy",
    description: "Your data stays on your Mac. No accounts, no cloud.",
    order: 8,
  },
] as const;

export type DocSlug = (typeof docsConfig)[number]["slug"];
