#!/usr/bin/env node

const { existsSync } = require("node:fs");
const path = require("node:path");
const { spawnSync } = require("node:child_process");

function fail(message) {
  console.error(`[abi-check] ${message}`);
  process.exit(1);
}

const appPath = path.resolve(
  process.env.TODOFOCUS_APP_PATH ||
    "dist-electron/mac-arm64/TodoFocus.app/Contents/MacOS/TodoFocus"
);

const nativeModulePath = path.resolve(
  process.env.TODOFOCUS_NATIVE_MODULE_PATH ||
    "dist-electron/mac-arm64/TodoFocus.app/Contents/Resources/app.asar.unpacked/node_modules/better-sqlite3/build/Release/better_sqlite3.node"
);

const standaloneNativeModulePath = path.resolve(
  process.env.TODOFOCUS_STANDALONE_NATIVE_MODULE_PATH ||
    "dist-electron/mac-arm64/TodoFocus.app/Contents/Resources/app.asar.unpacked/.next/standalone/node_modules/better-sqlite3/build/Release/better_sqlite3.node"
);

if (!existsSync(appPath)) {
  fail(`App binary not found at ${appPath}`);
}

if (!existsSync(nativeModulePath)) {
  fail(`Native module not found at ${nativeModulePath}`);
}

if (!existsSync(standaloneNativeModulePath)) {
  fail(`Standalone native module not found at ${standaloneNativeModulePath}`);
}

const electronAbi = spawnSync(
  appPath,
  ["-e", "console.log(process.versions.modules)"],
  {
    env: { ...process.env, ELECTRON_RUN_AS_NODE: "1" },
    encoding: "utf8",
  }
);

if (electronAbi.status !== 0) {
  fail(`Failed to read Electron ABI: ${electronAbi.stderr || electronAbi.stdout}`);
}

const abi = electronAbi.stdout.trim();
if (!abi) {
  fail("Electron ABI was empty");
}

const loadResult = spawnSync(
  appPath,
  [
    "-e",
    `require(${JSON.stringify(nativeModulePath)}); console.log('ABI_OK')`,
  ],
  {
    env: { ...process.env, ELECTRON_RUN_AS_NODE: "1" },
    encoding: "utf8",
  }
);

if (loadResult.status !== 0 || !loadResult.stdout.includes("ABI_OK")) {
  fail(
    [
      `Native module failed to load with Electron ABI ${abi}.`,
      loadResult.stderr || loadResult.stdout,
    ]
      .filter(Boolean)
      .join("\n")
  );
}

const standaloneLoadResult = spawnSync(
  appPath,
  [
    "-e",
    `require(${JSON.stringify(standaloneNativeModulePath)}); console.log('STANDALONE_ABI_OK')`,
  ],
  {
    env: { ...process.env, ELECTRON_RUN_AS_NODE: "1" },
    encoding: "utf8",
  }
);

if (
  standaloneLoadResult.status !== 0 ||
  !standaloneLoadResult.stdout.includes("STANDALONE_ABI_OK")
) {
  fail(
    [
      `Standalone native module failed to load with Electron ABI ${abi}.`,
      standaloneLoadResult.stderr || standaloneLoadResult.stdout,
    ]
      .filter(Boolean)
      .join("\n")
  );
}

console.log(`[abi-check] Electron ABI ${abi} can load better-sqlite3`);
