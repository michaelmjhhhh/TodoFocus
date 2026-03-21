"use client";

import { useState, useMemo, useEffect, useCallback } from "react";
import { Sidebar, type SmartList } from "./Sidebar";
import { TodoInput } from "./TodoInput";
import { TodoList, type TodoData } from "./TodoList";
import { TaskDetail } from "./TaskDetail";
import { TimeFilterBar } from "./TimeFilterBar";
import { Sun, Star, CalendarDays, List } from "lucide-react";
import { matchesTimeFilter, type TimeFilter } from "@/lib/timeFilter";

interface ListItem {
  id: string;
  name: string;
  color: string;
  _count: { todos: number };
}

interface AppShellProps {
  todos: TodoData[];
  lists: ListItem[];
}

const DETAIL_PANEL_MIN_WIDTH = 340;
const DETAIL_PANEL_MAX_WIDTH = 760;
const DETAIL_PANEL_MIN_MAIN_WIDTH = 460;
const DETAIL_PANEL_STORAGE_KEY = "todofocus.detailPanelWidth";

const viewConfig: Record<
  SmartList,
  { label: string; icon: typeof Sun; description: string }
> = {
  myday: { label: "My Day", icon: Sun, description: "Focus on today" },
  important: {
    label: "Important",
    icon: Star,
    description: "Tasks you've starred",
  },
  planned: {
    label: "Planned",
    icon: CalendarDays,
    description: "Tasks with due dates",
  },
  all: { label: "All Tasks", icon: List, description: "Everything in one place" },
};

