const { applyVideoProgress } = require("./processingRun");

function parseVideoProgress(message) {
  if (!message || message.messageType !== "video-progress") return null;

  const timestamp = new Date(message.timestamp);
  if (!Number.isFinite(timestamp.getTime())) return null;
  if (typeof message.sourceProcessId !== "string" || !message.sourceProcessId) return null;
  if (typeof message.projectId !== "string" || !message.projectId) return null;
  if (typeof message.mediaId !== "string" || !message.mediaId) return null;
  if (!Number.isSafeInteger(message.runToken) || message.runToken < 1) return null;
  if (!Number.isSafeInteger(message.percent) || message.percent < 0 || message.percent > 100) return null;
  if (typeof message.preview !== "boolean") return null;

  return { ...message, timestamp };
}

async function handleVideoProgress(message, {
  getProcess,
  getProject,
  updateProgress,
  publishProgress,
}) {
  const observation = parseVideoProgress(message);
  if (!observation) return { accepted: false, reason: "invalid" };

  const process = await getProcess(observation.sourceProcessId);
  if (!process
    || process.msg_id !== observation.sourceProcessId
    || String(process.project_id) !== observation.projectId
    || String(process.img_id) !== observation.mediaId
    || (process.token || 0) !== observation.runToken) {
    return { accepted: false, reason: "process-mismatch" };
  }

  const project = await getProject(process.user_id, process.project_id);
  if (!project
    || (project.activeToken || 0) !== observation.runToken
    || !project.processingRun
    || project.processingRun.runToken !== observation.runToken
    || project.processingRun.state !== "running") {
    return { accepted: false, reason: "stale-run" };
  }

  const transition = applyVideoProgress(project.processingRun, {
    runToken: observation.runToken,
    mediaId: observation.mediaId,
    progress: observation.percent,
    preview: observation.preview,
    timestamp: observation.timestamp,
  });
  if (!transition.accepted) return { accepted: false, reason: "duplicate-or-stale" };

  const updated = await updateProgress({
    userId: process.user_id,
    projectId: process.project_id,
    runToken: observation.runToken,
    mediaId: observation.mediaId,
    percent: observation.percent,
    preview: observation.preview,
    timestamp: observation.timestamp,
  });
  if (!updated) return { accepted: false, reason: "update-conflict" };

  publishProgress({
    user: process.runner_id || process.user_id,
    projectId: observation.projectId,
    imgId: observation.mediaId,
    preview: observation.preview,
    percent: observation.percent,
    timestamp: observation.timestamp.toISOString(),
  });
  return { accepted: true };
}

module.exports = { parseVideoProgress, handleVideoProgress };
