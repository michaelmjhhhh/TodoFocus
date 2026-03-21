const path = require("node:path");

const MAX_LAUNCH_ITEMS = 12;
const URL_PROTOCOL_ALLOWLIST = new Set(["http:", "https:"]);
const APP_PROTOCOL_DENYLIST = new Set(["javascript:", "data:", "file:"]);

function normalizeString(value) {
  if (typeof value !== "string") {
    return "";
  }
  return value.trim();
}

function sanitizeUrl(value) {
  const raw = normalizeString(value);
  if (!raw) {
    return { ok: false, reason: "empty-url" };
  }

  let parsed;
  try {
    parsed = new URL(raw);
  } catch {
    return { ok: false, reason: "invalid-url" };
  }

  if (!URL_PROTOCOL_ALLOWLIST.has(parsed.protocol)) {
    return { ok: false, reason: "disallowed-url-protocol" };
  }

  return { ok: true, value: parsed.toString() };
}

function sanitizeFilePath(value) {
  const raw = normalizeString(value);
  if (!raw) {
    return { ok: false, reason: "empty-path" };
  }
  if (raw.includes("\0")) {
    return { ok: false, reason: "invalid-path" };
  }
  if (!path.isAbsolute(raw)) {
    return { ok: false, reason: "path-must-be-absolute" };
  }

  return { ok: true, value: path.normalize(raw) };
}

function sanitizeAppTarget(value) {
  const raw = normalizeString(value);
  if (!raw) {
    return { ok: false, reason: "empty-app-target" };
  }

  if (path.isAbsolute(raw)) {
    return { ok: true, value: path.normalize(raw), mode: "path" };
  }

  let parsed;
  try {
    parsed = new URL(raw);
  } catch {
    return { ok: false, reason: "invalid-app-target" };
  }

  if (APP_PROTOCOL_DENYLIST.has(parsed.protocol)) {
    return { ok: false, reason: "disallowed-app-protocol" };
  }

  return { ok: true, value: parsed.toString(), mode: "external" };
}

function validateResource(resource) {
  if (!resource || typeof resource !== "object") {
    return { ok: false, reason: "invalid-resource" };
  }

  const id = normalizeString(resource.id);
  const type = normalizeString(resource.type);
  const value = normalizeString(resource.value);

  if (!id) {
    return { ok: false, reason: "missing-id" };
  }
  if (!value) {
    return { ok: false, reason: "missing-value" };
  }
  if (!["url", "file", "app"].includes(type)) {
    return { ok: false, reason: "invalid-type", id };
  }

  if (type === "url") {
    const sanitized = sanitizeUrl(value);
    if (!sanitized.ok) {
      return { ok: false, reason: sanitized.reason, id };
    }
    return { ok: true, id, type, value: sanitized.value };
  }

  if (type === "file") {
    const sanitized = sanitizeFilePath(value);
    if (!sanitized.ok) {
      return { ok: false, reason: sanitized.reason, id };
    }
    return { ok: true, id, type, value: sanitized.value };
  }

  const sanitized = sanitizeAppTarget(value);
  if (!sanitized.ok) {
    return { ok: false, reason: sanitized.reason, id };
  }
  return { ok: true, id, type, value: sanitized.value, mode: sanitized.mode };
}

function getDeps(deps = {}) {
  return {
    openExternal:
      typeof deps.openExternal === "function"
        ? deps.openExternal
        : async () => {
            throw new Error("openExternal dependency missing");
          },
    openPath:
      typeof deps.openPath === "function"
        ? deps.openPath
        : async () => {
            throw new Error("openPath dependency missing");
          },
  };
}

async function launchOne(validatedResource, deps) {
  if (validatedResource.type === "url") {
    await deps.openExternal(validatedResource.value);
    return;
  }

  if (validatedResource.type === "file") {
    const result = await deps.openPath(validatedResource.value);
    if (typeof result === "string" && result.length > 0) {
      throw new Error(result);
    }
    return;
  }

  if (validatedResource.mode === "path") {
    const result = await deps.openPath(validatedResource.value);
    if (typeof result === "string" && result.length > 0) {
      throw new Error(result);
    }
    return;
  }

  await deps.openExternal(validatedResource.value);
}

async function launchAll(resources, deps = {}) {
  const safeDeps = getDeps(deps);
  const input = Array.isArray(resources) ? resources.slice(0, MAX_LAUNCH_ITEMS) : [];

  const results = [];
  let launchedCount = 0;

  for (const resource of input) {
    const validated = validateResource(resource);

    if (!validated.ok) {
      const id = validated.id || "unknown";
      results.push({ id, status: "rejected", reason: validated.reason });
      continue;
    }

    try {
      await launchOne(validated, safeDeps);
      results.push({ id: validated.id, status: "launched" });
      launchedCount += 1;
    } catch (error) {
      const reason = error instanceof Error ? error.message : "launch-failed";
      results.push({ id: validated.id, status: "failed", reason });
    }
  }

  return {
    ok: true,
    launchedCount,
    results,
  };
}

module.exports = {
  MAX_LAUNCH_ITEMS,
  sanitizeUrl,
  sanitizeFilePath,
  sanitizeAppTarget,
  validateResource,
  launchAll,
};
