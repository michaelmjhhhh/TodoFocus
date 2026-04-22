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

export const metadata: Metadata = {
  title: "TodoFocus | Stop collecting tasks. Start finishing them.",
  description: "A local-first macOS task app that actually helps you finish things.",
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
