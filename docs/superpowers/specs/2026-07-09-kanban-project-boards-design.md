# Kanban Project Boards Design

## Goal

Add a dedicated Kanban area for long-term project development. Kanban projects and cards are separate from daily TodoFocus tasks so project planning does not clutter My Day, Daily Review, Quick Capture, or focus-task workflows.

## Product Scope

The first release supports multiple named projects. Each project has a fixed five-stage workflow:

1. Backlog
2. Ready
3. In Progress
4. Blocked
5. Done

Cards remain visible in Done until the user archives or deletes them. Users manually order cards by dragging them within and between columns.

## Navigation

- Add a `Kanban` item to the Smart Lists section of the main sidebar.
- Selecting it opens `KanbanView` instead of `TaskListView` or `DailyReviewView`.
- The Kanban header provides a project switcher and controls to create, edit, and delete projects.
- Creating a project requires a name, color, and short goal.
- Selecting a card opens a resizable right-side `KanbanCardDetailView`, following the existing task-detail interaction pattern.
- Kanban cards never appear in daily task lists, Daily Review, Deep Focus, Quick Capture, or task search.

## Architecture

Kanban is a separate module with four layers:

- **Core:** project and card models, workflow status, priority, validation, and ordering rules.
- **Data:** GRDB records, migration, and repositories.
- **App state:** `KanbanStore`, which loads projects and cards, owns selection, and coordinates mutations.
- **Features:** project controls, board, columns, cards, card composer, archive browser, and detail panel.

This boundary keeps project-planning behavior independent of `Todo`, `TodoRepository`, and `TodoAppStore`.

## Data Model

A GRDB migration adds four tables.

### `kanban_project`

- `id`: text primary key
- `name`: non-empty text
- `color`: validated `#RRGGBB` value
- `goal`: non-empty text
- `createdAt`: date
- `updatedAt`: date

### `kanban_card`

- `id`: text primary key
- `projectId`: required foreign key to `kanban_project`
- `title`: non-empty text
- `description`: text
- `status`: `backlog`, `ready`, `inProgress`, `blocked`, or `done`
- `priority`: `low`, `medium`, `high`, or `urgent`
- `dueDate`: optional date
- `sortOrder`: integer
- `isArchived`: boolean, default false
- `createdAt`: date
- `updatedAt`: date

### `kanban_card_label`

- `id`: text primary key
- `cardId`: required foreign key to `kanban_card`
- `name`: non-empty text
- `sortOrder`: integer

### `kanban_checklist_item`

- `id`: text primary key
- `cardId`: required foreign key to `kanban_card`
- `title`: non-empty text
- `isCompleted`: boolean
- `sortOrder`: integer

Deleting a project cascades to its cards, labels, and checklist items. Deleting a card cascades to its labels and checklist items. Indexes support project/status/order board queries and card-child ordering.

## State and Data Flow

- `KanbanStore` loads project summaries alphabetically and keeps the selected project for the current app session. On first entry, it selects the first project alphabetically.
- Selecting a project loads its active cards, labels, and checklist data.
- A new card enters Backlog at the bottom of that column unless created from another column's Add Card action.
- Card order is represented by dense, zero-based `sortOrder` values within each project and status.
- Dragging within a column renormalizes that column's order in one database transaction.
- Dragging between columns updates status and renormalizes both affected columns in one database transaction.
- Moving a card to Done does not archive it.
- Archiving removes a card from the active board. An Archived Cards sheet supports restoration or permanent deletion. Restoring returns the card to the bottom of its retained status column.
- Repository mutations succeed before committed in-memory state is published. A failed drag restores the previous card position.
- Deleting the selected card closes its detail panel. Deleting the selected project closes the panel and selects the first remaining project alphabetically; if none remain, the empty-project state appears.

## Board UI

- Render five fixed-width columns in workflow order within a horizontal scroll view.
- Each column shows its title, active-card count, and Add Card action.
- Cards show title, priority, optional due date, labels, and checklist progress.
- Full descriptions and checklist editing remain in the detail panel.
- Drop targets use a clear terracotta highlight. The dragged card retains enough context to make its destination understandable.
- Empty projects and empty columns provide explicit creation prompts.
- Project color appears in the project switcher and board header while preserving the existing warm editorial theme.

## Card Detail Panel

The detail panel supports:

- title
- description
- priority
- optional due date
- labels
- checklist items
- a non-drag status control
- archive and delete actions

Project names and card titles persist on submit or focus loss. Multiline project goals and card descriptions persist after a 300-millisecond debounce. Labels and checklist items persist through explicit add, edit, toggle, reorder, and delete actions. Status, priority, due date, archive, and delete actions persist immediately.

## Accessibility and Keyboard Behavior

- All project, column, card, and action controls are keyboard accessible.
- Cards and columns expose descriptive accessibility labels, including status, priority, due date, and checklist progress.
- The detail panel's status control provides a complete alternative to drag-and-drop.
- Destructive project and card deletion require explicit confirmation.
- Focus order follows project controls, columns from left to right, cards from top to bottom, then the detail panel.

## Validation and Error Handling

- Trim project names, project goals, card titles, label names, and checklist titles; reject empty values.
- Limit project names to 100 characters and project goals to 500 characters.
- Limit card titles to 200 characters and card descriptions to 10,000 characters.
- Limit label names to 40 characters and each card to 10 labels.
- Limit checklist titles to 200 characters and each card to 50 checklist items.
- Validate project colors as six-digit hexadecimal values in `#RRGGBB` form.
- Invalid persisted status values display the card in Backlog; invalid priority values display Medium. Either fallback raises a dismissible data-repair banner.
- Encode all limits and fallback rules as named validation constants with unit tests.
- Board mutations are transactional. Failed persistence leaves or restores the UI to the last confirmed state.
- Repository failures appear in a dismissible inline board banner. Retry is offered only for idempotent loads and updates, never for destructive operations.

## Testing Strategy

### Migration tests

- Required tables, columns, indexes, defaults, and foreign keys exist.
- Project and card cascade deletion behaves correctly.
- Existing databases migrate without affecting todo data.

### Repository tests

- Project create, read, update, and delete.
- Card create, read, update, archive, restore, and delete.
- Manual ordering within a column.
- Transactional moves between columns.
- Label and checklist CRUD and ordering.

### Core and store tests

- Fixed workflow ordering and priority decoding.
- Field validation and reorder calculations.
- Project switching and card selection cleanup.
- Failed-mutation rollback and error propagation.
- Correct fallback when the selected project is deleted.

### View behavior tests

- Five columns render in the defined order.
- Counts and empty states remain accurate.
- Cards display the required summary fields.
- The non-drag status control can perform every workflow transition.

### Manual user-flow validation

1. Create two projects with distinct colors and goals.
2. Add and edit cards in both projects.
3. Reorder cards within a column and move them across columns.
4. Restart the app and confirm project, status, and ordering persistence.
5. Edit labels and checklist items.
6. Move a card to Done and confirm it remains visible.
7. Archive and restore a card.
8. Delete a card and a project through confirmation flows.
9. Confirm Kanban cards never appear in daily task views.

Run the full macOS test suite and a Release build after implementation.

## Non-Goals for Version 1

- Custom columns or column renaming
- Collaboration, assignees, or cloud synchronization
- Links between Kanban cards and daily tasks
- Deep Focus or Launchpad integration
- GitHub issue or pull-request synchronization
- Project templates, analytics, estimates, or repository metadata
- Changes to the existing Daily Review board
