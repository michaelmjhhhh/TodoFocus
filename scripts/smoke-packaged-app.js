#!/usr/bin/env node

const path = require("node:path");
const { spawn } = require("node:child_process");

const appPath = path.resolve(
  process.env.TODOFOCUS_APP_PATH ||
    "dist-electron/mac-arm64/TodoFocus.app/Contents/MacOS/TodoFocus"
);

const timeoutMs = Number(process.env.TODOFOCUS_SMOKE_TIMEOUT_MS || 45000);
const start = Date.now();

let resolvedPort = null;
let ready = false;
let sawStartupFailure = false;

const child = spawn(appPath, [], {
  env: { ...process.env },
  stdio: ["ignore", "pipe", "pipe"],
});

function consume(chunk) {
  const text = chunk.toString();
  process.stdout.write(text);

  if (text.includes("[electron] app startup failed")) {
    sawStartupFailure = true;
  }
  if (text.includes("NODE_MODULE_VERSION")) {
    sawStartupFailure = true;
  }

  const localMatch = text.match(/Local:\s+http:\/\/127\.0\.0\.1:(\d+)/);
  if (localMatch) {
    resolvedPort = Number(localMatch[1]);
  }
  if (text.includes("Ready in")) {
    ready = true;
  }
}

child.stdout.on("data", consume);
child.stderr.on("data", consume);

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function pollHttp() {
  if (!resolvedPort) return false;
  try {
    const res = await fetch(`http://127.0.0.1:${resolvedPort}`);
    return res.status === 200;
  } catch {
    return false;
  }
}

async function run() {
  try {
    while (Date.now() - start < timeoutMs) {
      if (sawStartupFailure) {
        throw new Error("Detected startup failure in packaged app logs");
      }
      if (ready && (await pollHttp())) {
        console.log(`[smoke] Packaged app responded with HTTP 200 on port ${resolvedPort}`);
        return;
      }
      await sleep(500);
    }
    throw new Error("Timed out waiting for packaged app readiness");
  } finally {
    if (!child.killed) {
      child.kill("SIGTERM");
    }
  }
}

run().catch((error) => {
  console.error(`[smoke] ${error.message}`);
  process.exit(1);
});
