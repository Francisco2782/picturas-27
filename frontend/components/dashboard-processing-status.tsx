"use client";

import Link from "next/link";
import { isAxiosError } from "axios";
import { usePathname } from "next/navigation";
import { createContext, useCallback, useContext, useEffect, useMemo, useState } from "react";
import { AlertCircle, CheckCircle2, LoaderCircle, X } from "lucide-react";
import { useQueryClient } from "@tanstack/react-query";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Progress } from "@/components/ui/progress";
import { useGetProjectProcessingStatus, useGetSocket, useResolveShareLink } from "@/lib/queries/projects";
import { useCancelProjectProcess } from "@/lib/mutations/projects";
import { useUpdateSession } from "@/lib/mutations/session";
import { applyVideoProgressEvent, shouldRefreshProcessingStatus } from "@/lib/processing-status";
import type { ProcessingRunStatus } from "@/lib/projects";
import { useSession } from "@/providers/session-provider";

type TrackedProject = {
  userId: string;
  projectId: string;
  ownerId: string;
  shareId?: string;
  projectVersion?: number;
};

type ProcessingStatusContextValue = {
  trackProject: (project: TrackedProject) => void;
};

const STORAGE_KEY = "picturas-active-processing-project";
const ProcessingStatusContext = createContext<ProcessingStatusContextValue | null>(null);

export function useTrackProcessingProject() {
  const context = useContext(ProcessingStatusContext);
  if (!context) throw new Error("Processing status provider is missing");
  return context.trackProject;
}

function processingStatusKey(track: TrackedProject, token: string) {
  return ["projectProcessingStatus", track.userId, track.projectId, token, track.ownerId, track.shareId];
}

