# Data Export/Import Feature Design

## Overview

Add Import and Export functionality to the Settings page, allowing users to export all TodoFocus data as a JSON file and import data from a previously exported file.

## Requirements

- **Export Format**: JSON file named `TodoFocus-export.json`
- **Export Scope**: Complete data — all lists, todos, steps, launch resources, focus time records
- **Import Scope**: Full restore (replacement strategy — clears local data before import)
- **UI Location**: Settings page
- **Cross-platform**: JSON format enables future sharing between platforms

## Data Model

### Export JSON Structure

```json
{
  "version": "1.0",
  "exportedAt": "2026-03-25T12:00:00Z",
  "lists": [
    {
      "id": "uuid",
      "name": "Work",
      "color": "#6366F1",
      "sortOrder": 0
    }
  ],
  "todos": [
    {
      "id": "uuid",
      "title": "Task title",
      "isCompleted": false,
      "isImportant": true,
      "isMyDay": false,
      "dueDate": "2026-03-25T00:00:00Z",
      "notes": "Notes text",
      "listId": "uuid",
      "focusTimeSeconds": 3600,
      "steps": [
        {
          "id": "uuid",
          "title": "Step title",
          "isCompleted": false,
          "sortOrder": 0
        }
      ],
      "launchResources": [
        {
          "type": "url",
          "value": "https://example.com"
        }
      ]
    }
  ]
}
```

## Technical Implementation

### New Files

1. **`Data/Export/ExportService.swift`** — Handles serialization to JSON and deserialization from JSON
2. **`Data/Export/ExportModels.swift`** — Codable DTOs for export format

### Modified Files

1. **`Features/Settings/SettingsView.swift`** — Add Import/Export buttons (or find existing settings)
2. **`Data/Database/DatabaseManager.swift`** — Add `clearAllData()` method for import reset
3. **`TodoAppStore`** — Add methods to fetch all data and bulk import

### Architecture

```
ExportService
├── exportToJSON() -> Data
├── importFromJSON(Data)
└── validateImportData(Data) -> Bool

DatabaseManager
├── clearAllTables()
└── importAllData(lists:, todos:)

SettingsView
├── Export Button → NSSavePanel → ExportService.exportToJSON()
└── Import Button → NSOpenPanel → ExportService.importFromJSON()
```

## UI Design

- Two buttons in Settings page:
  - "Export Data" button with download icon
  - "Import Data" button with upload icon
- Export: Opens NSSavePanel, default filename `TodoFocus-export.json`
- Import: Opens NSOpenPanel, filters for `.json` files

## Error Handling

- Invalid JSON format → show alert "Invalid file format"
- Version mismatch → attempt migration or show warning
- Import failure → transaction rollback, preserve existing data
- Empty file → show alert "No data found in file"

## Implementation Steps

1. Create `ExportModels.swift` with Codable structs
2. Create `ExportService.swift` with export/import logic
3. Add `clearAllTables()` to `DatabaseManager`
4. Add `importAllData()` methods to repositories
5. Add Export/Import buttons to Settings view
6. Test export and import round-trip

## Test Plan

- [ ] Export creates valid JSON file
- [ ] Export includes all lists, todos, steps, launch resources
- [ ] Import restores all data correctly
- [ ] Import clears existing data before restoring
- [ ] Invalid file shows appropriate error
