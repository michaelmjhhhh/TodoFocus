"use client";

import { useTransition } from "react";
import { motion } from "framer-motion";
import { toggleTodo, toggleImportant, deleteTodo } from "@/actions/todos";
import { Star, X, Check, CalendarDays, ListChecks, Repeat } from "lucide-react";
import { cn } from "@/lib/cn";

interface Step {
  id: string;
  title: string;
  isCompleted: boolean;
}

interface TodoItemProps {
  id: string;
  title: string;
  isCompleted: boolean;
  isImportant: boolean;
  recurrence: string | null;
  dueDate: Date | null;
  steps: Step[];
  listName?: string;
  listColor?: string;
  onSelect: (id: string) => void;
}

function formatDueDate(date: Date): { text: string; isOverdue: boolean } {
  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const due = new Date(date.getFullYear(), date.getMonth(), date.getDate());
  const diff = Math.floor(
    (due.getTime() - today.getTime()) / (1000 * 60 * 60 * 24)
  );

  if (diff < 0) return { text: "Overdue", isOverdue: true };
  if (diff === 0) return { text: "Today", isOverdue: false };
  if (diff === 1) return { text: "Tomorrow", isOverdue: false };
  if (diff < 7) {
    return {
      text: due.toLocaleDateString("en-US", { weekday: "short" }),
      isOverdue: false,
    };
  }
  return {
    text: due.toLocaleDateString("en-US", { month: "short", day: "numeric" }),
    isOverdue: false,
  };
}

export function TodoItem({
  id,
  title,
  isCompleted,
  isImportant,
  recurrence,
  dueDate,
  steps,
  listName,
  listColor,
  onSelect,
}: TodoItemProps) {
  const [isToggling, startToggle] = useTransition();
  const [isStarring, startStar] = useTransition();
  const [isDeleting, startDelete] = useTransition();

  const isPending = isToggling || isStarring || isDeleting;
  const completedSteps = steps.filter((s) => s.isCompleted).length;
  const totalSteps = steps.length;
  const dueDateInfo = dueDate ? formatDueDate(new Date(dueDate)) : null;

  function handleToggle(e: React.MouseEvent) {
    e.stopPropagation();
    startToggle(async () => {
      await toggleTodo(id, !isCompleted);
    });
  }

  function handleStar(e: React.MouseEvent) {
    e.stopPropagation();
    startStar(async () => {
      await toggleImportant(id, !isImportant);
    });
  }

  function handleDelete(e: React.MouseEvent) {
    e.stopPropagation();
    startDelete(async () => {
      await deleteTodo(id);
    });
  }

  return (
    <motion.div
      layout
      initial={{ opacity: 0, y: 4 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, x: -12 }}
      transition={{
        layout: { type: "spring", stiffness: 400, damping: 30 },
        opacity: { duration: 0.15 },
      }}
      onClick={() => onSelect(id)}
      className={cn(
        "group flex items-start gap-3 px-4 py-3 rounded-lg cursor-pointer transition-colors duration-100 hover:bg-[var(--zen-surface-hover)]",
        isPending && "opacity-50"
      )}
    >
      {/* Checkbox */}
      <button
        type="button"
        onClick={handleToggle}
        disabled={isPending}
        aria-label={isCompleted ? "Mark as incomplete" : "Mark as complete"}
        className={cn(
          "relative flex-shrink-0 mt-0.5 w-[18px] h-[18px] rounded-full border-[1.5px] transition-all duration-150 cursor-pointer",
          isCompleted
            ? "border-[var(--zen-accent)] bg-[var(--zen-accent)]"
            : "border-[var(--zen-text-muted)] hover:border-[var(--zen-accent)]"
        )}
      >
        {isCompleted ? (
          <Check
            size={11}
            strokeWidth={3}
            className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 text-white"
          />
        ) : null}
      </button>

      {/* Content */}
      <div className="flex-1 min-w-0">
        <span
          className={cn(
            "block text-[13px] leading-snug transition-colors duration-150",
            isCompleted
              ? "line-through text-[var(--zen-text-muted)]"
              : "text-[var(--zen-text)]"
          )}
        >
          {title}
        </span>

        {/* Metadata row */}
        {(totalSteps > 0 || dueDateInfo || recurrence || listName) ? (
          <div className="flex items-center gap-2 mt-1 flex-wrap">
            {totalSteps > 0 ? (
              <span className="flex items-center gap-1 text-[11px] text-[var(--zen-text-muted)]">
                <ListChecks size={11} strokeWidth={1.5} />
                {completedSteps}/{totalSteps}
              </span>
            ) : null}
            {dueDateInfo ? (
              <span
                className={cn(
                  "flex items-center gap-1 text-[11px]",
                  dueDateInfo.isOverdue
                    ? "text-[var(--zen-danger)]"
                    : "text-[var(--zen-text-muted)]"
                )}
              >
                <CalendarDays size={11} strokeWidth={1.5} />
                {dueDateInfo.text}
              </span>
            ) : null}
            {recurrence ? (
              <span className="flex items-center gap-1 text-[11px] text-[var(--zen-text-muted)]">
                <Repeat size={11} strokeWidth={1.5} />
                {recurrence === "daily"
                  ? "Daily"
                  : recurrence === "weekly"
                    ? "Weekly"
                    : recurrence === "monthly"
                      ? "Monthly"
                      : recurrence}
              </span>
            ) : null}
            {listName ? (
              <span className="flex items-center gap-1 text-[11px] text-[var(--zen-text-muted)]">
                <span
                  className="w-1.5 h-1.5 rounded-full"
                  style={{ backgroundColor: listColor }}
                />
                {listName}
              </span>
            ) : null}
          </div>
        ) : null}
      </div>

      {/* Right actions */}
      <div className="flex items-center gap-1 flex-shrink-0 mt-0.5">
        <button
          type="button"
          onClick={handleStar}
          disabled={isPending}
          aria-label={isImportant ? "Remove importance" : "Mark as important"}
          className={cn(
            "p-1 rounded transition-colors duration-100 cursor-pointer",
            isImportant
              ? "text-[var(--zen-warning)]"
              : "text-transparent group-hover:text-[var(--zen-text-muted)] hover:!text-[var(--zen-warning)]"
          )}
        >
          <Star
            size={14}
            strokeWidth={1.5}
            fill={isImportant ? "currentColor" : "none"}
          />
        </button>

        <button
          type="button"
          onClick={handleDelete}
          disabled={isPending}
          aria-label="Delete todo"
          className="p-1 rounded text-transparent group-hover:text-[var(--zen-text-muted)] hover:!text-[var(--zen-danger)] hover:bg-[var(--zen-danger-soft)] transition-colors duration-100 cursor-pointer"
        >
          <X size={14} strokeWidth={1.5} />
        </button>
      </div>
    </motion.div>
  );
}
