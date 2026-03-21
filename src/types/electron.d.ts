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

type LaunchpadPickResult =
  | {
      ok: true;
      value: string;
    }
  | {
      ok: false;
      canceled: boolean;
      reason: string;
    };

interface ElectronAPI {
  isElectron: true;
  platform: NodeJS.Platform;
  pickLaunchFile: () => Promise<LaunchpadPickResult>;
  pickLaunchApp: () => Promise<LaunchpadPickResult>;
  launchAllForTask: (resources: LaunchpadResource[]) => Promise<LaunchpadInvokeResult>;
}

declare global {
  interface Window {
    electronAPI?: ElectronAPI;
  }
}

export {};
