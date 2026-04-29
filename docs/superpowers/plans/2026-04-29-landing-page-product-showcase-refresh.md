# Landing Page Product Showcase Refresh Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a clearer, more premium TodoFocus landing page that explains the important app features through a polished product-led showcase.

**Architecture:** Keep the landing page as a static Next.js App Router page. Use small typed arrays for feature/gallery data, existing public screenshots/GIFs, and Tailwind utilities for responsive layouts. Avoid new runtime dependencies.

**Tech Stack:** Next.js 14, React 18, TypeScript, Tailwind CSS, existing static assets.

---

## Chunk 1: Landing Page Refresh

### Task 1: Update metadata and page structure

**Files:**
- Modify: `web/src/app/layout.tsx`
- Modify: `web/src/app/page.tsx`

- [x] Update structured data `softwareVersion` to `1.0.9`.
- [x] Refine metadata copy around native macOS, local-first data, Quick Capture, Deep Focus, Launchpad, and Daily Review.
- [x] Replace the current centered hero with a product-led hero that includes a large screenshot in the first viewport.
- [x] Keep primary and secondary CTAs visible near the top.

### Task 2: Build feature showcase sections

**Files:**
- Modify: `web/src/app/page.tsx`

- [x] Add data arrays for workflow steps, feature spotlights, gallery images, and trust facts.
- [x] Add a workflow strip for Capture, Plan, Launch, Review.
- [x] Add feature sections for Quick Capture, Deep Focus, Context Launchpad, Daily Review, and local-first data.
- [x] Use existing screenshots/GIFs intentionally based on each feature.

### Task 3: Improve visual system details

**Files:**
- Modify: `web/src/app/globals.css`
- Modify: `web/src/app/page.tsx`

- [x] Add small reusable CSS utilities for premium surface texture, image rendering, and focus-visible states if needed.
- [x] Keep the palette restrained and tied to TodoFocus' terracotta/dark UI identity.
- [x] Ensure mobile layout does not rely on awkward horizontal scrolling.

### Task 4: Verify

**Files:**
- Test: `web`

- [x] Run `npm run lint` from `web`.
- [x] Run `npm run build` from `web`.
- [x] Fix any issues and rerun failing checks.