export function DashboardProcessingStatus({ children }: { children: React.ReactNode }) {
  const session = useSession();
  const socket = useGetSocket(session.token);
  const qc = useQueryClient();
  const pathname = usePathname();
  const [tracked, setTracked] = useState<TrackedProject | null>(null);
  const [cancelError, setCancelError] = useState(false);
  const isTrackedProjectOpen = tracked && pathname === `/dashboard/${tracked.projectId}`;
  const share = useResolveShareLink(isTrackedProjectOpen ? undefined : tracked?.shareId, true);
  const status = useGetProjectProcessingStatus(
    tracked?.userId ?? "",
    tracked?.projectId ?? "",
    session.token,
    tracked?.ownerId,
    tracked?.shareId,
  );
  const cancelProcess = useCancelProjectProcess(
    tracked?.userId ?? "",
    tracked?.projectId ?? "",
    session.token,
    tracked?.ownerId,
    tracked?.shareId,
  );
  const updateSession = useUpdateSession();
  const canEdit = tracked && tracked.userId === session.user._id && (tracked.shareId
    ? !share.isError && share.data?.permission === "edit" &&
      share.data.ownerId === tracked.ownerId && share.data.projectId === tracked.projectId
    : tracked.ownerId === session.user._id);

  useEffect(() => {
    if (!session.user?._id) return;
    try {
      const saved = sessionStorage.getItem(STORAGE_KEY);
      if (!saved) return;
      const parsed = JSON.parse(saved) as TrackedProject;
      if (parsed.userId === session.user._id && parsed.projectId && parsed.ownerId) {
        setTracked(parsed);
      } else {
        sessionStorage.removeItem(STORAGE_KEY);
      }
    } catch {
      sessionStorage.removeItem(STORAGE_KEY);
    }
  }, [session.user?._id]);

  const trackProject = useCallback((project: TrackedProject) => {
    setTracked((current) => {
      if (current?.projectId !== project.projectId || current.ownerId !== project.ownerId ||
          current.userId !== project.userId || current.shareId !== project.shareId) return project;
      const version = Math.max(current.projectVersion ?? 0, project.projectVersion ?? 0) || undefined;
      return version === current.projectVersion ? current : { ...project, projectVersion: version };
    });
  }, []);

  useEffect(() => {
    if (tracked) sessionStorage.setItem(STORAGE_KEY, JSON.stringify(tracked));
  }, [tracked]);

  const dismiss = useCallback(() => {
    setTracked(null);
    sessionStorage.removeItem(STORAGE_KEY);
  }, []);

  const cancelTrackedRun = () => {
    if (!tracked || !canEdit || status.data?.state !== "running" ||
        tracked.projectVersion === undefined || !Number.isFinite(tracked.projectVersion)) return;
    setCancelError(false);
    cancelProcess.mutate({ projectVersion: tracked.projectVersion }, {
      onSuccess: () => updateSession.mutate({ userId: session.user._id, token: session.token }),
      onError: (error) => {
        setCancelError(true);
        if (!isAxiosError(error) || error.response?.status !== 409) return;
        const version = error.response.data?.serverVersion;
        if (typeof version !== "number" || !Number.isFinite(version)) return;
        setTracked((current) => current === tracked ? { ...current, projectVersion: version } : current);
      },
    });
  };

  const queryKey = useMemo(
    () => tracked ? processingStatusKey(tracked, session.token) : [],
    [tracked, session.token],
  );

  useEffect(() => {
    const client = socket.data;
    if (!client || !tracked) return;

    const onVideoProgress = (event: {
      projectId: string;
      imgId: string;
      runToken: number;
      percent: number;
      preview: boolean;
      timestamp: string;
    }) => {
      if (event.projectId !== tracked.projectId || event.preview) return;
      qc.setQueryData<ProcessingRunStatus | null>(queryKey, (current) =>
        applyVideoProgressEvent(current, tracked.projectId, event) ?? null,
      );
    };

    const refreshStatus = (event: { projectId?: string; runToken?: number; timestamp?: string }) => {
      const current = qc.getQueryData<ProcessingRunStatus | null>(queryKey);
      if (!shouldRefreshProcessingStatus(current, event, tracked.projectId)) return;
      qc.invalidateQueries({ queryKey });
    };

    client.on("video-progress", onVideoProgress);
    client.on("process-update", refreshStatus);
    client.on("process-error", refreshStatus);
    return () => {
      client.off("video-progress", onVideoProgress);
      client.off("process-update", refreshStatus);
      client.off("process-error", refreshStatus);
    };
  }, [socket.data, tracked, qc, queryKey]);

  const visibleStatus = status.isError ? null : status.data;
  const progressValues = visibleStatus?.videos.map((video) => video.progress) ?? [];
  const progress = progressValues.length
    ? Math.round(progressValues.reduce((sum, value) => sum + value, 0) / progressValues.length)
    : null;
  const hrefParams = new URLSearchParams();
  if (tracked?.ownerId && tracked.ownerId !== tracked.userId) hrefParams.set("owner", tracked.ownerId);
  if (tracked?.shareId) hrefParams.set("share", tracked.shareId);
  const hrefQuery = hrefParams.toString();
  const projectHref = tracked
    ? `/dashboard/${tracked.projectId}${hrefQuery ? `?${hrefQuery}` : ""}`
    : "#";

  const contextValue = useMemo(() => ({ trackProject }), [trackProject]);
  const running = visibleStatus?.state === "running";
  const failed = status.data?.state === "failed" || status.isError;
  const terminal = (!!visibleStatus && visibleStatus.state !== "running") || status.isError;
  const statusLabel = status.isError
    ? "Status unavailable"
    : visibleStatus?.state === "completed"
    ? "Processing complete"
    : visibleStatus?.state === "failed"
      ? "Processing failed"
      : visibleStatus?.state === "cancelled"
        ? "Processing cancelled"
        : status.isError
          ? "Status unavailable"
          : "Processing";

  return (
    <ProcessingStatusContext.Provider value={contextValue}>
      {tracked && (
        <Card className="fixed bottom-4 right-4 z-[60] w-[min(24rem,calc(100vw-2rem))] p-3 shadow-lg">
          <div className="flex items-start gap-3">
            {running ? <LoaderCircle className="mt-0.5 size-4 shrink-0 animate-spin" />
              : failed ? <AlertCircle className="mt-0.5 size-4 shrink-0 text-destructive" />
                : <CheckCircle2 className="mt-0.5 size-4 shrink-0" />}
            <div className="min-w-0 flex-1 space-y-1">
              <div className="font-medium">{statusLabel}</div>
              {running && progress !== null && (
                <>
                  <Progress value={progress} />
                  <div className="text-xs text-muted-foreground">{progress}%</div>
                </>
              )}
              {running && progress === null && (
                <div className="text-xs text-muted-foreground">The job is still running.</div>
              )}
              {status.isLoading && <div className="text-xs text-muted-foreground">Recovering the latest status…</div>}
              {status.isError && <div className="text-xs text-muted-foreground">Open the project to check access and retry.</div>}
              {cancelError && <div className="text-xs text-destructive">Could not cancel processing. Reopen the project and try again.</div>}
              <Link href={projectHref} className="text-xs underline underline-offset-2">Open project</Link>
              {status.data?.state === "running" && canEdit && !isTrackedProjectOpen && Number.isFinite(tracked.projectVersion) && (
                <Button
                  variant="outline"
                  size="sm"
                  disabled={cancelProcess.isPending}
                  onClick={cancelTrackedRun}
                  className="ml-2 h-7"
                  title="Cancel processing"
                  aria-label="Cancel processing"
                >
                  {cancelProcess.isPending ? <LoaderCircle className="size-3 animate-spin" /> : "Cancel"}
                </Button>
              )}
            </div>
            {terminal && (
              <Button variant="ghost" size="icon" className="size-7" onClick={dismiss} title="Dismiss processing status" aria-label="Dismiss processing status">
                <X className="size-4" />
              </Button>
            )}
          </div>
        </Card>
      )}
      {children}
    </ProcessingStatusContext.Provider>
  );
}
