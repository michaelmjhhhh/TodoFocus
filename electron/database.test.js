const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const Database = require("better-sqlite3");

const { ensureDatabaseAtPath } = require("./database");

function mkTmpDir() {
  return fs.mkdtempSync(path.join(os.tmpdir(), "todofocus-db-test-"));
}

test("ensureDatabaseAtPath applies all migrations and is idempotent", () => {
  const tmpDir = mkTmpDir();
  const dbPath = path.join(tmpDir, "todofocus.db");
  const migrationsDir = path.join(__dirname, "..", "prisma", "migrations");

  ensureDatabaseAtPath({ dbPath, migrationsDir });
  ensureDatabaseAtPath({ dbPath, migrationsDir });

  const db = new Database(dbPath, { fileMustExist: true });

  const listColumns = db
    .prepare("PRAGMA table_info('List')")
    .all()
    .map((row) => row.name);
  assert.ok(listColumns.includes("id"));
  assert.ok(listColumns.includes("name"));

  const todoColumns = db
    .prepare("PRAGMA table_info('Todo')")
    .all()
    .map((row) => row.name);
  assert.ok(todoColumns.includes("listId"));
  assert.ok(todoColumns.includes("isImportant"));
  assert.ok(todoColumns.includes("isMyDay"));
  assert.ok(todoColumns.includes("recurrence"));
  assert.ok(todoColumns.includes("recurrenceInterval"));
  assert.ok(todoColumns.includes("lastCompletedAt"));

  const stepColumns = db
    .prepare("PRAGMA table_info('Step')")
    .all()
    .map((row) => row.name);
  assert.ok(stepColumns.includes("todoId"));

  const appliedCount = db
    .prepare("SELECT COUNT(*) AS count FROM _zen_migrations")
    .get().count;
  const migrationDirs = fs
    .readdirSync(migrationsDir, { withFileTypes: true })
    .filter((entry) => entry.isDirectory())
    .map((entry) => entry.name)
    .filter((name) => /^\d+_/.test(name));
  assert.equal(appliedCount, migrationDirs.length);

  db.close();
});
