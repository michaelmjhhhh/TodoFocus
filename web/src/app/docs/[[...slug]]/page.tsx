import { notFound } from "next/navigation";
import type { Metadata } from "next";
import { compileMDX } from "next-mdx-remote/rsc";
import { MDXRemote } from "next-mdx-remote/rsc";
import { getAllDocs, getDocBySlug, getSidebarItems, getAdjacentDocs } from "@/lib/docs";
import { siteConfig } from "@/lib/site";
import { DocsSidebar } from "@/components/docs/DocsSidebar";
import { DocsPager } from "@/components/docs/DocsPager";

interface PageProps {
  params: { slug?: string[] };
}

function slugFromParams(params: PageProps["params"]): string {
  if (!params.slug || params.slug.length === 0) return "quick-start";
  return params.slug.join("/");
}

export async function generateStaticParams() {
  const slugs = getAllDocs().map((d) => ({ slug: [d.slug] }));
  // Also add the root /docs redirect
  return [{ slug: [] as string[] }, ...slugs];
}

export async function generateMetadata({ params }: PageProps): Promise<Metadata> {
  const slug = slugFromParams(params);
  const doc = getDocBySlug(slug);
  if (!doc) return {};
  return {
    title: doc.title,
    description: doc.description,
    alternates: { canonical: `${siteConfig.siteUrl}/docs/${slug}/` },
  };
}

const mdxComponents = {};

export default async function DocPage({ params }: PageProps) {
  const slug = slugFromParams(params);
  const doc = getDocBySlug(slug);

  if (!doc) notFound();

  const { content } = await compileMDX({
    source: doc.content,
    components: mdxComponents,
    options: { parseFrontmatter: false },
  });

  const sidebarItems = getSidebarItems();
  const adjacent = getAdjacentDocs(slug);

  return (
    <div className="flex gap-12 max-w-5xl mx-auto">
      <DocsSidebar items={sidebarItems} />
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
            prose-strong:text-ink prose-strong:font-medium
            prose-table:text-sm prose-table:font-sans
            prose-th:bg-paper-dark prose-th:text-ink prose-th:font-medium
            prose-td:text-ink-light
            prose-blockquote:border-l-4 prose-blockquote:border-terracotta/40 prose-blockquote:not-italic prose-blockquote:text-ink-light
            prose-ul:font-sans prose-ul:text-ink-light
            prose-li:text-ink-light"
        >
          {content}
        </div>
        <DocsPager adjacent={adjacent} />
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
