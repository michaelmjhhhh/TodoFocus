# Import/Export Upgrade Notes

## What Changed

- Import now supports two modes:
  - `Replace existing data`
  - `Merge into existing data`
- Import now runs a preflight check before execution.
- Replace-mode import creates a JSON backup snapshot before mutating local data.
- Export format now uses version `1.1` with optional metadata while remaining compatible with `1.0` imports.

## Behavior Details

- Unsupported versions are blocked during preflight.
- Duplicate IDs in import payload are treated as blocking errors.
- Unknown launch resource types are skipped and counted in the result summary.
- Import success UI now includes created/updated counts and backup file path (when available).

## Backward Compatibility

- Existing `1.0` export files are still accepted.
- New metadata fields are optional and ignored by older payloads.

## Known Constraints

- Merge mode uses ID-based upsert semantics for lists/todos/steps.
- Merge mode does not delete local records that are absent from the import file.
