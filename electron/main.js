const { app, BrowserWindow, shell } = require("electron");
const path = require("path");
const { spawn } = require("child_process");
const net = require("net");

// Keep a global reference of the window object to prevent GC
let mainWindow = null;
let nextProcess = null;

const isDev = process.env.NODE_ENV === "development";
const PORT = 3000;

// SQLite database path: use app's userData directory so it persists
// across updates and is specific to this app
function getDbPath() {
  const userDataPath = app.getPath("userData");
  return path.join(userDataPath, "zen.db");
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

  // In production, start the standalone Next.js server
  const serverPath = path.join(
    process.resourcesPath,
    "standalone",
    "server.js"
  );

  nextProcess = spawn(process.execPath, [serverPath], {
    env: {
      ...process.env,
      PORT: String(PORT),
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
}

app.whenReady().then(async () => {
  await ensureDatabase();
  await startNextServer();

  if (!isDev) {
    await waitForPort(PORT);
  }

  createWindow();
  mainWindow.loadURL(`http://127.0.0.1:${PORT}`);

  app.on("activate", () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createWindow();
      mainWindow.loadURL(`http://127.0.0.1:${PORT}`);
    }
  });
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
