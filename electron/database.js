const fs = require("node:fs");
const path = require("node:path");
const Database = require("better-sqlite3");

function listMigrationFiles(migrationsDir) {
  const entries = fs
    .readdirSync(migrationsDir, { withFileTypes: true })
    .filter((entry) => entry.isDirectory())
    .map((entry) => entry.name)
    .sort();

  return entries.map((dirName) => ({
    id: dirName,
    filePath: path.join(migrationsDir, dirName, "migration.sql"),
  }));
}

function ensureMetaTable(db) {
  db.exec(`
    CREATE TABLE IF NOT EXISTS _zen_migrations (
      id TEXT PRIMARY KEY,
      appliedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
    );
  `);
}

function applyMigration(db, migration) {
  const exists = db
    .prepare("SELECT 1 FROM _zen_migrations WHERE id = ? LIMIT 1")
    .get(migration.id);

  if (exists) {
    return;
  }

  const sql = fs.readFileSync(migration.filePath, "utf8");

  const run = db.transaction(() => {
    db.exec(sql);
    db.prepare("INSERT INTO _zen_migrations (id) VALUES (?)").run(migration.id);
  });

  run();
}

function ensureDatabaseAtPath({ dbPath, migrationsDir }) {
  const db = new Database(dbPath);
  try {
    ensureMetaTable(db);
    const migrations = listMigrationFiles(migrationsDir);
    for (const migration of migrations) {
      applyMigration(db, migration);
    }
  } finally {
    db.close();
  }
}

module.exports = {
  ensureDatabaseAtPath,
};
