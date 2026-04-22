import fs from "fs";
import path from "path";
import matter from "gray-matter";
import type { Doc, DocMeta, AdjacentDocs } from "@/types/docs";

const CONTENT_DIR = path.join(process.cwd(), "content", "docs");

const DOCS_CONFIG = [
  { slug: "quick-start", order: 1 },
  { slug: "quick-capture", order: 2 },
  { slug: "deep-focus", order: 3 },
  { slug: "hard-focus", order: 4 },
  { slug: "launchpad", order: 5 },
  { slug: "daily-review", order: 6 },
  { slug: "smart-views", order: 7 },
  { slug: "data-privacy", order: 8 },
];

function readDoc(slug: string) {
  const filePath = path.join(CONTENT_DIR, `${slug}.mdx`);
  const raw = fs.readFileSync(filePath, "utf-8");
  return matter(raw);
}

function buildDoc(slug: string, order: number): Doc {
  const { data, content } = readDoc(slug);
  return {
    slug,
    title: String(data.title ?? "Untitled"),
    description: String(data.description ?? ""),
    order,
    href: `/docs/${slug}/`,
    content,
  };
}

export function getAllDocs(): Doc[] {
  return DOCS_CONFIG.map(({ slug, order }) => buildDoc(slug, order));
}

export function getDocBySlug(slug: string): Doc | null {
  const found = DOCS_CONFIG.find((d) => d.slug === slug);
  if (!found) return null;
  return buildDoc(found.slug, found.order);
}

export function getSidebarItems(): DocMeta[] {
  return getAllDocs().map(({ slug, title, description, order, href }) => ({
    slug, title, description, order, href,
  }));
}

export function getAdjacentDocs(slug: string): AdjacentDocs {
  const docs = getAllDocs();
  const idx = docs.findIndex((d) => d.slug === slug);
  return {
    prev: idx > 0
      ? { slug: docs[idx - 1].slug, title: docs[idx - 1].title, description: docs[idx - 1].description, order: docs[idx - 1].order, href: docs[idx - 1].href }
      : null,
    next: idx < docs.length - 1
      ? { slug: docs[idx + 1].slug, title: docs[idx + 1].title, description: docs[idx + 1].description, order: docs[idx + 1].order, href: docs[idx + 1].href }
      : null,
  };
}

export function getStaticDocSlugs(): string[] {
  return DOCS_CONFIG.map((d) => d.slug);
}
