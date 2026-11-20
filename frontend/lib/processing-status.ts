import type { ProcessingRunStatus } from "./projects";

const terminalStates = new Set(["completed", "failed", "cancelled"]);

export function reconcileProcessingStatus(
  current: ProcessingRunStatus | null | undefined,
  incoming: ProcessingRunStatus | null,
): ProcessingRunStatus | null {
  if (!current) return incoming;
  if (!incoming) return current;
  if (incoming.runToken > current.runToken) return incoming;
  if (incoming.runToken < current.runToken) return current;

  const currentTerminal = terminalStates.has(current.state);
  const incomingTerminal = terminalStates.has(incoming.state);
  if (currentTerminal && !incomingTerminal) return current;
  if (incomingTerminal && !currentTerminal) return incoming;

  const incomingIsNewer = Date.parse(incoming.updatedAt) >= Date.parse(current.updatedAt);
  const base = incomingIsNewer ? incoming : current;
  const other = incomingIsNewer ? current : incoming;
  const videosById = new Map<string, ProcessingRunStatus["videos"][number]>();
  base.videos.forEach((video) => videosById.set(video.mediaId, video));

  for (const video of other.videos) {
    const existing = videosById.get(video.mediaId);
    if (!existing || Date.parse(video.updatedAt) > Date.parse(existing.updatedAt)) {
      videosById.set(video.mediaId, video);
    }
  }

  return { ...base, videos: [...videosById.values()] };
}

export type VideoProgressEvent = {
  projectId: string;
  imgId: string;
  runToken: number;
  percent: number;
  preview: boolean;
  timestamp: string;
};

export function applyVideoProgressEvent(
  current: ProcessingRunStatus | null | undefined,
  projectId: string,
  event: VideoProgressEvent,
): ProcessingRunStatus | null | undefined {
  if (!current || event.projectId !== projectId || event.preview) return current;
  if (current.state !== "running" || current.runToken !== event.runToken) return current;
  if (!Number.isInteger(event.percent) || event.percent < 0 || event.percent > 100) return current;
  const eventTime = Date.parse(event.timestamp);
  if (!Number.isFinite(eventTime)) return current;

  const video = current.videos.find((item) => item.mediaId === event.imgId);
  if (!video || event.percent <= video.progress || Date.parse(video.updatedAt) >= eventTime) return current;

  const next: ProcessingRunStatus = {
    ...current,
    updatedAt: Math.max(Date.parse(current.updatedAt), eventTime) === eventTime
      ? event.timestamp
      : current.updatedAt,
    videos: current.videos.map((item) => item.mediaId === event.imgId
      ? { ...item, progress: event.percent, preview: false, updatedAt: event.timestamp }
      : item),
  };
  return reconcileProcessingStatus(current, next);
}

export function shouldRefreshProcessingStatus(
  current: ProcessingRunStatus | null | undefined,
  event: { projectId?: string; runToken?: number; timestamp?: string },
  projectId: string,
): boolean {
  if (event.projectId !== projectId || !Number.isSafeInteger(event.runToken)) return false;
  if (!current || event.runToken! > current.runToken) return true;
  if (event.runToken! < current.runToken || terminalStates.has(current.state)) return false;
  const eventTime = Date.parse(event.timestamp ?? "");
  return Number.isFinite(eventTime) && eventTime > Date.parse(current.updatedAt);
}
