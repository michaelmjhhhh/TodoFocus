# Test Suite Regression: MainActor/API Drift Causes `xcodebuild test` Failure

## Summary
`xcodebuild test` currently fails at compile time in `CoreTests` due to drift between production API changes and test code assumptions.

## Reproduction
From repo root:

```bash
cd macos/TodoFocusMac
xcodegen generate
xcodebuild test -project "TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"
```

## Observed Failures
1. Main actor isolation violations in test files using `AppModel` from non-`@MainActor` test contexts.
2. `DeepFocusService.startSession` signature mismatch (`duration` parameter now required).
3. `DeepFocusService.stats` access in tests despite `stats` being `private`.
4. `CoreTodo` initializer mismatch in tests after adding `isCompleted` field.

## Root Cause
Recent production changes tightened actor isolation and updated model/service APIs, but related tests were not updated in lockstep.

## Scope
- `Tests/CoreTests/AppModelTests.swift`
- `Tests/CoreTests/AppSelectionStateTests.swift`
- `Tests/CoreTests/DeepFocusServiceTests.swift`
- `Tests/CoreTests/TodoQueryTests.swift`

## Acceptance Criteria
- `xcodebuild test -project "TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"` passes.
- Changes are limited to test compatibility updates and do not alter production behavior.
- Test assertions for Deep Focus stats rely on public behavior (`DeepFocusReport`) rather than private internals.

## Notes
Separate warning exists in Xcode project generation regarding duplicate group memberships for `Sources/Data/*` paths. This issue tracks test failures only.
