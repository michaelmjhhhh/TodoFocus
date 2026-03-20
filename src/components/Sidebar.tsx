"use client";

import { useRef, useState, useTransition } from "react";
import {
  Sun,
  Star,
  CalendarDays,
  List,
  Plus,
  Trash2,
  Hash,
} from "lucide-react";
import { createList, deleteList } from "@/actions/todos";
import { ThemeToggle } from "./ThemeToggle";
import { cn } from "@/lib/cn";

export type SmartList = "myday" | "important" | "planned" | "all";

interface ListItem {
  id: string;
  name: string;
  color: string;
  _count: { todos: number };
}

interface SidebarProps {
  lists: ListItem[];
  activeView: SmartList | string;
  onNavigate: (view: SmartList | string) => void;
}

const smartLists = [
  { id: "myday" as SmartList, label: "My Day", icon: Sun },
  { id: "important" as SmartList, label: "Important", icon: Star },
  { id: "planned" as SmartList, label: "Planned", icon: CalendarDays },
  { id: "all" as SmartList, label: "All Tasks", icon: List },
];

export function Sidebar({ lists, activeView, onNavigate }: SidebarProps) {
  const [isAdding, setIsAdding] = useState(false);
  const [isPending, startTransition] = useTransition();
  const inputRef = useRef<HTMLInputElement>(null);

  function handleAddList() {
    setIsAdding(true);
    setTimeout(() => inputRef.current?.focus(), 0);
  }

  function handleSubmitList(formData: FormData) {
    const name = formData.get("name") as string;
    if (!name?.trim()) {
      setIsAdding(false);
      return;
    }
    startTransition(async () => {
      await createList(name.trim());
      setIsAdding(false);
    });
  }

  function handleDeleteList(e: React.MouseEvent, id: string) {
    e.stopPropagation();
    e.preventDefault();
    startTransition(async () => {
      await deleteList(id);
      if (activeView === id) onNavigate("all");
    });
  }

  return (
    <aside className="w-[260px] h-screen flex flex-col bg-[var(--zen-bg-secondary)] border-r border-[var(--zen-border)]">
      {/* Header */}
      <div className="px-4 pt-5 pb-3 flex items-center justify-between">
        <h1 className="text-lg font-semibold tracking-tight text-[var(--zen-text)]">
          TodoFocus.
        </h1>
        <ThemeToggle />
      </div>

      {/* Smart Lists */}
      <nav className="px-2 mt-1">
        {smartLists.map(({ id, label, icon: Icon }) => (
          <button
            key={id}
            onClick={() => onNavigate(id)}
            className={cn(
              "w-full flex items-center gap-3 px-3 py-2 rounded-lg text-[13px] font-medium transition-colors duration-100 cursor-pointer",
              activeView === id
                ? "bg-[var(--zen-accent-soft)] text-[var(--zen-accent)]"
                : "text-[var(--zen-text-secondary)] hover:bg-[var(--zen-surface-hover)]"
            )}
          >
            <Icon size={16} strokeWidth={1.5} />
            <span>{label}</span>
          </button>
        ))}
      </nav>

      {/* Divider */}
      <div className="mx-4 my-3 h-px bg-[var(--zen-border)]" />

      {/* Custom Lists */}
      <div className="flex-1 overflow-y-auto px-2">
        <div className="flex items-center justify-between px-3 mb-1">
          <span className="text-[11px] font-semibold uppercase tracking-wider text-[var(--zen-text-muted)]">
            Lists
          </span>
          <button
            onClick={handleAddList}
            className="p-1 rounded text-[var(--zen-text-muted)] hover:text-[var(--zen-text-secondary)] hover:bg-[var(--zen-surface-hover)] transition-colors cursor-pointer"
            aria-label="Create new list"
          >
            <Plus size={14} strokeWidth={1.5} />
          </button>
        </div>

        {lists.map((list) => (
          <div
            key={list.id}
            role="button"
            tabIndex={0}
            onClick={() => onNavigate(list.id)}
            onKeyDown={(e) => {
              if (e.key === "Enter" || e.key === " ") onNavigate(list.id);
            }}
            className={cn(
              "group w-full flex items-center gap-3 px-3 py-2 rounded-lg text-[13px] font-medium transition-colors duration-100 cursor-pointer",
              activeView === list.id
                ? "bg-[var(--zen-accent-soft)] text-[var(--zen-accent)]"
                : "text-[var(--zen-text-secondary)] hover:bg-[var(--zen-surface-hover)]"
            )}
          >
            <Hash size={14} strokeWidth={1.5} style={{ color: list.color }} />
            <span className="flex-1 text-left truncate">{list.name}</span>
            {list._count.todos > 0 ? (
              <span className="text-[11px] text-[var(--zen-text-muted)]">
                {list._count.todos}
              </span>
            ) : null}
            <button
              onClick={(e) => handleDeleteList(e, list.id)}
              className="opacity-0 group-hover:opacity-100 p-0.5 rounded text-[var(--zen-text-muted)] hover:text-[var(--zen-danger)] hover:bg-[var(--zen-danger-soft)] transition-all cursor-pointer"
              aria-label={`Delete list ${list.name}`}
            >
              <Trash2 size={12} strokeWidth={1.5} />
            </button>
          </div>
        ))}

        {/* New list input */}
        {isAdding ? (
          <form action={handleSubmitList} className="px-3 py-1">
            <input
              ref={inputRef}
              name="name"
              placeholder="List name..."
              autoComplete="off"
              disabled={isPending}
              onBlur={(e) => {
                if (!e.currentTarget.value.trim()) setIsAdding(false);
              }}
              onKeyDown={(e) => {
                if (e.key === "Escape") setIsAdding(false);
              }}
              className="w-full px-2 py-1.5 rounded-md bg-[var(--zen-surface)] border border-[var(--zen-border)] text-[13px] text-[var(--zen-text)] placeholder:text-[var(--zen-text-muted)] focus:outline-none focus:border-[var(--zen-accent)]"
            />
          </form>
        ) : null}
      </div>

      {/* Footer */}
      <div className="px-4 py-3 border-t border-[var(--zen-border)]">
        <p className="text-[10px] text-[var(--zen-text-muted)] tracking-wider uppercase text-center">
          breathe &middot; focus &middot; do
        </p>
      </div>
    </aside>
  );
}
