"use client";

import { useRef, useTransition } from "react";
import { addTodo } from "@/actions/todos";
import { Plus } from "lucide-react";

export function TodoInput() {
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
    <form
      ref={formRef}
      action={handleSubmit}
      className="group relative"
    >
      <input
        ref={inputRef}
        type="text"
        name="title"
        placeholder="what needs your attention..."
        autoComplete="off"
        disabled={isPending}
        className={`
          w-full px-5 py-4 
          bg-white/60 backdrop-blur-sm
          border border-transparent
          rounded-xl
          text-[var(--zen-text)] placeholder:text-[var(--zen-accent)]
          font-light tracking-wide
          transition-all duration-300 ease-out
          focus:outline-none focus:border-[var(--zen-accent-soft)]
          focus:bg-white focus:shadow-[var(--zen-shadow-md)]
          hover:bg-white/80
          disabled:opacity-50
        `}
      />
      <button
        type="submit"
        disabled={isPending}
        aria-label="Add todo"
        className={`
          absolute right-3 top-1/2 -translate-y-1/2
          p-2 rounded-lg
          text-[var(--zen-accent)]
          transition-all duration-200
          hover:text-[var(--zen-text)] hover:bg-[var(--zen-border)]/50
          focus-visible:outline-2 focus-visible:outline-[var(--zen-accent)]
          disabled:opacity-30
          cursor-pointer
        `}
      >
        <Plus size={18} strokeWidth={1.5} />
      </button>
    </form>
  );
}
