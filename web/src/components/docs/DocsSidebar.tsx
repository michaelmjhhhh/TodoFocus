"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import type { DocMeta } from "@/types/docs";

interface DocsSidebarProps {
  items: DocMeta[];
}

export function DocsSidebar({ items }: DocsSidebarProps) {
  const pathname = usePathname();

  return (
    <nav className="w-56 flex-shrink-0 hidden lg:block">
      <div className="sticky top-8">
        <p className="font-sans text-xs font-bold uppercase tracking-widest text-ink-lighter mb-4">
          Documentation
        </p>
        <ul className="space-y-1">
          {items.map((item) => {
            const isActive = pathname === item.href;
            return (
              <li key={item.slug}>
                <Link
                  href={item.href}
                  className={`block rounded-lg px-3 py-2 font-sans text-sm transition-colors duration-150 ${
                    isActive
                      ? "bg-terracotta/10 text-terracotta font-medium"
                      : "text-ink-light hover:text-ink hover:bg-paper-dark"
                  }`}
                >
                  {item.title}
                </Link>
              </li>
            );
          })}
        </ul>
      </div>
    </nav>
  );
}
