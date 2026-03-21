import assert from "node:assert/strict";
import test from "node:test";

import {
  parseLaunchResources,
  serializeLaunchResources,
  trySerializeLaunchResources,
  validateLaunchResource,
} from "./launchResources.ts";

test("accepts a valid https URL resource", () => {
  const result = validateLaunchResource({
    type: "url",
    label: "Docs",
    value: "https://example.com/docs",
  });

  assert.equal(result.ok, true);
  if (result.ok) {
    assert.equal(result.value.type, "url");
    assert.equal(result.value.label, "Docs");
    assert.equal(result.value.value, "https://example.com/docs");
    assert.equal(typeof result.value.id, "string");
    assert.equal(typeof result.value.createdAt, "string");
  }
});

test("rejects invalid URL protocol", () => {
  const result = validateLaunchResource({
    type: "url",
    label: "Bad",
    value: "javascript:alert(1)",
  });

  assert.equal(result.ok, false);
});

test("requires absolute file path for file resources", () => {
  const result = validateLaunchResource({
    type: "file",
    label: "Relative file",
    value: "./notes/today.md",
  });

  assert.equal(result.ok, false);
});

test("trims parsed payload to max resource count", () => {
  const rawItems = Array.from({ length: 14 }, (_, index) => ({
    id: `id-${index + 1}`,
    type: "url",
    label: `Link ${index + 1}`,
    value: "https://example.com",
    createdAt: new Date().toISOString(),
  }));

  const parsed = parseLaunchResources(JSON.stringify(rawItems));

  assert.equal(parsed.length, 12);
});

test("returns an empty list for malformed JSON", () => {
  const parsed = parseLaunchResources("not-json");

  assert.deepEqual(parsed, []);
});

test("serializes and re-parses valid resources", () => {
  const maybeResource = validateLaunchResource({
    type: "app",
    label: "Obsidian",
    value: "obsidian://open?vault=personal",
  });

  assert.equal(maybeResource.ok, true);
  if (!maybeResource.ok) {
    return;
  }

  const serialized = serializeLaunchResources([maybeResource.value]);
  const parsed = parseLaunchResources(serialized);

  assert.equal(parsed.length, 1);
  assert.equal(parsed[0]?.type, "app");
});

test("returns explicit error when serialized payload exceeds limit", () => {
  const veryLongValue = `https://example.com/${"a".repeat(5000)}`;
  const items = Array.from({ length: 12 }, (_, index) => {
    const result = validateLaunchResource({
      type: "url",
      label: `Very Long Link ${index + 1}`,
      value: veryLongValue,
    });

    if (!result.ok) {
      throw new Error("Failed to construct valid launch resource for overflow test");
    }

    return result.value;
  });

  const serializationResult = trySerializeLaunchResources(items);
  assert.equal(serializationResult.ok, false);
  if (!serializationResult.ok) {
    assert.equal(serializationResult.error, "payload_too_large");
  }
});
