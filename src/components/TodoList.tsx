"use client";

import { AnimatePresence, LayoutGroup } from "framer-motion";
import { TodoItem } from "./TodoItem";

interface Todo {
  id: string;
  title: string;
  isCompleted: boolean;
  createdAt: Date;
  updatedAt: Date;
}

interface TodoListProps {
  todos: Todo[];
}

export function TodoList({ todos }: TodoListProps) {
  const active = todos.filter((t) => !t.isCompleted);
  const completed = todos.filter((t) => t.isCompleted);

  return (
    <LayoutGroup>
      <div className="space-y-1">
        <AnimatePresence mode="popLayout">
          {active.map((todo) => (
            <TodoItem
              key={todo.id}
              id={todo.id}
              title={todo.title}
              isCompleted={todo.isCompleted}
            />
          ))}
        </AnimatePresence>

        {completed.length > 0 && active.length > 0 ? (
          <div className="py-3 px-5">
            <div className="h-px bg-[var(--zen-border)]" />
          </div>
        ) : null}

        <AnimatePresence mode="popLayout">
          {completed.map((todo) => (
            <TodoItem
              key={todo.id}
              id={todo.id}
              title={todo.title}
              isCompleted={todo.isCompleted}
            />
          ))}
        </AnimatePresence>
      </div>

      {todos.length === 0 ? (
        <div className="py-16 text-center">
          <p className="text-[var(--zen-accent)] font-light text-sm tracking-widest uppercase">
            nothing here yet
          </p>
          <p className="text-[var(--zen-accent-soft)] text-xs mt-2 tracking-wide">
            add a task to begin
          </p>
        </div>
      ) : null}
    </LayoutGroup>
  );
}
