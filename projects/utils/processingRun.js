const TERMINAL_OUTCOMES = new Set(["completed", "failed", "cancelled"]);

function toDate(value) {
  const date = value instanceof Date ? value : new Date(value);
  return Number.isNaN(date.getTime()) ? null : date;
}

function startProcessingRun(runToken, videoIds = [], now = new Date()) {
  if (!Number.isSafeInteger(runToken) || runToken < 1) {
    throw new TypeError("runToken must be a positive safe integer");
  }
  const startedAt = toDate(now);
  if (!startedAt) throw new TypeError("now must be a valid date");

  return {
    runToken,
    state: "running",
    outcome: null,
    startedAt,
    updatedAt: startedAt,
    finishedAt: null,
    videos: [...new Set(videoIds.map(String))].map((mediaId) => ({
      mediaId,
      progress: 0,
      preview: false,
      updatedAt: startedAt,
    })),
  };
}

function applyVideoProgress(run, observation) {
  if (!run || run.state !== "running") return { accepted: false, run };
  if (run.runToken !== observation.runToken) return { accepted: false, run };
  if (!Number.isSafeInteger(observation.progress) || observation.progress < 0 || observation.progress > 100) {
    return { accepted: false, run };
  }

  const mediaId = String(observation.mediaId || "");
  const video = (run.videos || []).find((item) => item.mediaId === mediaId);
  if (!video || observation.progress <= video.progress) return { accepted: false, run };

  const observedAt = toDate(observation.timestamp || new Date());
  if (!observedAt) return { accepted: false, run };
  const lastObservedAt = toDate(video.updatedAt);
  if (lastObservedAt && observedAt < lastObservedAt) return { accepted: false, run };
  const runUpdatedAt = toDate(run.updatedAt);
  const next = {
    ...run,
    updatedAt: runUpdatedAt && runUpdatedAt > observedAt ? runUpdatedAt : observedAt,
    videos: run.videos.map((item) => item.mediaId === mediaId
      ? { ...item, progress: observation.progress, preview: Boolean(observation.preview), updatedAt: observedAt }
      : item),
  };
  return { accepted: true, run: next };
}

function finishProcessingRun(run, runToken, outcome, now = new Date()) {
  if (!run || run.state !== "running" || run.runToken !== runToken) return null;
  if (!TERMINAL_OUTCOMES.has(outcome)) throw new TypeError("Invalid processing run outcome");
  const finishedAt = toDate(now);
  if (!finishedAt) throw new TypeError("now must be a valid date");

  return {
    ...run,
    state: outcome,
    outcome,
    updatedAt: finishedAt,
    finishedAt,
    videos: outcome === "completed"
      ? (run.videos || []).map((item) => ({ ...item, progress: 100, preview: false, updatedAt: finishedAt }))
      : (run.videos || []),
  };
}

module.exports = {
  TERMINAL_OUTCOMES,
  startProcessingRun,
  applyVideoProgress,
  finishProcessingRun,
};
