import assert from "node:assert/strict";
import test from "node:test";

import { launchAllClient } from "./launchAllClient.ts";

test("returns desktop_only when not running in desktop app", async () => {
  const result = await launchAllClient("[]", {
    isDesktopApp: () => false,
    launchAllFromDesktop: null,
  });

  assert.equal(result.ok, false);
  if (!result.ok) {
    assert.equal(result.reason, "desktop_only");
  }
});

test("returns empty when resources payload has no valid entries", async () => {
  const result = await launchAllClient("not-json", {
    isDesktopApp: () => true,
    launchAllFromDesktop: async () => ({ ok: true, launchedCount: 0 }),
  });

  assert.equal(result.ok, false);
  if (!result.ok) {
    assert.equal(result.reason, "empty");
  }
});

test("returns unavailable when desktop launcher is missing", async () => {
  const result = await launchAllClient(
    JSON.stringify([
      {
        id: "a",
        type: "url",
        label: "Docs",
        value: "https://example.com",
        createdAt: new Date(0).toISOString(),
      },
    ]),
    {
      isDesktopApp: () => true,
      launchAllFromDesktop: null,
    }
  );

  assert.equal(result.ok, false);
  if (!result.ok) {
    assert.equal(result.reason, "unavailable");
  }
});

test("launches valid resources with desktop launcher", async () => {
  let receivedCount = 0;

  const result = await launchAllClient(
    JSON.stringify([
      {
        id: "a",
        type: "url",
        label: "Docs",
        value: "https://example.com",
        createdAt: new Date(0).toISOString(),
      },
      {
        id: "b",
        type: "app",
        label: "Obsidian",
        value: "obsidian://open?vault=main",
        createdAt: new Date(0).toISOString(),
      },
    ]),
    {
      isDesktopApp: () => true,
      launchAllFromDesktop: async (resources) => {
        receivedCount = resources.length;
        return { ok: true, launchedCount: resources.length };
      },
    }
  );

  assert.equal(receivedCount, 2);
  assert.equal(result.ok, true);
  if (result.ok) {
    assert.equal(result.launchedCount, 2);
  }
});
