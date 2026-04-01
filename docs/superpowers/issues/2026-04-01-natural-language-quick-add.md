# Natural Language Quick Add (English)

## Goal
Support natural-language quick add input so users can type one command and get task metadata applied automatically.

## Scope (MVP)
- Parse date tokens: `today`, `tomorrow`, `next week`, weekday short/full names (`mon`..`sun`, `monday`..`sunday`).
- Parse time token: `9am`, `9:30am`, `21:15`.
- Parse flags: `!` / `!high` => important, `@myday` => my day.
- Parse list token: `#listName` (apply only if matching existing list name; otherwise ignore token and keep default list context).
- Remove parsed tokens from title before creating task.
- If due date is parsed, persist exact due date (not default planned-now behavior).

## Rules
- English-only parsing.
- Keep existing quick-add behavior when no parse tokens are present.
- If token-stripped title is empty, keep current validation behavior (reject empty title).

## Acceptance
- Quick add command can create task with inferred due date/time, flags, and list.
- Existing quick add tests remain green.
- New parser and integration tests cover supported syntax.
