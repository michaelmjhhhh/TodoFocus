# Daily Review MVP Plan

## Goal
Ship a manual Daily Review flow reachable from Sidebar to process all tasks quickly with summary feedback.

## Scope
- Add `Daily Review` entry in Sidebar navigation.
- Add dedicated `DailyReviewView` in main content area.
- Show all tasks in review view (completed + active, with active prioritized).
- Provide quick actions:
  - Mark Done
  - Add to My Day
  - Reschedule (Today / Tomorrow / Next 7 / No Date)
- Display running summary counters in review session UI.

## Out of Scope
- Auto-trigger prompts
- Weekly review workflow
- Calendar integration
- Bulk multi-select operations

## Implementation Steps
1. Extend navigation model
- Add `SidebarSelection.dailyReview`.
- Update `AppModel` selection helpers and active view IDs.
- Add Sidebar row for Daily Review.

2. Add store helpers for review actions
- Add `setMyDay(todoId:isMyDay:)` mutation helper.
- Reuse existing `markComplete(todoId:)` and `setDueDate(todoId:date:)`.

3. Build `DailyReviewView`
- New feature view rendering all tasks.
- Include lightweight summary panel with counters:
  - reviewedCount
  - completedCount
  - rescheduledCount
  - addedToMyDayCount
- Include task rows with action controls and due-date chips.

4. Route main content in `RootView`
- Show `DailyReviewView` when selection is `.dailyReview`.
- Keep existing `TaskListView` for all other selections.

5. Verify
- Run test and release build gates.
- Ensure no behavior regressions in existing list/detail flow.

## Risks
- Selection model changes can affect query paths; mitigate by mapping `.dailyReview` to `.all` smart list and rendering dedicated view in `RootView`.
- Action fatigue in dense rows; mitigate with concise action set and compact layout.
