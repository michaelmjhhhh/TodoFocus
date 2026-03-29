# xcodegen warning: duplicate file-reference group membership for Sources/Data/*

## Summary
`xcodebuild` currently emits warnings after project generation:

- `Sources/Data/Database` member of multiple groups
- `Sources/Data/DTO` member of multiple groups
- `Sources/Data/Repositories` member of multiple groups

## Reproduction
```bash
cd macos/TodoFocusMac
xcodegen generate
xcodebuild build -project "TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -configuration Release -derivedDataPath "build/DerivedData" -destination "platform=macOS"
```

## Suspected Root Cause
In `project.yml`, app target includes broad `Sources` path while agent target separately lists multiple files under `Sources/Data/*`, which can produce malformed group membership in generated project structure.

## Scope
- `macos/TodoFocusMac/project.yml`
- generated `macos/TodoFocusMac/TodoFocusMac.xcodeproj/project.pbxproj` (if needed)

## Acceptance Criteria
- `xcodegen generate` + `xcodebuild build` no longer emits duplicate group-membership warnings.
- Build/test behavior remains unchanged.
