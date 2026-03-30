# Portable Import/Export: URL-Only Launch Resources + Settings UX Polish

## Problem
Current import/export behavior was not aligned with cross-device portability expectations. Launch resources tied to local filesystem/app paths (`file`, `app`) are not portable between devices, and the Settings import/export section needed clearer UX and messaging.

## Goals
- Export/import only portable launch resources (`url`).
- Skip non-portable launch resources (`file`, `app`) during import and report skipped counts.
- Show preflight warning when non-portable launch resources are present.
- Improve Settings import/export UI clarity and visual quality.
- Add explicit reminder in UI that file/app resources are intentionally excluded for portability.

## Scope
- Data export/import logic in `ExportService`.
- Export format version update and compatibility handling.
- Data tests covering URL-only behavior and non-portable skip semantics.
- SettingsView import/export redesign and updated copy.

## Acceptance Criteria
- Export payload includes only URL launch resources.
- Import persists only URL launch resources and skips file/app entries without failing import.
- Preflight surfaces warning for non-portable launch resources.
- Full test suite passes and Release build succeeds.
- Settings view clearly communicates portability behavior.

## Notes
- Device-local state remains excluded from import/export (theme, window persistence, deep focus runtime/session state, etc.).
