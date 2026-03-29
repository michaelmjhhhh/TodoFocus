---
name: todofocus-workflow
description: Execute TodoFocus end-to-end delivery workflow with mandatory gates for this repo. Use when implementing features, fixing bugs, polishing UI, doing refactors, or shipping release-quality changes. Trigger when requests involve requirement clarification, plan writing, issue/branch/PR flow, skill routing, systematic debugging, SwiftUI/UI polish, TDD, subagent parallelization, verification, and final commit/push/PR.
---

# TodoFocus Workflow

## Objective
Run one consistent path from request to PR: clarify -> plan -> issue -> branch -> implement -> verify -> commit/push -> PR.

## Non-Negotiable Gates
1. Run `brainstorming` before implementation to clarify requirements.
2. Run `writing-plans` before non-trivial implementation.
3. Run `systematic-debugging` before any bug fix or unexpected behavior change.
4. Run verification commands before any completion claim.

## Required Sequence
1. **Clarify (`brainstorming`)**
   - Ask targeted questions until scope and success criteria are explicit.
   - Do not start coding before user confirmation.
2. **Plan (`writing-plans`)**
   - For non-trivial work, write plan doc:
     - `docs/superpowers/plans/YYYY-MM-DD-<topic>.md`
3. **Issue (`gh-cli`)**
   - Write/update issue doc:
     - `docs/superpowers/issues/YYYY-MM-DD-<topic>.md`
   - Create GitHub issue from that document.
4. **Branch (`gh-cli` + git)**
   - Create branch from `main`:
     - `feat/<issue>-<topic>` for features
     - `fix/<issue>-<topic>` for fixes
5. **Route Skills (mandatory decision before coding)**
   - Choose execution skills with the routing table below.
6. **Implement**
   - Keep edits focused and minimal; avoid unrelated refactors.
7. **Verify (`verification-before-completion`)**
   - Run required test/build gates and capture explicit outcomes.
8. **PR Artifact**
   - Write PR doc:
     - `docs/superpowers/prs/YYYY-MM-DD-<topic>.md`
   - Include: `Closes #<issue>`, change summary, verification commands, verification results.
9. **Ship (`git-commit` + `gh-cli`)**
   - Create commit with `git-commit` skill.
   - Push branch and open PR using PR markdown body.

## Skill Routing Table
Apply all matching rules.

- **Bug / regression / failing behavior**
  - Required first: `systematic-debugging`
- **UI/UX work (Task list/detail/sheets/menu bar, etc.)**
  - Required: `swiftui-expert-skill` + `ui-ux-pro-max`
- **Logic with regression risk or fragile behavior**
  - Default: `test-driven-development`
- **Large/non-trivial work with independent chunks**
  - Use: `subagent-driven-development`
  - Parallel workers must use model: `gpt-5.3-codex`
- **About to claim done/passing/fixed**
  - Required: `verification-before-completion`

## Subagent Constraints
- Split ownership by disjoint file sets.
- Tell workers they are not alone in the repo and must not revert others' edits.
- Keep immediate critical-path work local when waiting would block progress.

## SwiftUI / UX Constraints
- Reuse `ThemeTokens` and `MotionTokens`; avoid hardcoded visual constants.
- Preserve smooth, deterministic interactions and macOS-native behavior.
- Maintain accessibility labels and keyboard interaction parity.

## Verification Commands
Run before completion claims and before final PR handoff:
- `xcodegen generate` (inside `macos/TodoFocusMac` when project regen is needed)
- `xcodebuild test -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -destination "platform=macOS"`
- `xcodebuild build -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" -scheme "TodoFocusMac" -configuration Release -derivedDataPath "macos/TodoFocusMac/build/DerivedData" -destination "platform=macOS"`

Record exact success markers in PR doc:
- `** TEST SUCCEEDED **`
- `** BUILD SUCCEEDED **`

## Required Artifacts
- Issue doc: `docs/superpowers/issues/...`
- Plan doc (non-trivial): `docs/superpowers/plans/...`
- PR doc: `docs/superpowers/prs/...`

Use `references/checklist.md` to track execution quality.
