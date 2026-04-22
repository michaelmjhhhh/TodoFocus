export interface DocFrontmatter {
  title: string;
  description: string;
  order: number;
}

export interface Doc {
  slug: string;
  title: string;
  description: string;
  order: number;
  href: string;
  content: string;
}

export interface DocMeta {
  slug: string;
  title: string;
  description: string;
  order: number;
  href: string;
}

export interface AdjacentDocs {
  prev: DocMeta | null;
  next: DocMeta | null;
}
