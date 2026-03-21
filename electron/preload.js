const { contextBridge, ipcRenderer } = require("electron");

// Expose a minimal API to the renderer
contextBridge.exposeInMainWorld("electronAPI", {
  isElectron: true,
  platform: process.platform,
  launchAllForTask: (resources) =>
    ipcRenderer.invoke("launchpad:launch-all", {
      resources,
    }),
});
