type LaunchpadResourceType = "url" | "file" | "app";

type LaunchpadResource = {
  id: string;
  type: LaunchpadResourceType;
  value: string;
};

type LaunchpadItemResult = {
  id: string;
  status: "launched" | "rejected" | "failed";
  reason?: string;
};

type LaunchpadInvokeResult = {
  ok: boolean;
  launchedCount: number;
  results: LaunchpadItemResult[];
  reason?: string;
};

interface ElectronAPI {
  isElectron: true;
  platform: NodeJS.Platform;
  launchAllForTask: (resources: LaunchpadResource[]) => Promise<LaunchpadInvokeResult>;
}

declare global {
  interface Window {
    electronAPI?: ElectronAPI;
  }
}

export {};
