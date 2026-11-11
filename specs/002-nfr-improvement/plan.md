# NFR Improvement Plan

The Phase 2 work is constrained to refactoring existing behavior. Establish and
archive the baseline before any application change. The measured performance
baseline already in `evaluation/evidence/` is provisional until rerun on the
commit named in the report.

## NFR 1 — Video processing performance efficiency: capacity

### Alternatives considered

1. Increase `video_tool` replicas, keeping the shared worker implementation.
2. Move CPU-heavy subtitles into a dedicated worker/queue while retaining the
   existing worker for ordinary video pipelines.
3. Add parallel processing inside one worker process.

### Decision

Prefer separating subtitle recognition from ordinary video work, with explicit
queue capacity and bounded concurrency. Confirm the design against current
message/result ownership before implementation. A replica-only change is a
smaller fallback if routing can safely distinguish subtitle work without
changing pipeline semantics. Avoid unconstrained threads in a CPU-bound
Faster-Whisper process.

### Consequences and affected components

Likely components: `Tools/video/video.py`, `Tools/video/subtitles.py`,
`Tools/video/video_processor.py`, RabbitMQ definitions, `docker-compose.yaml`,
and the projects orchestrator's dispatch/reply path. More parallel workers may
increase CPU and memory pressure, RabbitMQ unacked work, and storage contention;
subtitle and ordinary job completion order may change. Queue routing, progress,
ack/retry, temporary-file cleanup, and result commits need explicit treatment.

### Functional preservation

Run image and video regression suites, including ordered pipeline effects,
subtitle audio preservation/no-op cases, failures and cleanup. Re-run the same
evaluation workload and parameters; require three valid runs, compare all eight
metrics, and report CPU/memory/queue side effects as well as B wait.

## NFR 2 — Usability: operability during processing

### Alternatives considered

1. Replace the blocking overlay with a non-blocking progress panel while keeping
   the current in-memory state.
2. Persist active job state server-side and restore it after navigation/reload,
   with a non-blocking project-level status surface.
3. Keep the modal but add a minimize control.

### Decision

Prefer persisted/recoverable processing status plus a non-blocking progress
surface. A minimize-only modal does not address reload recovery. Keep the job's
current API lifecycle and result semantics; cancellation remains governed by
existing behavior.

### Consequences and affected components

Likely components: `frontend/app/dashboard/[pid]/page.tsx`, project/process API
and persistence, WebSocket reconnection/state refresh, and possibly shared
navigation/status UI. Persisting state adds API and database coupling and raises
the need to distinguish running, completed, failed, and stale jobs. It may
increase backend reads and frontend state complexity. Maintainability and
performance of status polling are potential side effects.

### Functional preservation

Preserve progress percentages/events, job completion and error messages, result
refresh, and project permissions. Regression checks cover image and video
processing, navigation during jobs, refresh/reconnect recovery, and ensuring
that stale status is not shown as active or complete. Evaluate the four
specified interactions with the same workload and browser conditions before
and after.
