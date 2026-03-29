# Feature: Deep Focus Menu Bar Status Panel (macOS)

## Summary
Add a native macOS Menu Bar status entry for Deep Focus using SwiftUI `MenuBarExtra`.

## Goals
- Show real-time Deep Focus status directly from menu bar.
- Provide quick actions:
  - Open TodoFocus main window.
  - End current Deep Focus session.
  - Quit app.
- Keep existing Deep Focus/Hard Focus logic unchanged.

## UX / Visual Requirements
- Must feel smooth and responsive (no badge flicker / jumpy width changes).
- Reuse existing app visual language:
  - `ThemeTokens` (`panelBackground`, `sectionBorder`, `textPrimary`, `textSecondary`, `accentTerracotta`)
  - `MotionTokens` (`hoverEase`, `focusEase`, `panelSpring`)
- Keep click targets >= 44pt and keyboard accessible labels.

## Functional Requirements
- Use `MenuBarExtra(...).menuBarExtraStyle(.window)`.
- Read state from existing observable chain: `AppModel.deepFocusService` + `TodoAppStore`.
- Support timed sessions with compact remaining-time badge in menu bar label.
- `End Deep Focus` disabled when no active session.
- `Open TodoFocus` should reliably bring app to front and open/create main window.

## Technical Constraints
- SwiftUI-first implementation.
- Use `swiftui-expert-skill` and `ui-ux-pro-max` standards.
- No behavior changes to focus session business rules.
- Follow TDD for new mapping logic.

## Acceptance Criteria
- Menu bar status appears and updates correctly when Deep Focus starts/ends.
- Timed session badge updates smoothly.
- End Focus action calls existing store end flow and works safely.
- Open action reliably foregrounds main window.
- Full test suite and release build pass.
