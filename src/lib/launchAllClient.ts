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
  results?: LaunchpadItemResult[];
  reason?: string;
};

type LaunchAllClientDeps = {
  isDesktopApp: () => boolean;
  launchAllFromDesktop: ((resources: LaunchpadResource[]) => Promise<LaunchpadInvokeResult>) | null;
};

export type LaunchAllClientResult =
  | {
      ok: true;
      launchedCount: number;
      results: LaunchpadItemResult[];
    }
  | {
      ok: false;
      reason: "desktop_only" | "empty" | "unavailable" | "failed";
      launchedCount: number;
      results: LaunchpadItemResult[];
    };

function parseLaunchResourcesForClient(raw: string): LaunchpadResource[] {
  if (typeof raw !== "string" || raw.trim().length === 0) {
    return [];
  }

  let parsed: unknown;
  try {
    parsed = JSON.parse(raw);
  } catch {
    return [];
  }

  if (!Array.isArray(parsed)) {
    return [];
  }

  const resources: LaunchpadResource[] = [];
  for (const item of parsed) {
    if (resources.length >= 12) {
      break;
    }

    if (!item || typeof item !== "object") {
      continue;
    }

    const candidate = item as Record<string, unknown>;
    if (
      typeof candidate.id !== "string" ||
      (candidate.type !== "url" && candidate.type !== "file" && candidate.type !== "app") ||
      typeof candidate.value !== "string"
    ) {
      continue;
    }

    const id = candidate.id.trim();
    const value = candidate.value.trim();
    if (!id || !value) {
      continue;
    }

    resources.push({
      id,
      type: candidate.type,
      value,
    });
  }

  return resources;
}

function getDefaultDeps(): LaunchAllClientDeps {
  if (typeof window === "undefined") {
    return { isDesktopApp: () => false, launchAllFromDesktop: null };
  }

  const electronAPI = window.electronAPI;

  return {
    isDesktopApp: () => Boolean(electronAPI?.isElectron),
    launchAllFromDesktop: electronAPI
      ? (resources) => electronAPI.launchAllForTask(resources)
      : null,
  };
}

export async function launchAllClient(
  rawResources: string,
  depsOverride?: Partial<LaunchAllClientDeps>
): Promise<LaunchAllClientResult> {
  const defaultDeps = getDefaultDeps();
  const deps: LaunchAllClientDeps = {
    ...defaultDeps,
    ...depsOverride,
  };

  if (!deps.isDesktopApp()) {
    return { ok: false, reason: "desktop_only", launchedCount: 0, results: [] };
  }

  const parsed = parseLaunchResourcesForClient(rawResources);
  if (parsed.length === 0) {
    return { ok: false, reason: "empty", launchedCount: 0, results: [] };
  }

  if (!deps.launchAllFromDesktop) {
    return { ok: false, reason: "unavailable", launchedCount: 0, results: [] };
  }

  try {
    const invokeResult = await deps.launchAllFromDesktop(parsed);

    if (!invokeResult.ok) {
      return {
        ok: false,
        reason: "failed",
        launchedCount: invokeResult.launchedCount ?? 0,
        results: invokeResult.results ?? [],
      };
    }

    return {
      ok: true,
      launchedCount: invokeResult.launchedCount,
      results: invokeResult.results ?? [],
    };
  } catch {
    return { ok: false, reason: "failed", launchedCount: 0, results: [] };
  }
}