export function AppShell({ todos, lists }: AppShellProps) {
  const [activeView, setActiveView] = useState<SmartList | string>("myday");
  const [activeTimeFilter, setActiveTimeFilter] = useState<TimeFilter>("all-dates");
  const [selectedTodoId, setSelectedTodoId] = useState<string | null>(null);
  const [detailPanelWidth, setDetailPanelWidth] = useState<number>(() => {
    if (typeof window === "undefined") {
      return 380;
    }

    const stored = window.localStorage.getItem(DETAIL_PANEL_STORAGE_KEY);
    const parsed = stored ? Number.parseInt(stored, 10) : Number.NaN;
    return Number.isFinite(parsed) ? parsed : 380;
  });
  const [isResizingDetailPanel, setIsResizingDetailPanel] = useState(false);

  const clampDetailPanelWidth = useCallback((candidate: number) => {
    if (typeof window === "undefined") {
      return Math.min(Math.max(candidate, DETAIL_PANEL_MIN_WIDTH), DETAIL_PANEL_MAX_WIDTH);
    }

    const viewportMax = window.innerWidth - DETAIL_PANEL_MIN_MAIN_WIDTH;
    const dynamicMax = Math.max(
      DETAIL_PANEL_MIN_WIDTH,
      Math.min(DETAIL_PANEL_MAX_WIDTH, viewportMax)
    );

    return Math.min(Math.max(candidate, DETAIL_PANEL_MIN_WIDTH), dynamicMax);
  }, []);

  const updateDetailPanelWidthFromPointer = useCallback(
    (clientX: number) => {
      if (typeof window === "undefined") {
        return;
      }

      const nextWidth = clampDetailPanelWidth(window.innerWidth - clientX);
      setDetailPanelWidth(nextWidth);
    },
    [clampDetailPanelWidth]
  );

  useEffect(() => {
    setDetailPanelWidth((current) => clampDetailPanelWidth(current));
  }, [clampDetailPanelWidth]);

  useEffect(() => {
    if (typeof window === "undefined") {
      return;
    }

    const handleResize = () => {
      setDetailPanelWidth((current) => clampDetailPanelWidth(current));
    };

    window.addEventListener("resize", handleResize);
    return () => window.removeEventListener("resize", handleResize);
  }, [clampDetailPanelWidth]);

  useEffect(() => {
    if (typeof window === "undefined") {
      return;
    }

    window.localStorage.setItem(
      DETAIL_PANEL_STORAGE_KEY,
      String(clampDetailPanelWidth(detailPanelWidth))
    );
  }, [detailPanelWidth, clampDetailPanelWidth]);

  useEffect(() => {
    if (!isResizingDetailPanel || typeof window === "undefined") {
      return;
    }

    const handlePointerMove = (event: PointerEvent) => {
      updateDetailPanelWidthFromPointer(event.clientX);
    };

    const stopResizing = () => {
      setIsResizingDetailPanel(false);
    };

    document.body.style.userSelect = "none";
    document.body.style.cursor = "col-resize";

    window.addEventListener("pointermove", handlePointerMove);
    window.addEventListener("pointerup", stopResizing);
    window.addEventListener("pointercancel", stopResizing);

    return () => {
      document.body.style.userSelect = "";
      document.body.style.cursor = "";
      window.removeEventListener("pointermove", handlePointerMove);
      window.removeEventListener("pointerup", stopResizing);
      window.removeEventListener("pointercancel", stopResizing);
    };
  }, [isResizingDetailPanel, updateDetailPanelWidthFromPointer]);

  const filteredTodos = useMemo(() => {
    const viewFilteredTodos = (() => {
      switch (activeView) {
      case "myday":
        return todos.filter((t) => t.isMyDay);
      case "important":
        return todos.filter((t) => t.isImportant);
      case "planned":
        return todos.filter((t) => t.dueDate !== null);
      case "all":
        return todos;
      default:
        return todos.filter((t) => t.listId === activeView);
      }
    })();

    const now = new Date();
    return viewFilteredTodos.filter((t) =>
      matchesTimeFilter(activeTimeFilter, t.dueDate, now)
    );
  }, [todos, activeView, activeTimeFilter]);

  const selectedTodo = useMemo(() => {
    if (!selectedTodoId) return null;
    return todos.find((t) => t.id === selectedTodoId) ?? null;
  }, [todos, selectedTodoId]);

  const isSmartList = ["myday", "important", "planned", "all"].includes(
    activeView
  );
  const currentList = isSmartList
    ? null
    : lists.find((l) => l.id === activeView);
  const config = isSmartList
    ? viewConfig[activeView as SmartList]
    : null;

  const headerLabel = config?.label ?? currentList?.name ?? "Tasks";
  const HeaderIcon = config?.icon;
  const showListBadge = isSmartList && activeView !== "all";

  return (
    <div className="flex h-screen overflow-hidden">
      <Sidebar
        lists={lists}
        activeView={activeView}
        onNavigate={(view) => {
          setActiveView(view);
          setSelectedTodoId(null);
        }}
      />

      {/* Main content */}
      <main className="flex-1 flex flex-col h-screen overflow-hidden min-w-0">
        {/* Content header */}
        <header className="px-6 pt-6 pb-4">
          <div className="flex items-center gap-2.5">
            {HeaderIcon ? (
              <HeaderIcon
                size={20}
                strokeWidth={1.5}
                className="text-[var(--zen-accent)]"
              />
            ) : (
              <span
                className="w-3 h-3 rounded-full"
                style={{ backgroundColor: currentList?.color }}
              />
            )}
            <h1 className="text-xl font-semibold text-[var(--zen-text)]">
              {headerLabel}
            </h1>
          </div>
          {config?.description ? (
            <p className="text-xs text-[var(--zen-text-muted)] mt-1 ml-[30px]">
              {config.description}
            </p>
          ) : null}
          <TimeFilterBar value={activeTimeFilter} onChange={setActiveTimeFilter} />
        </header>

        {/* Add task */}
        <div className="px-6 pb-3">
          <TodoInput
            listId={!isSmartList ? activeView : undefined}
            isMyDay={activeView === "myday"}
            isImportant={activeView === "important"}
            planned={activeView === "planned"}
            placeholder={
              activeView === "myday"
                ? "What will you focus on today?"
                : "Add a task..."
            }
          />
        </div>

        {/* Task list */}
        <div className="flex-1 overflow-y-auto px-2">
          <TodoList
            todos={filteredTodos}
            onSelectTodo={setSelectedTodoId}
            showListBadge={showListBadge}
          />
        </div>

        {/* Status bar */}
        <div className="px-6 py-2 border-t border-[var(--zen-border)]">
          <p className="text-[11px] text-[var(--zen-text-muted)]">
            {filteredTodos.filter((t) => !t.isCompleted).length} task
            {filteredTodos.filter((t) => !t.isCompleted).length !== 1
              ? "s"
              : ""}{" "}
            remaining
          </p>
        </div>
      </main>

      {/* Detail panel */}
      {selectedTodo ? (
        <div
          className="relative h-screen flex-shrink-0"
          style={{ width: clampDetailPanelWidth(detailPanelWidth) }}
        >
          <button
            type="button"
            onPointerDown={(event) => {
              event.preventDefault();
              setIsResizingDetailPanel(true);
              updateDetailPanelWidthFromPointer(event.clientX);
            }}
            className="absolute left-0 top-0 z-20 h-full w-2 -translate-x-1/2 cursor-col-resize group"
            aria-label="Resize detail panel"
          >
            <span className="absolute left-1/2 top-0 h-full w-px -translate-x-1/2 bg-transparent transition-colors group-hover:bg-[var(--zen-accent)] group-active:bg-[var(--zen-accent)]" />
          </button>
          <TaskDetail
            key={selectedTodo.id}
            todo={selectedTodo}
            onClose={() => setSelectedTodoId(null)}
          />
        </div>
      ) : null}
    </div>
  );
}
