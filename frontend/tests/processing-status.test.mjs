import test from "node:test";
import assert from "node:assert/strict";
import {
  applyVideoProgressEvent,
  reconcileProcessingStatus,
  shouldRefreshProcessingStatus,
} from "../lib/processing-status.ts";

const timestamp = (seconds) => `2026-11-20T10:00:${String(seconds).padStart(2, "0")}.000Z`;

function status(overrides = {}) {
  return {
    runToken: 4,
    state: "running",
    outcome: null,
    startedAt: timestamp(0),
    updatedAt: timestamp(1),
    finishedAt: null,
    videos: [{ mediaId: "video-a", progress: 10, preview: false, updatedAt: timestamp(1) }],
    ...overrides,
  };
}

test("a newer run replaces an older run snapshot", () => {
  assert.equal(reconcileProcessingStatus(status(), status({ runToken: 5 })).runToken, 5);
  assert.equal(reconcileProcessingStatus(status({ runToken: 5 }), status()).runToken, 5);
});

test("a terminal state cannot be replaced by a stale active response", () => {
  const completed = status({ state: "completed", outcome: "completed", updatedAt: timestamp(8) });
  assert.equal(reconcileProcessingStatus(completed, status({ updatedAt: timestamp(3) })).state, "completed");
});

test("newer status responses keep the newest timestamp for each video", () => {
  const current = status({ updatedAt: timestamp(6), videos: [
    { mediaId: "video-a", progress: 70, preview: false, updatedAt: timestamp(6) },
    { mediaId: "video-b", progress: 20, preview: false, updatedAt: timestamp(2) },
  ] });
  const incoming = status({ updatedAt: timestamp(7), videos: [
    { mediaId: "video-a", progress: 40, preview: false, updatedAt: timestamp(4) },
    { mediaId: "video-b", progress: 30, preview: false, updatedAt: timestamp(7) },
  ] });
  const result = reconcileProcessingStatus(current, incoming);
  assert.equal(result.videos.find((video) => video.mediaId === "video-a").progress, 70);
  assert.equal(result.videos.find((video) => video.mediaId === "video-b").progress, 30);
});

test("a missing response cannot clear a snapshot already observed from a socket", () => {
  assert.equal(reconcileProcessingStatus(status(), null).state, "running");
});

test("an incoming terminal state replaces the matching active run", () => {
  const completed = status({ state: "completed", outcome: "completed", updatedAt: timestamp(8) });
  assert.equal(reconcileProcessingStatus(status(), completed).state, "completed");
});

test("socket progress is accepted only for the matching run and newer timestamp", () => {
  const current = status();
  const event = {
    projectId: "project-a", imgId: "video-a", runToken: 4,
    percent: 55, preview: false, timestamp: timestamp(5),
  };
  assert.equal(applyVideoProgressEvent(current, "project-a", event).videos[0].progress, 55);
  assert.equal(applyVideoProgressEvent(current, "project-a", { ...event, runToken: 3 }), current);
  assert.equal(applyVideoProgressEvent(current, "project-a", { ...event, timestamp: timestamp(0) }), current);
  assert.equal(applyVideoProgressEvent(current, "project-b", event), current);
});

test("terminal and stale socket notifications do not trigger status reloads", () => {
  const current = status({ updatedAt: timestamp(5) });
  assert.equal(shouldRefreshProcessingStatus(current, {
    projectId: "project-a", runToken: 4, timestamp: timestamp(4),
  }, "project-a"), false);
  assert.equal(shouldRefreshProcessingStatus(current, {
    projectId: "project-a", runToken: 5, timestamp: timestamp(6),
  }, "project-a"), true);
  assert.equal(shouldRefreshProcessingStatus(status({ state: "completed" }), {
    projectId: "project-a", runToken: 4, timestamp: timestamp(6),
  }, "project-a"), false);
});
