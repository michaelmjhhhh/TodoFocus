import type { Config } from "tailwindcss";
import typography from "@tailwindcss/typography";

const config: Config = {
  content: [
    "./src/pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/components/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ["var(--font-sans)", "system-ui", "sans-serif"],
        serif: ["var(--font-serif)", "Georgia", "serif"],
        mono: ["var(--font-mono)", "monospace"],
      },
      colors: {
        paper: {
          DEFAULT: "#F7F5F0",
          dark: "#EFECE4",
        },
        ink: {
          DEFAULT: "#1a1a1a",
          light: "#4a4a4a",
          lighter: "#8a8a8a",
        },
        terracotta: {
          DEFAULT: "#C46849",
          hover: "#A85538",
        },
      },
    },
  },
  plugins: [typography],
};
export default config;
