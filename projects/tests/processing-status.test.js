const test = require("node:test");
const assert = require("node:assert/strict");
const { buildProcessingStatus, canReadProcessingStatus } = require("../utils/processingStatus");

test("status snapshot returns only the latest run fields needed by clients", () => {
  const status = buildProcessingStatus({
    processingRun: {
      runToken: 12,
      state: "running",
      outcome: null,
      startedAt: "2026-11-20T10:00:00.000Z",
      updatedAt: "2026-11-20T10:00:03.000Z",
      finishedAt: null,
      videos: [{ mediaId: "video-1", progress: 35, preview: false, updatedAt: "2026-11-20T10:00:03.000Z", internal: "omit" }],
      secret: "omit",
    },
    user_id: "owner",
    activeToken: 999,
  });

  assert.deepEqual(status, {
    runToken: 12,
    state: "running",
    outcome: null,
    startedAt: "2026-11-20T10:00:00.000Z",
    updatedAt: "2026-11-20T10:00:03.000Z",
    finishedAt: null,
    videos: [{ mediaId: "video-1", progress: 35, preview: false, updatedAt: "2026-11-20T10:00:03.000Z" }],
  });
});

test("status snapshot includes terminal outcomes and no-run projects", () => {
  for (const state of ["completed", "failed", "cancelled"]) {
    assert.equal(buildProcessingStatus({ processingRun: { state, outcome: state } }).state, state);
  }
  assert.equal(buildProcessingStatus({}), null);
});

test("only the owner or a permitted share can read status", () => {
  assert.equal(canReadProcessingStatus("owner", "owner"), true);
  assert.equal(canReadProcessingStatus("viewer", "owner", "read"), true);
  assert.equal(canReadProcessingStatus("editor", "owner", "edit"), true);
  assert.equal(canReadProcessingStatus("stranger", "owner"), false);
  assert.equal(canReadProcessingStatus(null, "owner", "read"), false);
});

test("a stale client token still receives only the authoritative latest snapshot", () => {
  const latest = buildProcessingStatus({ processingRun: { runToken: 9, state: "completed", videos: [] } });
  assert.equal(latest.runToken, 9);
  assert.equal(Object.hasOwn(latest, "previousRun"), false);
});
