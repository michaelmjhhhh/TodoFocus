"use client";

import { useTransition } from "react";
import { motion } from "framer-motion";
import { toggleTodo, deleteTodo } from "@/actions/todos";
import { X, Check } from "lucide-react";

interface TodoItemProps {
  id: string;
  title: string;
  isCompleted: boolean;
}

export function TodoItem({ id, title, isCompleted }: TodoItemProps) {
  const [isToggling, startToggle] = useTransition();
  const [isDeleting, startDelete] = useTransition();

  const isPending = isToggling || isDeleting;

  function handleToggle() {
    startToggle(async () => {
      await toggleTodo(id, !isCompleted);
    });
  }

  function handleDelete() {
    startDelete(async () => {
      await deleteTodo(id);
    });
  }

  return (
    <motion.div
      layout
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, x: -16, filter: "blur(4px)" }}
      transition={{
        layout: { type: "spring", stiffness: 350, damping: 30 },
        opacity: { duration: 0.2 },
        y: { duration: 0.25 },
        x: { duration: 0.2 },
      }}
      className={`
        group flex items-center gap-4 px-5 py-4
        rounded-xl
        transition-colors duration-200
        hover:bg-white/70
        ${isPending ? "opacity-50" : ""}
      `}
    >
      {/* Custom circular checkbox */}
      <button
        type="button"
        onClick={handleToggle}
        disabled={isPending}
        aria-label={isCompleted ? "Mark as incomplete" : "Mark as complete"}
        className={`
          relative flex-shrink-0
          w-[22px] h-[22px] rounded-full
          border-[1.5px] transition-all duration-300
          cursor-pointer
          focus-visible:outline-2 focus-visible:outline-offset-2
          focus-visible:outline-[var(--zen-accent)]
          ${
            isCompleted
              ? "border-[var(--zen-accent)] bg-[var(--zen-accent)]"
              : "border-[var(--zen-accent-soft)] hover:border-[var(--zen-accent)]"
          }
        `}
      >
        {isCompleted ? (
          <Check
            size={14}
            strokeWidth={2.5}
            className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 text-white"
          />
        ) : null}
      </button>

      {/* Title */}
      <span
        className={`
          flex-1 text-[15px] leading-relaxed tracking-wide
          transition-all duration-300
          ${
            isCompleted
              ? "line-through text-[var(--zen-accent)] decoration-[var(--zen-accent-soft)]"
              : "text-[var(--zen-text)]"
          }
        `}
      >
        {title}
      </span>

      {/* Delete button - appears on hover */}
      <button
        type="button"
        onClick={handleDelete}
        disabled={isPending}
        aria-label="Delete todo"
        className={`
          flex-shrink-0 p-1.5 rounded-lg
          text-transparent
          transition-all duration-200
          group-hover:text-[var(--zen-accent-soft)]
          hover:!text-red-400 hover:bg-red-50
          focus-visible:text-red-400
          focus-visible:outline-2 focus-visible:outline-offset-2
          focus-visible:outline-red-300
          cursor-pointer
        `}
      >
        <X size={15} strokeWidth={1.5} />
      </button>
    </motion.div>
  );
}
