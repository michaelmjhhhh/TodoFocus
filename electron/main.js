const { app, BrowserWindow, shell, dialog } = require("electron");
const path = require("path");
const { spawn } = require("child_process");
const net = require("net");
const { ensureDatabaseAtPath } = require("./database");

// Keep a global reference of the window object to prevent GC
let mainWindow = null;
let nextProcess = null;

const isDev = process.env.NODE_ENV === "development";
const DEFAULT_PORT = 3000;
let serverPort = DEFAULT_PORT;

// SQLite database path: use app's userData directory so it persists
// across updates and is specific to this app
function getDbPath() {
  const userDataPath = app.getPath("userData");
  return path.join(userDataPath, "todofocus.db");
}

function getDbUrl() {
  return `file:${getDbPath()}`;
}

// Wait for a port to become available
function waitForPort(port, timeout = 30000) {
  return new Promise((resolve, reject) => {
    const start = Date.now();
    function check() {
      const socket = new net.Socket();
      socket.setTimeout(500);
      socket.on("connect", () => {
        socket.destroy();
        resolve();
      });
      socket.on("error", () => {
        socket.destroy();
        if (Date.now() - start > timeout) {
          reject(new Error(`Timeout waiting for port ${port}`));
        } else {
          setTimeout(check, 200);
        }
      });
      socket.on("timeout", () => {
        socket.destroy();
        if (Date.now() - start > timeout) {
          reject(new Error(`Timeout waiting for port ${port}`));
        } else {
          setTimeout(check, 200);
        }
      });
      socket.connect(port, "127.0.0.1");
    }
    check();
  });
}

function getAvailablePort(preferredPort) {
  return new Promise((resolve, reject) => {
    const server = net.createServer();
    server.unref();
    server.on("error", (err) => {
      reject(err);
    });
    server.listen(preferredPort, "127.0.0.1", () => {
      const address = server.address();
      if (!address || typeof address === "string") {
        server.close(() => reject(new Error("Failed to resolve available port")));
        return;
      }
      const { port } = address;
      server.close(() => resolve(port));
    });
  });
}

async function resolveServerPort() {
  if (isDev) return DEFAULT_PORT;
  try {
    return await getAvailablePort(DEFAULT_PORT);
  } catch {
    return await getAvailablePort(0);
  }
}

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1200,
    height: 800,
    minWidth: 800,
    minHeight: 600,
    titleBarStyle: "hiddenInset",
    trafficLightPosition: { x: 16, y: 16 },
    backgroundColor: "#09090B",
    show: false,
    webPreferences: {
      preload: path.join(__dirname, "preload.js"),
      contextIsolation: true,
      nodeIntegration: false,
    },
  });

  // Graceful show when ready
  mainWindow.once("ready-to-show", () => {
    mainWindow.show();
  });

  // Open external links in default browser
  mainWindow.webContents.setWindowOpenHandler(({ url }) => {
    shell.openExternal(url);
    return { action: "deny" };
  });

  mainWindow.on("closed", () => {
    mainWindow = null;
  });
}

async function startNextServer() {
  if (isDev) {
    // In dev mode, we expect Next.js dev server to already be running
    return;
  }

  // Use Next standalone server entry.
  const serverPath = app.isPackaged
    ? path.join(process.resourcesPath, "app", ".next", "standalone", "server.js")
    : path.join(__dirname, "..", ".next", "standalone", "server.js");

  console.log("[electron] Starting Next.js from:", serverPath);

  nextProcess = spawn(process.execPath, [serverPath], {
    cwd: path.dirname(serverPath),
    env: {
      ...process.env,
      ELECTRON_RUN_AS_NODE: "1",
      PORT: String(serverPort),
      HOSTNAME: "127.0.0.1",
      NODE_ENV: "production",
      DATABASE_URL: getDbUrl(),
    },
    stdio: "pipe",
  });

  nextProcess.stdout.on("data", (data) => {
    console.log(`[next] ${data.toString().trim()}`);
  });

  nextProcess.stderr.on("data", (data) => {
    console.error(`[next] ${data.toString().trim()}`);
  });

  nextProcess.on("error", (err) => {
    console.error("Failed to start Next.js server:", err);
  });

  nextProcess.on("exit", (code, signal) => {
    console.error(`[next] exited with code=${code} signal=${signal}`);
  });
}

// Ensure the database directory exists and run migrations if needed
async function ensureDatabase() {
  const fs = require("fs");
  const dbPath = getDbPath();
  const dbDir = path.dirname(dbPath);

  if (!fs.existsSync(dbDir)) {
    fs.mkdirSync(dbDir, { recursive: true });
  }

  // Set DATABASE_URL for the current process so Prisma picks it up
  process.env.DATABASE_URL = getDbUrl();

  const migrationsDir = app.isPackaged
    ? path.join(process.resourcesPath, "app", "prisma", "migrations")
    : path.join(__dirname, "..", "prisma", "migrations");

  ensureDatabaseAtPath({ dbPath, migrationsDir });
}

app.whenReady().then(async () => {
  try {
    await ensureDatabase();
    serverPort = await resolveServerPort();
    await startNextServer();

    if (!isDev) {
      await waitForPort(serverPort);
    }

    createWindow();
    mainWindow.loadURL(`http://127.0.0.1:${serverPort}`);

    app.on("activate", () => {
      if (BrowserWindow.getAllWindows().length === 0) {
        createWindow();
        mainWindow.loadURL(`http://127.0.0.1:${serverPort}`);
      }
    });
  } catch (error) {
    const message = error instanceof Error ? error.stack || error.message : String(error);
    console.error("[electron] app startup failed:\n", message);
    dialog.showErrorBox("Failed to start Zen", message);
    app.quit();
  }
});

app.on("window-all-closed", () => {
  if (process.platform !== "darwin") {
    app.quit();
  }
});

app.on("before-quit", () => {
  if (nextProcess) {
    nextProcess.kill();
    nextProcess = null;
  }
});
