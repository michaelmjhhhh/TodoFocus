# Landing Page Product Showcase Refresh Design

## Goal

Update the TodoFocus web landing page to prioritize product understanding and premium visual polish while keeping the interface clean and restrained.

## Audience

The page is for macOS users evaluating whether TodoFocus is worth downloading. They should quickly understand that TodoFocus is native, local-first, and built around a focused workday: capture thoughts, choose the right work, launch context, focus, and review.

## Design Direction

Use a product-led layout inspired by the app itself: dark polished surfaces, terracotta accents, subtle warm paper sections, crisp typography, and large real screenshots. Avoid decorative-only visuals. Every image should explain a part of the workflow.

## Page Structure

1. Header
   - Logo and product name.
   - Lightweight trust markers.
   - Download CTA.

2. Hero
   - Clear headline naming TodoFocus as a native macOS task app.
   - Short explanation of local-first focus workflow.
   - Primary download CTA and secondary GitHub/releases CTA.
   - Large screenshot in a staged product frame, visible in the first viewport.

3. Workflow Strip
   - Four concise steps: Capture, Plan, Launch, Review.
   - Designed for quick scanning, not long-form education.

4. Feature Showcases
   - Quick Capture and Deep Focus: explain system-wide capture and focused execution.
   - Context Launchpad: use the GIF as the hero media for launching links, files, and apps.
   - Daily Review and My Day: show review/reset workflow using screenshots.
   - Local-first data: explain no account, SQLite storage, and import/export.

5. Gallery
   - Replace the current single horizontal screenshot strip with an editorial gallery using varied image sizes.
   - Use captions that connect each image to a feature.

6. Final CTA
   - Repeat download action with macOS requirement and latest release context.

## Implementation Notes

- Keep changes scoped to `web/src/app/page.tsx`, `web/src/app/layout.tsx`, and `web/src/app/globals.css` unless verification requires small supporting updates.
- Continue using existing assets in `web/public`.
- Keep static export compatibility by retaining the existing production `assetBase` behavior.
- Use Tailwind classes and small local data arrays in `page.tsx`; avoid adding dependencies.
- Update schema `softwareVersion` to `1.0.9`.

## Verification

- Run `npm run lint` in `web`.
- Run `npm run build` in `web`.
- Inspect the resulting page structure for responsive image treatment and CTA availability.
