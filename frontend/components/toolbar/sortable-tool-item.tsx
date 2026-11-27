"use client";

import { useSortable } from "@dnd-kit/sortable";
import { CSS } from "@dnd-kit/utilities";
import { X, GripVertical } from "lucide-react";
import type { ProjectToolResponse } from "@/lib/projects";

export function SortableToolItem({ tool, onRemove }: {
  tool: ProjectToolResponse;
  onRemove?: (id: string) => void;
}) {
  const { attributes, listeners, setNodeRef, transform, transition } = useSortable({
    id: tool._id,
    disabled: !onRemove,
  });

  return (
    <div
      ref={setNodeRef}
      style={{
        transform: CSS.Transform.toString(transform),
        transition,
      }}
      className="flex w-full items-center justify-between rounded bg-muted/50 px-2 py-1"
    >
      <div className="flex items-center gap-2 min-w-0">
        {onRemove && (
          <GripVertical className="w-3 h-3 cursor-grab" {...attributes} {...listeners}
            aria-label={`Reorder ${tool.procedure}`} />
        )}
        <span className="max-w-[4.5rem] truncate text-[11px]">{tool.procedure}</span>
      </div>

      {onRemove && (
        <button type="button" aria-label={`Remove ${tool.procedure}`}
          onClick={() => onRemove(tool._id)} className="shrink-0 text-red-500">
          <X className="size-3" />
        </button>
      )}
    </div>
  );
}
