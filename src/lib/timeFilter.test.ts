import assert from "node:assert/strict";
import test from "node:test";

// @ts-expect-error Node's test runner resolves the local TypeScript module directly.
import { matchesTimeFilter } from "./timeFilter.ts";

test("overdue excludes tasks due earlier today", () => {
  const now = new Date(2026, 2, 21, 23, 59, 0);
  const dueEarlierToday = new Date(2026, 2, 21, 0, 1, 0);

  assert.equal(matchesTimeFilter("overdue", dueEarlierToday, now), false);
  assert.equal(matchesTimeFilter("today", dueEarlierToday, now), true);
});

test("today matches only local today", () => {
  const now = new Date(2026, 2, 21, 10, 0, 0);
  const dueToday = new Date(2026, 2, 21, 23, 30, 0);
  const dueTomorrow = new Date(2026, 2, 22, 0, 0, 0);

  assert.equal(matchesTimeFilter("today", dueToday, now), true);
  assert.equal(matchesTimeFilter("today", dueTomorrow, now), false);
});

test("tomorrow matches next local day only", () => {
  const now = new Date(2026, 2, 21, 10, 0, 0);
  const dueTomorrow = new Date(2026, 2, 22, 9, 0, 0);
  const dueInTwoDays = new Date(2026, 2, 23, 9, 0, 0);

  assert.equal(matchesTimeFilter("tomorrow", dueTomorrow, now), true);
  assert.equal(matchesTimeFilter("tomorrow", dueInTwoDays, now), false);
});

test("next-7-days includes today and next six days", () => {
  const now = new Date(2026, 2, 21, 10, 0, 0);
  const dueToday = new Date(2026, 2, 21, 8, 0, 0);
  const dueDaySix = new Date(2026, 2, 27, 12, 0, 0);
  const dueDaySeven = new Date(2026, 2, 28, 12, 0, 0);
  const dueYesterday = new Date(2026, 2, 20, 12, 0, 0);

  assert.equal(matchesTimeFilter("next-7-days", dueToday, now), true);
  assert.equal(matchesTimeFilter("next-7-days", dueDaySix, now), true);
  assert.equal(matchesTimeFilter("next-7-days", dueDaySeven, now), false);
  assert.equal(matchesTimeFilter("next-7-days", dueYesterday, now), false);
});

test("no-date matches only null due date", () => {
  const now = new Date(2026, 2, 21, 10, 0, 0);
  const dueToday = new Date(2026, 2, 21, 18, 0, 0);

  assert.equal(matchesTimeFilter("no-date", null, now), true);
  assert.equal(matchesTimeFilter("no-date", dueToday, now), false);
});

test("all-dates always matches", () => {
  const now = new Date(2026, 2, 21, 10, 0, 0);
  const dueToday = new Date(2026, 2, 21, 18, 0, 0);

  assert.equal(matchesTimeFilter("all-dates", null, now), true);
  assert.equal(matchesTimeFilter("all-dates", dueToday, now), true);
});
