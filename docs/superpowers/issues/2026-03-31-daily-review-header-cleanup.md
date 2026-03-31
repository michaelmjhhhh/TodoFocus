# Daily Review Header Cleanup

## Problems
1. The summary stats bar below the Daily Review title is visually noisy and redundant.
2. `Open` lane header icon color is inconsistent with `Completed` lane styling.

## Scope
- Remove the summary stats strip from Daily Review.
- Unify lane header icon color between `Open` and `Completed`.

## Acceptance Criteria
- No summary stats strip under the title.
- Open and Completed lane headers share the same icon color style.
- No regression in board grouping or card actions.
