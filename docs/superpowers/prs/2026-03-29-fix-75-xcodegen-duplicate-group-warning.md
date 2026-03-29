## Summary
Closes #75.

Removes Xcode-generated malformed group membership warnings by simplifying `TodoFocusAgent` source declarations in `project.yml`.

## What Changed
- Updated `macos/TodoFocusMac/project.yml`:
  - `TodoFocusAgent.sources` now uses a single `path: Sources` entry with `includes` for agent-specific files.
  - Replaced multiple mixed `Sources/Agent` + `Sources/Data/*` entries that were causing duplicate file-reference group memberships.

## Why
`xcodebuild` warnings showed `Sources/Data/Database`, `Sources/Data/DTO`, and `Sources/Data/Repositories` as members of multiple groups. This made generated project structure malformed/noisy.

## Verification
```bash
cd macos/TodoFocusMac
xcodegen generate
xcodebuild build -project "TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -configuration Release -derivedDataPath "build/DerivedData" -destination "platform=macOS"
xcodebuild test -project "TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"
```

Results:
- Build succeeded.
- Tests succeeded.
- Duplicate group-membership warnings are no longer emitted.
