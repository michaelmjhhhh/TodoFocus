import { getTodos } from "@/actions/todos";
import { TodoInput } from "@/components/TodoInput";
import { TodoList } from "@/components/TodoList";

export default async function Home() {
  const todos = await getTodos();

  return (
    <main className="min-h-screen flex flex-col items-center px-4 pt-24 pb-16">
      {/* Header */}
      <header className="mb-16 text-center">
        <h1 className="font-serif text-4xl font-medium tracking-tight text-[var(--zen-text)]">
          zen.
        </h1>
        <p className="mt-2 text-xs tracking-[0.3em] uppercase text-[var(--zen-accent)] font-light">
          breathe &middot; focus &middot; do
        </p>
      </header>

      {/* Content */}
      <div className="w-full max-w-lg">
        <TodoInput />

        <div className="mt-8">
          <TodoList todos={todos} />
        </div>

        {/* Footer count */}
        {todos.length > 0 ? (
          <div className="mt-8 text-center">
            <p className="text-[11px] tracking-widest uppercase text-[var(--zen-accent-soft)] font-light">
              {todos.filter((t) => !t.isCompleted).length} remaining
            </p>
          </div>
        ) : null}
      </div>
    </main>
  );
}
