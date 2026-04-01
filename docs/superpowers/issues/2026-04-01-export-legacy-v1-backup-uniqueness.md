# Fix export legacy v1 decode and backup snapshot uniqueness

## Summary
Two reliability gaps remain in import/export:

1. Legacy `v1.0` payloads with non-empty todos can fail decode because newer required fields (`recurrenceInterval`, `sortOrder`) are not guaranteed in historical files.
2. Replace-import backups are named with second-level timestamp only, so rapid consecutive imports can collide and overwrite backup files.

## Scope
- Add backward-compatible decode defaults for `ExportTodo` missing legacy fields.
- Make backup snapshot filenames collision-resistant.
- Add regression tests for both behaviors.

## Acceptance Criteria
- A `v1.0` payload with one todo and missing modern fields decodes successfully.
- Replace import produces a backup filename with high-entropy uniqueness marker.
- Full macOS test suite passes.

## Out of Scope
- Changing export schema version beyond current `1.3`.
- Reworking import modes or merge semantics beyond this bugfix.
