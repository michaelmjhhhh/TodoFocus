# AGENTS.md

## Contributor Guidelines

- Keep changes focused and small; avoid unrelated refactors in the same PR.
- Follow existing stack and patterns: Next.js App Router, Server Actions, Prisma + SQLite, Tailwind, Framer Motion, Electron.
- Run checks before opening a PR: `npm run lint` and a quick local run (`npm run dev` or `npm run electron:dev` for desktop work).
- Do not commit secrets (`.env`, local DB files, signing credentials).
- For data model changes, include Prisma migration files and verify app startup still applies migrations.
- For bug fixes, follow systematic debugging: reproduce -> collect evidence -> identify root cause -> then implement.
- For new features, follow this flow: issue -> branch -> implement -> PR.
- For non-trivial feature work, write a plan in `docs/superpowers/plans/` before implementation.

## Packaging (TodoFocus Electron)

### Core Packaging Rules (Must Follow)

- Treat desktop packaging as a **standalone runtime** flow (not the same as `npm run dev`).
- Always package from **clean, updated main** when preparing release artifacts.
- Release assets should be produced by CI workflow (`release-macos`) rather than manual local upload when possible.
- Keep `asar` enabled; only unpack what is required at runtime.
- Include `prisma/migrations/**/*` in packaged files; missing migrations break first-run DB setup.
- Keep static copy step before packaging:
  - `.next/static` -> `.next/standalone/.next/static`
  - `public` -> `.next/standalone/public`
- Rebuild native modules for Electron target before or during packaging:
  - `npx electron-builder install-app-deps`
- After native rebuild, sync standalone native artifacts from root `node_modules`:
  - `npm run sync:standalone:native`
- Gate release upload with both checks:
  - ABI check (`npm run verify:electron:abi`)
  - Packaged app smoke check (`npm run verify:electron:smoke`)

### Build Requirements

- Node.js 18+ and npm 9+.
- Install dependencies: `npm install`.
- If `src/generated/prisma` is missing, run `npm run prisma:generate` before builds.
- Next standalone build is required for Electron packaging.
- Packaging config lives in `electron-builder.json` (asar enabled; native modules unpacked via `asarUnpack`).

### Preflight Checklist (Before Creating DMG)

1. Verify branch and workspace are correct (`main`, no accidental local-only changes).
2. Run:
   1. `npm run build`
   2. `npm run build:electron:assets`
   3. `npx electron-builder install-app-deps`
3. Package app directory build:
   - `CSC_IDENTITY_AUTO_DISCOVERY=false npx electron-builder --mac dir --publish never`
4. Smoke test packaged app from `dist-electron/mac-arm64/TodoFocus.app`.
5. Only after smoke passes, generate/refresh DMG.

### Build Commands

- macOS release build: `npm run electron:build`
- Windows build: `npm run electron:build:win`
- Linux build: `npm run electron:build:linux`
- Fast local validation (no publish):
  1. `npm run build`
  2. `npm run build:electron:assets`
  3. `CSC_IDENTITY_AUTO_DISCOVERY=false npx electron-builder --mac dir --publish never`
- CI-equivalent guarded local packaging:
  - `npm run electron:ci:package`

### Release Upload Flow

1. Build target artifacts into `dist-electron/` using the platform build command.
2. Smoke test the packaged app (`dist-electron/mac-arm64/TodoFocus.app` on Apple Silicon).
3. Optional quick DMG refresh:
   `hdiutil create -volname "TodoFocus" -srcfolder "dist-electron/mac-arm64/TodoFocus.app" -ov -format UDZO "dist-electron/TodoFocus-mac-arm64.dmg"`
4. Create a GitHub Release (draft or final) and upload generated artifacts from `dist-electron/` (typically `.dmg` and `.zip` for macOS).
5. If replacing an existing asset, use `gh release upload <tag> <file> --clobber`.

### Local Data Path

- macOS app data directory: `~/Library/Application Support/todofocus/`
- SQLite database file: `~/Library/Application Support/todofocus/todofocus.db`
- Next standalone server is started in-process by Electron main (no separate spawned server child process).

### Common Troubleshooting

- Unstyled UI in packaged app: usually stale internal server/port conflict; fully quit old app processes and relaunch.
- Packaging fails with missing standalone server/static assets: rerun `npm run build` then `npm run build:electron:assets`.
- Runtime DB/migration issues: confirm `prisma/migrations` is included in package and migration SQL files exist.
- Native module errors (`better-sqlite3`): ensure `asarUnpack` settings in `electron-builder.json` remain intact.
- `better-sqlite3` ABI mismatch (`NODE_MODULE_VERSION` error): run `npx electron-builder install-app-deps`, then rebuild package artifacts.
- `P2022 column does not exist` in dev: local `dev.db` is behind schema; run `npx prisma migrate dev`.
