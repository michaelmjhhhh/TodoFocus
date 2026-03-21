# AGENTS.md

## Contributor Guidelines

- Keep changes focused and small; avoid unrelated refactors in the same PR.
- Follow existing stack and patterns: Next.js App Router, Server Actions, Prisma + SQLite, Tailwind, Framer Motion, Electron.
- Run checks before opening a PR: `npm run lint` and a quick local run (`npm run dev` or `npm run electron:dev` for desktop work).
- Do not commit secrets (`.env`, local DB files, signing credentials).
- For data model changes, include Prisma migration files and verify app startup still applies migrations.

## Packaging (TodoFocus Electron)

### Build Requirements

- Node.js 18+ and npm 9+.
- Install dependencies: `npm install`.
- Next standalone build is required for Electron packaging.
- Packaging config lives in `electron-builder.json` (asar enabled; native modules unpacked via `asarUnpack`).

### Build Commands

- macOS release build: `npm run electron:build`
- Windows build: `npm run electron:build:win`
- Linux build: `npm run electron:build:linux`
- Fast local validation (no publish):
  1. `npm run build`
  2. `npm run build:electron:assets`
  3. `CSC_IDENTITY_AUTO_DISCOVERY=false npx electron-builder --mac dir --publish never`

### Release Upload Flow

1. Build target artifacts into `dist-electron/` using the platform build command.
2. Smoke test the packaged app (`dist-electron/mac-arm64/TodoFocus.app` on Apple Silicon).
3. Optional quick DMG refresh:
   `hdiutil create -volname "TodoFocus" -srcfolder "dist-electron/mac-arm64/TodoFocus.app" -ov -format UDZO "dist-electron/TodoFocus-mac-arm64.dmg"`
4. Create a GitHub Release (draft or final) and upload generated artifacts from `dist-electron/` (typically `.dmg` and `.zip` for macOS).

### Local Data Path

- macOS app data directory: `~/Library/Application Support/todofocus/`
- SQLite database file: `~/Library/Application Support/todofocus/todofocus.db`
- Next standalone server is started in-process by Electron main (no separate spawned server child process).

### Common Troubleshooting

- Unstyled UI in packaged app: usually stale internal server/port conflict; fully quit old app processes and relaunch.
- Packaging fails with missing standalone server/static assets: rerun `npm run build` then `npm run build:electron:assets`.
- Runtime DB/migration issues: confirm `prisma/migrations` is included in package and migration SQL files exist.
- Native module errors (`better-sqlite3`): ensure `asarUnpack` settings in `electron-builder.json` remain intact.
