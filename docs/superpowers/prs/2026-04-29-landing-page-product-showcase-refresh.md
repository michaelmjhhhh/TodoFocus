# Landing Page Product Showcase Refresh

Closes #185

## Summary

- Reworked the web landing page around a product-led TodoFocus workflow: Capture, Choose, Launch, Review.
- Replaced the simple screenshot strip with feature spotlights, a Launchpad GIF showcase, and an editorial screenshot gallery.
- Updated SEO/social metadata and structured data copy for the latest native macOS/local-first positioning.
- Added lightweight implementation/spec/issue artifacts for the change.

## Verification

- `npm run lint`
  - Result: `No ESLint warnings or errors`
- `npm run build`
  - Result: `Compiled successfully`
  - Result: static route `/` prerendered successfully

## Notes

- Uses existing assets from `web/public`.
- Keeps static export compatibility with the existing GitHub Pages base path behavior.
