import { useSearchParams } from "next/navigation";
import BrightnessTool from "./brightness-tool";
import ContrastTool from "./contrast-tool";
import CropTool from "./crop-tool";
import ResizeTool from "./resize-tool";
import RotateTool from "./rotate-tool";
import SaturationTool from "./saturation-tool";
import BorderTool from "./border-tool";
import BinarizationTool from "./binarization-tool";
import WatermarkTool from "./watermark-tool";
import CropAITool from "./ai-crop-tool";
import BgRemovalAITool from "./ai-bg-removal";
import ObjectAITool from "./object-ai-tool";
import PeopleAITool from "./people-ai-tool";
import TextAITool from "./text-ai-tool";
import UpgradeAITool from "./upgrade-ai-tool";
import { useClearProjectTools } from "@/lib/mutations/projects";
import { useSession } from "@/providers/session-provider";
import { useCanEditProject, useProjectInfo } from "@/providers/project-provider";
import { Button } from "../ui/button";
import { AppliedToolsList } from "./applied-tools-list";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "../ui/dialog";
import { Eraser } from "lucide-react";
import { useState } from "react";
import ExpandAITool from "./expand-ai-tool";
import TrimTool from "./trim-tool";
import SpeedTool from "./speed-tool";
import SubtitlesTool from "./subtitles-tool";
import ExtractFramesTool from "./extract-frames-tool";
import { isVideo } from "@/lib/projects";

export function Toolbar() {
  const searchParams = useSearchParams();
  const view = searchParams.get("view") ?? "grid";
  const mode = searchParams.get("mode") ?? "edit";

  const project = useProjectInfo();
  const session = useSession();
  const canEdit = useCanEditProject();
  const disabled = mode === "results" || project.imgs.length === 0;

  // Projects with videos only show the effects the video worker supports
  // (AI tools and watermark are image-only).
  const hasVideos = project.imgs.some((i) => isVideo(i));

  const [open, setOpen] = useState<boolean>(false);
  const ownerParam = searchParams.get("owner") ?? session.user._id;
  const shareId = searchParams.get("share") ?? undefined;

  const clearTools = useClearProjectTools(
    session.user._id,
    project._id,
    session.token,
    ownerParam,
    shareId,
  );

  if (mode === "results") return null;

  return (
    <div className="flex h-full w-24 shrink-0 flex-col justify-between gap-3 overflow-x-hidden overflow-y-auto border-r bg-background p-2">
      <div className="flex flex-col gap-2 items-center">
        <span className="text-center text-sm text-gray-500">Project tools</span>
        <BrightnessTool disabled={disabled} />
        <ContrastTool disabled={disabled} />
        <SaturationTool disabled={disabled} />
        <BinarizationTool disabled={disabled} />
        <RotateTool disabled={disabled} />
        <CropTool disabled={disabled} />
        <ResizeTool disabled={disabled} />
        <BorderTool disabled={disabled} />
        {hasVideos && view === "carousel" && (
          <>
            <TrimTool disabled={disabled} />
            <SpeedTool disabled={disabled} />
          </>
        )}
        {hasVideos && <SubtitlesTool disabled={disabled} />}
        {hasVideos && <ExtractFramesTool disabled={disabled} />}
        {!hasVideos && (
          <>
            <WatermarkTool disabled={disabled} />
            <BgRemovalAITool disabled={disabled} />
            <CropAITool disabled={disabled} />
            <ObjectAITool disabled={disabled} />
            <PeopleAITool disabled={disabled} />
            <TextAITool disabled={disabled} />
            <ExpandAITool disabled={disabled} />
            <UpgradeAITool disabled={disabled} />
          </>
        )}
        {canEdit && <AppliedToolsList />}
      </div>
      <Dialog open={open} onOpenChange={setOpen}>
        <DialogTrigger asChild>
          <Button
            variant="outline"
            className="text-red-400 size-8"
            disabled={!canEdit || project.tools.length === 0}
            title="Clear all project tools"
            aria-label="Clear all project tools"
          >
            <Eraser />
          </Button>
        </DialogTrigger>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Clear Tools?</DialogTitle>
            <DialogDescription>
              This will remove <b>all</b> edits from the current project.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button
              variant="destructive"
              onClick={() => {
                clearTools.mutate({
                  toolIds: project.tools.map((t) => t._id),
                  projectVersion: project.version,
                });
                setOpen(false);
              }}
            >
              Clear
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
