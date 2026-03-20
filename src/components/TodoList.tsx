"use client";

import { AnimatePresence, LayoutGroup } from "framer-motion";
import { TodoItem } from "./TodoItem";

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

export interface TodoData {
  id: string;
  title: string;
  isCompleted: boolean;
  isImportant: boolean;
  isMyDay: boolean;
  notes: string;
  dueDate: Date | null;
  sortOrder: number;
  createdAt: Date;
  updatedAt: Date;
  listId: string | null;
  steps: Step[];
  list: ListInfo | null;
}

interface TodoListProps {
  todos: TodoData[];
  onSelectTodo: (id: string) => void;
  showListBadge?: boolean;
}

export function TodoList({ todos, onSelectTodo, showListBadge }: TodoListProps) {
  const active = todos.filter((t) => !t.isCompleted);
  const completed = todos.filter((t) => t.isCompleted);

  if (todos.length === 0) {
    return (
      <div className="py-20 text-center">
        <p className="text-[var(--zen-text-muted)] text-sm">
          No tasks yet
        </p>
        <p className="text-[var(--zen-text-muted)] text-xs mt-1 opacity-60">
          Add one above to get started
        </p>
      </div>
    );
  }

  return (
    <LayoutGroup>
      <div>
        <AnimatePresence mode="popLayout">
          {active.map((todo) => (
            <TodoItem
              key={todo.id}
              id={todo.id}
              title={todo.title}
              isCompleted={todo.isCompleted}
              isImportant={todo.isImportant}
              dueDate={todo.dueDate}
              steps={todo.steps}
              listName={showListBadge ? todo.list?.name : undefined}
              listColor={showListBadge ? todo.list?.color : undefined}
              onSelect={onSelectTodo}
            />
          ))}
        </AnimatePresence>

        {completed.length > 0 ? (
          <div className="mt-4">
            <p className="px-4 py-2 text-[11px] font-semibold uppercase tracking-wider text-[var(--zen-text-muted)]">
              Completed ({completed.length})
            </p>
            <AnimatePresence mode="popLayout">
              {completed.map((todo) => (
                <TodoItem
                  key={todo.id}
                  id={todo.id}
                  title={todo.title}
                  isCompleted={todo.isCompleted}
                  isImportant={todo.isImportant}
                  dueDate={todo.dueDate}
                  steps={todo.steps}
                  listName={showListBadge ? todo.list?.name : undefined}
                  listColor={showListBadge ? todo.list?.color : undefined}
                  onSelect={onSelectTodo}
                />
              ))}
            </AnimatePresence>
          </div>
        ) : null}
      </div>
    </LayoutGroup>
  );
}
