function buildProcessingStatus(project) {
  const run = project?.processingRun;
  if (!run) return null;

  return {
    runToken: run.runToken,
    state: run.state,
    outcome: run.outcome ?? null,
    startedAt: run.startedAt,
    updatedAt: run.updatedAt,
    finishedAt: run.finishedAt ?? null,
    videos: (run.videos || []).map((video) => ({
      mediaId: String(video.mediaId),
      progress: video.progress,
      preview: video.preview,
      updatedAt: video.updatedAt,
    })),
  };
}

function canReadProcessingStatus(callerId, ownerId, sharedPermission) {
  if (!callerId) return false;
  if (sharedPermission === "read" || sharedPermission === "edit") return true;
  return String(callerId) === String(ownerId);
}

module.exports = { buildProcessingStatus, canReadProcessingStatus };
