"use client";

import { useRef, useTransition } from "react";
import { addTodo } from "@/actions/todos";
import { Plus } from "lucide-react";

interface TodoInputProps {
  listId?: string;
  isMyDay?: boolean;
  placeholder?: string;
}

export function TodoInput({
  listId,
  isMyDay,
  placeholder = "Add a task...",
}: TodoInputProps) {
  const formRef = useRef<HTMLFormElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);
  const [isPending, startTransition] = useTransition();

  function handleSubmit(formData: FormData) {
    const title = formData.get("title");
    if (!title || typeof title !== "string" || title.trim().length === 0) {
      return;
    }

    startTransition(async () => {
      await addTodo(formData);
      formRef.current?.reset();
      inputRef.current?.focus();
    });
  }

  return (
    <form ref={formRef} action={handleSubmit} className="relative">
      <div className="flex items-center gap-3 px-4 py-3 rounded-lg bg-[var(--zen-surface)] border border-[var(--zen-border)] hover:border-[var(--zen-text-muted)] focus-within:border-[var(--zen-accent)] transition-colors">
        <Plus
          size={16}
          strokeWidth={1.5}
          className="text-[var(--zen-text-muted)] flex-shrink-0"
        />
        <input
          ref={inputRef}
          type="text"
          name="title"
          placeholder={placeholder}
          autoComplete="off"
          disabled={isPending}
          className="w-full bg-transparent text-[13px] text-[var(--zen-text)] placeholder:text-[var(--zen-text-muted)] focus:outline-none disabled:opacity-50"
        />
        {listId ? <input type="hidden" name="listId" value={listId} /> : null}
        {isMyDay ? (
          <input type="hidden" name="isMyDay" value="true" />
        ) : null}
      </div>
    </form>
  );
}
