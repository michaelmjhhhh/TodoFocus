# Plan: Export Legacy v1 Compatibility + Backup Filename Uniqueness

## Context
This is a bugfix iteration for import/export reliability after PR #139.

## Root Cause
1. `ExportTodo` relies on synthesized decoding with non-optional fields added after v1.0.
2. `createBackupSnapshot()` uses `yyyyMMdd-HHmmss` only.

## Implementation Steps
1. Add regression tests in `ExportServiceTests`:
   - decode legacy `v1.0` todo with missing modern fields
   - backup filename structure includes millisecond + random suffix
2. Implement custom decoding defaults in `ExportTodo`.
3. Update backup filename generation to include sub-second precision and UUID suffix.
4. Run verification:
   - `xcodebuild test ...`
   - `xcodebuild build ... Release ...`
5. Open PR with issue linkage and verification evidence.

## Risks
- Changing decode behavior could unintentionally mask malformed data.

## Mitigation
- Keep defaults narrow and explicit to known legacy fields only.
- Preserve strict validation elsewhere.
