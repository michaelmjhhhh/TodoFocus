import type { Metadata } from "next";
import Link from "next/link";
import { siteConfig } from "@/lib/site";

export const metadata: Metadata = {
  title: {
    default: "Docs — TodoFocus",
    template: "%s — TodoFocus",
  },
  description: "Complete documentation for TodoFocus macOS task app.",
  metadataBase: new URL(siteConfig.siteUrl),
  alternates: { canonical: `${siteConfig.siteUrl}/docs/` },
  robots: { index: true, follow: true },
};

export default function DocsLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="font-sans bg-[#F7F5F0] text-[#1a1a1a] antialiased">
      <header className="w-full border-b border-ink-lighter/20 bg-[#F7F5F0]/95 backdrop-blur-sm sticky top-0 z-50">
        <div className="max-w-6xl mx-auto px-6 py-4 flex justify-between items-center">
          <Link href="/" className="flex items-center gap-3 group">
            <img
              src={`${siteConfig.basePath}/readme-logo.png`}
              alt="TodoFocus Icon"
              width={32}
              height={32}
              className="rounded-lg shadow-sm"
            />
            <span className="font-sans font-medium tracking-tight text-ink">
              TodoFocus
            </span>
          </Link>
          <nav className="flex items-center gap-6">
            <Link
              href="/"
              className="font-sans text-sm text-ink-light hover:text-ink transition-colors"
            >
              Home
            </Link>
            <Link
              href="/docs/quick-start/"
              className="font-sans text-sm font-medium text-terracotta"
            >
              Docs
            </Link>
            <a
              href={`${siteConfig.siteUrl}/docs/quick-start/`}
              className="font-sans text-sm font-medium bg-ink text-paper px-4 py-2 rounded-full hover:bg-terracotta transition-colors duration-300"
            >
              Get the App
            </a>
          </nav>
        </div>
      </header>
      <div className="py-16 px-6">
        {children}
      </div>
      <footer className="border-t border-ink-lighter/20 py-8 px-6">
        <div className="max-w-6xl mx-auto flex justify-between items-center">
          <span className="font-sans text-sm text-ink-lighter">
            &copy; {new Date().getFullYear()} TodoFocus
          </span>
          <span className="font-sans text-sm text-ink-lighter">
            Local-first. No cloud. No nonsense.
          </span>
        </div>
      </footer>
    </div>
  );
}
