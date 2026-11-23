import { useQuery } from "@tanstack/react-query";
import { isAxiosError } from "axios";
import {
  fetchProjects,
  fetchProject,
  getProjectImages,
  ProjectImage,
  fetchProjectResults,
  fetchProjectProcessingStatus,
} from "../projects";
import io from "socket.io-client";
import { listProjectShareLinks, fetchSharedProject } from "../projects";
import type { ShareLink } from "../projects";
import { resolveShareLink } from "../projects";
import type { ProcessingRunStatus } from "../projects";
import { reconcileProcessingStatus } from "../processing-status";
import { useQueryClient } from "@tanstack/react-query";

export const useGetProjectProcessingStatus = (
  uid: string,
  pid: string,
  token: string,
  ownerId?: string,
  shareId?: string,
) => {
  const qc = useQueryClient();
  const queryKey = ["projectProcessingStatus", uid, pid, token, ownerId, shareId];
  return useQuery<ProcessingRunStatus | null>({
    queryKey,
    queryFn: async () => {
      const incoming = await fetchProjectProcessingStatus(uid, pid, token, ownerId, shareId);
      return reconcileProcessingStatus(
        qc.getQueryData<ProcessingRunStatus | null>(queryKey),
        incoming,
      );
    },
    enabled: !!uid && !!pid && !!token,
    retry: (count, error) => {
      const status = isAxiosError(error) ? error.response?.status : undefined;
      return ![401, 403, 404, 410].includes(status ?? 0) && count < 3;
    },
    refetchInterval: (query) => query.state.data?.state === "running" ? 1000 : false,
    refetchOnReconnect: true,
    refetchOnWindowFocus: true,
  });
};

export const useProjectShareLinks = (
  userId: string,
  projectId: string,
  token: string,
) => {
  return useQuery<ShareLink[]>({
    queryKey: ["projectShareLinks", userId, projectId, token],
    queryFn: () => listProjectShareLinks(userId, projectId, token),
    enabled: !!userId && !!projectId && !!token,
  });
};

export const useGetProjects = (uid: string, token: string) => {
  return useQuery({
    queryKey: ["projects", uid, token],
    queryFn: () => fetchProjects(uid, token),
    enabled: !!uid && !!token, // só faz request se tiver uid+token
  });
};


export const useGetProject = (
  uid: string,
  pid: string,
  token: string,
  ownerId?: string,
  shareId?: string,
) => {
  return useQuery({
    queryKey: ["project", uid, pid, token, ownerId, shareId],
    queryFn: () => fetchProject(uid, pid, token, ownerId, shareId),
  });
};

export const useGetProjectImages = (
  uid: string,
  pid: string,
  token: string,
  initialData?: ProjectImage[],
) => {
  return useQuery({
    queryKey: ["projectImages", uid, pid, token],
    queryFn: () => getProjectImages(uid, pid, token),
    initialData: initialData,
  });
};

export const useGetSocket = (token: string) => {
  return useQuery({
    queryKey: ["socket", token],
    queryFn: () =>
      io("https://localhost:8080", {
        transports: ["websocket"],
        secure: true,
        rejectUnauthorized: false,
        auth: { token },
      }),
    refetchOnWindowFocus: false,
    refetchOnMount: false,
  });
};

export const useGetProjectResults = (
  uid: string,
  pid: string,
  token: string,
  ownerId?: string,
  shareId?: string,
) => {
  return useQuery({
    queryKey: ["projectResults", uid, pid, token, ownerId, shareId],
    queryFn: () => fetchProjectResults(uid, pid, token, ownerId, shareId),
  });
};

export const useGetSharedProject = (shareId: string, token: string) => {
  return useQuery({
    queryKey: ["sharedProject", shareId, token],
    queryFn: () => fetchSharedProject(shareId, token),
    enabled: !!shareId && !!token,
  });
};

export const useResolveShareLink = (shareId?: string | null, watch = false) => {
  return useQuery({
    queryKey: ["resolveShareLink", shareId],
    queryFn: () => resolveShareLink(shareId as string),
    enabled: !!shareId,
    staleTime: 30_000,
    refetchInterval: watch ? 10_000 : false,
    retry: false,
  });
};
