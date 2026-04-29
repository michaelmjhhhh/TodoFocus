import type { Metadata } from "next";
import { DM_Sans, Newsreader, JetBrains_Mono } from "next/font/google";
import "./globals.css";

const sans = DM_Sans({
  subsets: ["latin"],
  variable: "--font-sans",
});

const serif = Newsreader({
  subsets: ["latin"],
  variable: "--font-serif",
  style: ["normal", "italic"],
});

const mono = JetBrains_Mono({
  subsets: ["latin"],
  variable: "--font-mono",
});

const assetBase = process.env.NODE_ENV === "production" ? "/TodoFocus" : "";
const siteUrl = "https://michaelmjhhhh.github.io/TodoFocus";

export const metadata: Metadata = {
  metadataBase: new URL(siteUrl),
  title: "TodoFocus | Native macOS task focus",
  description:
    "A native, local-first macOS task app for Quick Capture, Deep Focus, Context Launchpad tasks, Daily Review, and private SQLite storage.",
  keywords: [
    "task manager macOS",
    "productivity app mac",
    "focus timer app mac",
    "local first todo app",
    "macOS task app",
    "Deep Focus",
    "Quick Capture",
    "Launchpad tasks",
  ],
  authors: [{ name: "TodoFocus" }],
  creator: "TodoFocus",
  publisher: "TodoFocus",
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      "max-video-preview": -1,
      "max-image-preview": "large",
      "max-snippet": -1,
    },
  },
  alternates: {
    canonical: siteUrl,
  },
  openGraph: {
    type: "website",
    url: siteUrl,
    siteName: "TodoFocus",
    title: "TodoFocus | Native macOS task focus",
    description:
      "Capture tasks, launch context, protect focus, and review the day in one local-first macOS workflow.",
    images: [
      {
        url: `${assetBase}/og-image.svg`,
        width: 1200,
        height: 630,
        alt: "TodoFocus — macOS Task App",
      },
    ],
    locale: "en_US",
  },
  twitter: {
    card: "summary_large_image",
    title: "TodoFocus | Native macOS task focus",
    description:
      "Capture tasks, launch context, protect focus, and review the day in one local-first macOS workflow.",
    images: [`${assetBase}/og-image.svg`],
    creator: "@todofocus",
  },
  icons: {
    icon: `${assetBase}/readme-logo.png`,
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="scroll-smooth">
      <body
        className={`${sans.variable} ${serif.variable} ${mono.variable} font-sans bg-[#F7F5F0] text-[#1a1a1a] selection:bg-[#C46849] selection:text-[#F7F5F0] antialiased`}
      >
        {children}
      </body>
    </html>
  );
}
