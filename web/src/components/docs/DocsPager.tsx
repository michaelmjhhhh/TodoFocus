import Link from "next/link";
import type { AdjacentDocs } from "@/types/docs";

interface DocsPagerProps {
  adjacent: AdjacentDocs;
}

export function DocsPager({ adjacent }: DocsPagerProps) {
  const { prev, next } = adjacent;

  return (
    <div className="mt-16 pt-8 border-t border-ink-lighter/20 flex items-center justify-between">
      <div>
        {prev && (
          <Link
            href={prev.href}
            className="group flex items-center gap-2 font-sans text-sm text-ink-light hover:text-ink transition-colors"
          >
            <span className="text-ink-lighter group-hover:-translate-x-1 transition-transform duration-150">
              ←
            </span>
            <span>
              <span className="text-xs uppercase tracking-wider text-ink-lighter block">Previous</span>
              {prev.title}
            </span>
          </Link>
        )}
      </div>
      <div>
        {next && (
          <Link
            href={next.href}
            className="group flex items-center gap-2 font-sans text-sm text-ink-light hover:text-ink transition-colors text-right"
          >
            <span>
              <span className="text-xs uppercase tracking-wider text-ink-lighter block">Next</span>
              {next.title}
            </span>
            <span className="text-ink-lighter group-hover:translate-x-1 transition-transform duration-150">
              →
            </span>
          </Link>
        )}
      </div>
    </div>
  );
}
