export type LaunchResourceType = "url" | "file" | "app";

export type LaunchResource = {
  id: string;
  type: LaunchResourceType;
  label: string;
  value: string;
  createdAt: string;
};

const MAX_RESOURCES = 12;
const MAX_PAYLOAD_LENGTH = 16_000;
const ALLOWED_DEEP_LINK_PROTOCOLS = new Set([
  "obsidian:",
  "notion:",
  "raycast:",
]);

function createDeterministicId(type: LaunchResourceType, label: string, value: string): string {
  const source = `${type}|${label}|${value}`;
  let hash = 0;
  for (let i = 0; i < source.length; i += 1) {
    hash = (hash * 31 + source.charCodeAt(i)) >>> 0;
  }
  return `lr_${hash.toString(36)}`;
}

function isIsoDate(value: string): boolean {
  const timestamp = Date.parse(value);
  return Number.isFinite(timestamp);
}

function sanitizeLabel(input: unknown): string {
  if (typeof input !== "string") {
    return "";
  }

  return input.trim().slice(0, 80);
}

function sanitizeValue(input: unknown): string {
  if (typeof input !== "string") {
    return "";
  }

  return input.trim();
}

function isValidUrlValue(value: string): boolean {
  try {
    const url = new URL(value);
    return url.protocol === "http:" || url.protocol === "https:";
  } catch {
    return false;
  }
}

function hasTraversalPattern(value: string): boolean {
  return /(^|[\\/])\.\.([\\/]|$)/.test(value);
}

function isValidFileValue(value: string): boolean {
  if (!value.startsWith("/")) {
    return false;
  }

  if (hasTraversalPattern(value)) {
    return false;
  }

  return value.length > 1;
}

function isValidAppValue(value: string): boolean {
  if (value.startsWith("/")) {
    if (hasTraversalPattern(value)) {
      return false;
    }
    return value.endsWith(".app") || value.includes(".app/");
  }

  try {
    const url = new URL(value);
    return ALLOWED_DEEP_LINK_PROTOCOLS.has(url.protocol);
  } catch {
    return false;
  }
}

function sanitizeResource(input: Partial<LaunchResource>):
  | { ok: true; value: LaunchResource }
  | { ok: false; error: string } {
  const type = input.type;
  const label = sanitizeLabel(input.label);
  const value = sanitizeValue(input.value);

  if (type !== "url" && type !== "file" && type !== "app") {
    return { ok: false, error: "invalid_type" };
  }

  if (label.length === 0) {
    return { ok: false, error: "invalid_label" };
  }

  if (value.length === 0) {
    return { ok: false, error: "invalid_value" };
  }

  if (type === "url" && !isValidUrlValue(value)) {
    return { ok: false, error: "invalid_url" };
  }

  if (type === "file" && !isValidFileValue(value)) {
    return { ok: false, error: "invalid_file_path" };
  }

  if (type === "app" && !isValidAppValue(value)) {
    return { ok: false, error: "invalid_app_target" };
  }

  const id = typeof input.id === "string" && input.id.trim().length > 0
    ? input.id.trim()
    : createDeterministicId(type, label, value);

  const createdAt =
    typeof input.createdAt === "string" && isIsoDate(input.createdAt)
      ? new Date(input.createdAt).toISOString()
      : new Date(0).toISOString();

  return {
    ok: true,
    value: {
      id,
      type,
      label,
      value,
      createdAt,
    },
  };
}

export function validateLaunchResource(input: Partial<LaunchResource>):
  | { ok: true; value: LaunchResource }
  | { ok: false; error: string } {
  return sanitizeResource(input);
}

export function parseLaunchResources(raw: string | null | undefined): LaunchResource[] {
  if (typeof raw !== "string" || raw.trim().length === 0) {
    return [];
  }

  if (raw.length > MAX_PAYLOAD_LENGTH) {
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

  const sanitized: LaunchResource[] = [];
  for (const item of parsed) {
    if (sanitized.length >= MAX_RESOURCES) {
      break;
    }

    if (item === null || typeof item !== "object") {
      continue;
    }

    const result = sanitizeResource(item as Partial<LaunchResource>);
    if (result.ok) {
      sanitized.push(result.value);
    }
  }

  return sanitized;
}

export function serializeLaunchResources(items: LaunchResource[]): string {
  const sanitized: LaunchResource[] = [];

  for (const item of items) {
    if (sanitized.length >= MAX_RESOURCES) {
      break;
    }

    const result = sanitizeResource(item);
    if (result.ok) {
      sanitized.push(result.value);
    }
  }

  const serialized = JSON.stringify(sanitized);
  if (serialized.length > MAX_PAYLOAD_LENGTH) {
    return JSON.stringify([]);
  }

  return serialized;
}
