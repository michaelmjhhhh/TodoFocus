const { contextBridge, ipcRenderer } = require("electron");

// Expose a minimal API to the renderer
contextBridge.exposeInMainWorld("electronAPI", {
  isElectron: true,
  platform: process.platform,
  pickLaunchFile: () => ipcRenderer.invoke("launchpad:pick-file"),
  pickLaunchApp: () => ipcRenderer.invoke("launchpad:pick-app"),
  launchAllForTask: (resources) =>
    ipcRenderer.invoke("launchpad:launch-all", {
      resources,
    }),
});
