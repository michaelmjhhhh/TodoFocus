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
- Release assets must be produced by CI workflow (`release-macos`) by default.
- Do not manually upload a local DMG/ZIP unless CI is unavailable and maintainers approve an emergency fallback.
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

### CI-First Release Flow (Required)

1. Start from clean, updated `main`.
2. Create and push the release tag:
   - `git checkout main && git pull`
   - `git tag vX.Y.Z`
   - `git push origin vX.Y.Z`
3. Trigger the workflow with the same tag:
   - `gh workflow run release-macos -f tag=vX.Y.Z`
4. Monitor until completion:
   - `gh run list --workflow release-macos --limit 5`
   - `gh run watch <run-id>`
5. Verify release assets were published:
   - `gh release view vX.Y.Z --json assets,url`
   - Confirm expected files (for example macOS `.dmg` and `.zip`) are attached.

### Workflow Failure: Retry / Rollback

1. Open failed run logs: `gh run view <run-id> --log`.
2. If failure is transient (runner/network/signing service), rerun failed jobs from Actions UI or run a new workflow run for the same tag.
3. If release assets are wrong/corrupt, delete only the bad assets and rerun workflow:
   - `gh release delete-asset vX.Y.Z <asset-name> -y`
4. If the tag itself is wrong, remove and recreate it:
   - `git tag -d vX.Y.Z`
   - `git push origin :refs/tags/vX.Y.Z`
   - Create the corrected tag and rerun `release-macos`.

### Emergency-Only Manual Upload (Exception)

- Use only when CI is unavailable and maintainers explicitly approve bypassing CI.
- Before upload, run local guarded packaging (`npm run electron:ci:package`) and smoke test.
- Upload with: `gh release upload <tag> <file> --clobber`.

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
