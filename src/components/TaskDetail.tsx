"use client";

import { useRef, useState, useTransition, useEffect } from "react";
import { motion, AnimatePresence } from "framer-motion";
import {
  X,
  Plus,
  Check,
  CalendarDays,
  Repeat,
  Sun,
  Star,
  Trash2,
} from "lucide-react";
import {
  updateTodo,
  deleteTodo,
  addStep,
  toggleStep,
  deleteStep,
  toggleImportant,
  toggleMyDay,
} from "@/actions/todos";
import { cn } from "@/lib/cn";

interface Step {
  id: string;
  title: string;
  isCompleted: boolean;
}

interface ListInfo {
  id: string;
  name: string;
  color: string;
}

interface TaskDetailProps {
  todo: {
    id: string;
    title: string;
    isCompleted: boolean;
    isImportant: boolean;
    isMyDay: boolean;
    recurrence: string | null;
    recurrenceInterval: number;
    lastCompletedAt: Date | null;
    notes: string;
    launchResources: string;
    dueDate: Date | null;
    steps: Step[];
    list: ListInfo | null;
    createdAt: Date;
    updatedAt: Date;
  };
  onClose: () => void;
}

export function TaskDetail({ todo, onClose }: TaskDetailProps) {
  const [notes, setNotes] = useState(todo.notes);
  const [isPending, startTransition] = useTransition();
  const stepInputRef = useRef<HTMLInputElement>(null);
  const notesTimeout = useRef<ReturnType<typeof setTimeout>>(null);

  useEffect(() => {
    setNotes(todo.notes);
  }, [todo.notes]);

  function handleNotesChange(value: string) {
    setNotes(value);
    if (notesTimeout.current) clearTimeout(notesTimeout.current);
    notesTimeout.current = setTimeout(() => {
      startTransition(async () => {
        await updateTodo(todo.id, { notes: value });
      });
    }, 500);
  }

  function handleDueDate(e: React.ChangeEvent<HTMLInputElement>) {
    startTransition(async () => {
      await updateTodo(todo.id, { dueDate: e.target.value || null });
    });
  }

  function handleRecurrenceChange(e: React.ChangeEvent<HTMLSelectElement>) {
    const value = e.target.value;
    startTransition(async () => {
      await updateTodo(todo.id, {
        recurrence: value === "none" ? null : value,
      });
    });
  }

  function handleAddStep(formData: FormData) {
    const title = formData.get("step") as string;
    if (!title?.trim()) return;
    startTransition(async () => {
      await addStep(todo.id, title.trim());
    });
    if (stepInputRef.current) stepInputRef.current.value = "";
  }

  function handleToggleStep(stepId: string, completed: boolean) {
    startTransition(async () => {
      await toggleStep(stepId, completed);
    });
  }

  function handleDeleteStep(stepId: string) {
    startTransition(async () => {
      await deleteStep(stepId);
    });
  }

  function handleToggleImportant() {
    startTransition(async () => {
      await toggleImportant(todo.id, !todo.isImportant);
    });
  }

  function handleToggleMyDay() {
    startTransition(async () => {
      await toggleMyDay(todo.id, !todo.isMyDay);
    });
  }

  function handleDelete() {
    startTransition(async () => {
      await deleteTodo(todo.id);
      onClose();
    });
  }

  const dueDateValue = todo.dueDate
    ? new Date(todo.dueDate).toISOString().split("T")[0]
    : "";
  const recurrenceValue = todo.recurrence ?? "none";

  return (
    <motion.div
      initial={{ x: 24, opacity: 0 }}
      animate={{ x: 0, opacity: 1 }}
      exit={{ x: 24, opacity: 0 }}
      transition={{ duration: 0.15 }}
      className="w-[360px] h-screen flex flex-col bg-[var(--zen-bg-secondary)] border-l border-[var(--zen-border)]"
    >
      {/* Header */}
      <div className="flex items-center justify-between px-4 pt-4 pb-3">
        <h2 className="text-sm font-semibold text-[var(--zen-text)] truncate flex-1 mr-2">
          {todo.title}
        </h2>
        <button
          onClick={onClose}
          className="p-1.5 rounded-lg text-[var(--zen-text-muted)] hover:text-[var(--zen-text-secondary)] hover:bg-[var(--zen-surface-hover)] transition-colors cursor-pointer"
          aria-label="Close detail panel"
        >
          <X size={16} strokeWidth={1.5} />
        </button>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-y-auto px-4 pb-4 space-y-5">
        {/* Quick actions */}
        <div className="flex gap-2">
          <button
            onClick={handleToggleMyDay}
            className={cn(
              "flex items-center gap-2 px-3 py-1.5 rounded-md text-xs font-medium transition-colors cursor-pointer border",
              todo.isMyDay
                ? "border-[var(--zen-accent)] text-[var(--zen-accent)] bg-[var(--zen-accent-soft)]"
                : "border-[var(--zen-border)] text-[var(--zen-text-secondary)] hover:bg-[var(--zen-surface-hover)]"
            )}
          >
            <Sun size={13} strokeWidth={1.5} />
            My Day
          </button>
          <button
            onClick={handleToggleImportant}
            className={cn(
              "flex items-center gap-2 px-3 py-1.5 rounded-md text-xs font-medium transition-colors cursor-pointer border",
              todo.isImportant
                ? "border-[var(--zen-warning)] text-[var(--zen-warning)] bg-[rgba(245,158,11,0.1)]"
                : "border-[var(--zen-border)] text-[var(--zen-text-secondary)] hover:bg-[var(--zen-surface-hover)]"
            )}
          >
            <Star
              size={13}
              strokeWidth={1.5}
              fill={todo.isImportant ? "currentColor" : "none"}
            />
            Important
          </button>
        </div>

        {/* Steps */}
        <div>
          <p className="text-[11px] font-semibold uppercase tracking-wider text-[var(--zen-text-muted)] mb-2">
            Steps
          </p>
          <div className="space-y-1">
            <AnimatePresence>
              {todo.steps.map((step) => (
                <motion.div
                  key={step.id}
                  initial={{ opacity: 0, height: 0 }}
                  animate={{ opacity: 1, height: "auto" }}
                  exit={{ opacity: 0, height: 0 }}
                  className="group flex items-center gap-2"
                >
                  <button
                    onClick={() => handleToggleStep(step.id, !step.isCompleted)}
                    className={cn(
                      "relative flex-shrink-0 w-4 h-4 rounded-full border-[1.5px] transition-all duration-100 cursor-pointer",
                      step.isCompleted
                        ? "border-[var(--zen-accent)] bg-[var(--zen-accent)]"
                        : "border-[var(--zen-text-muted)] hover:border-[var(--zen-accent)]"
                    )}
                  >
                    {step.isCompleted ? (
                      <Check
                        size={9}
                        strokeWidth={3}
                        className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 text-white"
                      />
                    ) : null}
                  </button>
                  <span
                    className={cn(
                      "flex-1 text-[13px]",
                      step.isCompleted
                        ? "line-through text-[var(--zen-text-muted)]"
                        : "text-[var(--zen-text)]"
                    )}
                  >
                    {step.title}
                  </span>
                  <button
                    onClick={() => handleDeleteStep(step.id)}
                    className="opacity-0 group-hover:opacity-100 p-0.5 text-[var(--zen-text-muted)] hover:text-[var(--zen-danger)] transition-all cursor-pointer"
                    aria-label="Delete step"
                  >
                    <X size={12} strokeWidth={1.5} />
                  </button>
                </motion.div>
              ))}
            </AnimatePresence>
          </div>
          <form action={handleAddStep} className="mt-2">
            <div className="flex items-center gap-2">
              <Plus
                size={14}
                strokeWidth={1.5}
                className="text-[var(--zen-text-muted)] flex-shrink-0"
              />
              <input
                ref={stepInputRef}
                name="step"
                placeholder="Add a step..."
                autoComplete="off"
                className="w-full py-1 bg-transparent text-[13px] text-[var(--zen-text)] placeholder:text-[var(--zen-text-muted)] focus:outline-none"
              />
            </div>
          </form>
        </div>

        {/* Due date */}
        <div>
          <p className="text-[11px] font-semibold uppercase tracking-wider text-[var(--zen-text-muted)] mb-2">
            Due Date
          </p>
          <div className="flex items-center gap-2">
            <CalendarDays
              size={14}
              strokeWidth={1.5}
              className="text-[var(--zen-text-muted)]"
            />
            <input
              type="date"
              value={dueDateValue}
              onChange={handleDueDate}
              className="bg-[var(--zen-surface)] border border-[var(--zen-border)] rounded-md px-3 py-1.5 text-[13px] text-[var(--zen-text)] focus:outline-none focus:border-[var(--zen-accent)]"
            />
            {dueDateValue ? (
              <button
                onClick={() =>
                  startTransition(async () => {
                    await updateTodo(todo.id, { dueDate: null });
                  })
                }
                className="p-1 text-[var(--zen-text-muted)] hover:text-[var(--zen-danger)] cursor-pointer"
                aria-label="Remove due date"
              >
                <X size={12} strokeWidth={1.5} />
              </button>
            ) : null}
          </div>
        </div>

        {/* Recurrence */}
        <div>
          <p className="text-[11px] font-semibold uppercase tracking-wider text-[var(--zen-text-muted)] mb-2">
            Repeat
          </p>
          <div className="flex items-center gap-2">
            <Repeat
              size={14}
              strokeWidth={1.5}
              className="text-[var(--zen-text-muted)]"
            />
            <select
              value={recurrenceValue}
              onChange={handleRecurrenceChange}
              className="bg-[var(--zen-surface)] border border-[var(--zen-border)] rounded-md px-3 py-1.5 text-[13px] text-[var(--zen-text)] focus:outline-none focus:border-[var(--zen-accent)]"
            >
              <option value="none">Does not repeat</option>
              <option value="daily">Daily</option>
              <option value="weekly">Weekly</option>
              <option value="monthly">Monthly</option>
            </select>
          </div>
        </div>

        {/* Notes */}
        <div>
          <p className="text-[11px] font-semibold uppercase tracking-wider text-[var(--zen-text-muted)] mb-2">
            Notes
          </p>
          <textarea
            value={notes}
            onChange={(e) => handleNotesChange(e.target.value)}
            placeholder="Add notes..."
            rows={4}
            className="w-full bg-[var(--zen-surface)] border border-[var(--zen-border)] rounded-lg px-3 py-2 text-[13px] leading-relaxed text-[var(--zen-text)] placeholder:text-[var(--zen-text-muted)] focus:outline-none focus:border-[var(--zen-accent)] resize-none"
          />
        </div>
      </div>

      {/* Footer */}
      <div className="px-4 py-3 border-t border-[var(--zen-border)] flex items-center justify-between">
        <span className="text-[11px] text-[var(--zen-text-muted)]">
          Created {new Date(todo.createdAt).toLocaleDateString()}
        </span>
        <button
          onClick={handleDelete}
          disabled={isPending}
          className="flex items-center gap-1.5 px-3 py-1.5 rounded-md text-xs text-[var(--zen-danger)] hover:bg-[var(--zen-danger-soft)] transition-colors cursor-pointer"
        >
          <Trash2 size={13} strokeWidth={1.5} />
          Delete
        </button>
      </div>
    </motion.div>
  );
}
