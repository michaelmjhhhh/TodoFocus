import type { Doc } from "@/types/docs";
import { DocsPager } from "./DocsPager";

interface DocsArticleProps {
  doc: Doc;
  sidebar: React.ReactNode;
}

export function DocsArticle({ doc, sidebar }: DocsArticleProps) {
  return (
    <div className="flex gap-12 max-w-5xl mx-auto">
      {sidebar}
      <article className="flex-1 min-w-0">
        <header className="mb-10">
          <h1 className="font-serif text-4xl md:text-5xl text-ink mb-4 leading-tight">
            {doc.title}
          </h1>
          {doc.description && (
            <p className="font-sans text-lg text-ink-light leading-relaxed">
              {doc.description}
            </p>
          )}
        </header>
        <div
          className="prose prose-lg max-w-none
            prose-headings:font-serif prose-headings:text-ink
            prose-p:font-sans prose-p:text-ink-light prose-p:leading-relaxed
            prose-a:text-terracotta prose-a:no-underline hover:prose-a:underline
            prose-code:font-mono prose-code:text-sm prose-code:bg-paper-dark prose-code:px-1.5 prose-code:py-0.5 prose-code:rounded
            prose-kbd:border prose-kbd:border-ink-lighter/30 prose-kbd:bg-paper-dark prose-kbd:px-1.5 prose-kbd:py-0.5 prose-kbd:rounded-md prose-kbd:shadow-sm prose-kbd:text-xs
            prose-strong:text-ink prose-strong:font-medium
            prose-table:text-sm prose-table:font-sans
            prose-th:bg-paper-dark prose-th:text-ink prose-th:font-medium
            prose-td:text-ink-light
            prose-blockquote:border-l-4 prose-blockquote:border-terracotta/40 prose-blockquote:not-italic prose-blockquote:text-ink-light
            prose-ul:font-sans prose-ul:text-ink-light
            prose-li:text-ink-light"
        >
          {doc.content}
        </div>
        <DocsPager adjacent={{ prev: null, next: null }} />
        <div className="mt-8">
          <a
            href="#"
            className="font-sans text-xs text-ink-lighter hover:text-ink transition-colors"
          >
            ↑ Back to top
          </a>
        </div>
      </article>
    </div>
  );
}
