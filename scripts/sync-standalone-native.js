#!/usr/bin/env node

const fs = require("node:fs");
const path = require("node:path");

const rootReleaseDir = path.resolve(
  "node_modules/better-sqlite3/build/Release"
);
const standaloneReleaseDir = path.resolve(
  ".next/standalone/node_modules/better-sqlite3/build/Release"
);

function fail(message) {
  console.error(`[sync-standalone-native] ${message}`);
  process.exit(1);
}

if (!fs.existsSync(rootReleaseDir)) {
  fail(`Root native release directory not found: ${rootReleaseDir}`);
}

fs.mkdirSync(standaloneReleaseDir, { recursive: true });
fs.cpSync(rootReleaseDir, standaloneReleaseDir, { recursive: true, force: true });

const rootNode = path.join(rootReleaseDir, "better_sqlite3.node");
const standaloneNode = path.join(standaloneReleaseDir, "better_sqlite3.node");

if (!fs.existsSync(standaloneNode)) {
  fail(`Standalone native module missing after sync: ${standaloneNode}`);
}

const rootStat = fs.statSync(rootNode);
const standaloneStat = fs.statSync(standaloneNode);

console.log(
  `[sync-standalone-native] synced better-sqlite3 (${rootStat.size} bytes -> ${standaloneStat.size} bytes)`
);
