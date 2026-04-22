import type { MDXComponents } from "mdx/types";
import { Callout } from "@/components/docs/mdx/Callout";
import { Kbd } from "@/components/docs/mdx/Kbd";
import { Screenshot } from "@/components/docs/mdx/Screenshot";

export function useMDXComponents(components: MDXComponents): MDXComponents {
  return {
    ...components,
    Callout,
    Kbd,
    Screenshot,
  };
}
