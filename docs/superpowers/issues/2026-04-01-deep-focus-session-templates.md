# Deep Focus Session Templates (MVP)

## Goal
Allow users to save reusable Deep Focus presets and apply/start them quickly.

## Scope (MVP)
- Template model: `name`, `duration` (timed/infinite), `blocked apps`.
- Persist templates locally (UserDefaults).
- In `DeepFocusSetupSheet`:
  - list templates
  - apply template to current setup
  - start from template (using current passphrase)
  - save current setup as template
  - rename/delete template

## UX Constraints
- Keep UI lightweight and native macOS style.
- Preserve current start flow and passphrase requirement.

## Acceptance
- Template operations survive app relaunch.
- Applying template updates duration mode and blocked apps selection.
- User can start a focus session from a selected template without reselecting apps.
