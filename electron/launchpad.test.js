const test = require("node:test");
const assert = require("node:assert/strict");

const {
  sanitizeUrl,
  sanitizeFilePath,
  sanitizeAppTarget,
  launchAll,
} = require("./launchpad");

test("sanitizeUrl accepts https URLs", () => {
  const result = sanitizeUrl("https://example.com/docs");
  assert.equal(result.ok, true);
  assert.equal(result.value, "https://example.com/docs");
});

test("sanitizeUrl rejects javascript protocol", () => {
  const result = sanitizeUrl("javascript:alert(1)");
  assert.equal(result.ok, false);
});

test("sanitizeFilePath accepts absolute paths", () => {
  const result = sanitizeFilePath("/Users/alex/Documents/spec.pdf");
  assert.equal(result.ok, true);
  assert.equal(result.value, "/Users/alex/Documents/spec.pdf");
});

test("sanitizeFilePath rejects relative traversal", () => {
  const result = sanitizeFilePath("../../etc/passwd");
  assert.equal(result.ok, false);
});

test("sanitizeAppTarget accepts app bundle and deep links", () => {
  const appPath = sanitizeAppTarget("/Applications/Slack.app");
  assert.equal(appPath.ok, true);

  const deepLink = sanitizeAppTarget("obsidian://open?vault=Work");
  assert.equal(deepLink.ok, true);
});

test("launchAll skips invalid resources and reports outcomes", async () => {
  const opened = [];

  const deps = {
    openExternal: async (target) => {
      opened.push(["external", target]);
    },
    openPath: async (target) => {
      opened.push(["path", target]);
      return "";
    },
  };

  const resources = [
    {
      id: "1",
      type: "url",
      value: "https://example.com",
      label: "Docs",
      createdAt: new Date().toISOString(),
    },
    {
      id: "2",
      type: "url",
      value: "javascript:alert(1)",
      label: "Bad",
      createdAt: new Date().toISOString(),
    },
    {
      id: "3",
      type: "file",
      value: "/Users/alex/Notes/todo.md",
      label: "Notes",
      createdAt: new Date().toISOString(),
    },
  ];

  const result = await launchAll(resources, deps);
  assert.equal(result.ok, true);
  assert.equal(result.launchedCount, 2);
  assert.deepEqual(
    result.results.map((item) => ({ id: item.id, status: item.status })),
    [
      { id: "1", status: "launched" },
      { id: "2", status: "rejected" },
      { id: "3", status: "launched" },
    ]
  );
  assert.equal(opened.length, 2);
});
