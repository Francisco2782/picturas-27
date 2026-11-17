# Phase 2 implementation log

This log records each approved implementation increment, its validation, and
remaining work. The official baseline evidence remains local under the ignored
`evaluation/evidence/` directory.

## Approval and starting point

- The team approved baseline gate B-04 on 2026-11-17.
- Application baseline tag: `phase2-base`, commit
  `052310226c51fa57a17101c7bd1ad795674aac95`.
- Implementation branch: `main`, starting commit
  `afb84e5c818820f807bb504a8ed9f0a3162cc9dd`.
- The user requested incremental implementation with documentation at each
  step.

## Increment U-01 — Durable processing-run state

**Status: complete.**

### Changes

- Added the optional `processingRun` snapshot to the Project model. It records
  the current run token, lifecycle state/outcome, start/update/finish times, and
  each video's latest progress, preview flag and update time.
- Added pure transition helpers for starting a run, accepting monotonic
  per-video progress and finishing with `completed`, `failed` or `cancelled`.
  Only the latest run is retained; starting a new run replaces the old snapshot.
- New image/video processing requests persist a `running` snapshot alongside
  the existing `activeToken` update.
- A worker error marks the matching active run failed. A successful result
  changes the status to completed only when the matching active token commits.
  Cancellation records the terminal outcome while advancing the existing
  `activeToken` invalidation mechanism.
- The commit update is conditional on the run still being active and running;
  delayed sibling results cannot turn a failed or terminal run into success.
  Documents without a `processingRun` snapshot retain the previous commit path
  for jobs that were already in flight during rollout.

### Validation

- `node --check routes/projects.js`
- `node --check controllers/project.js`
- `node --check models/project.js`
- `node --test tests/*.test.js` from `projects/`: **14 passed, 0 failed**.
- Tests cover run creation, unique media IDs, schema validation, monotonic
  progress, stale token/timestamp rejection, terminal precedence, cancellation,
  active-token commit behavior, and failure persistence.

### Scope and next step

No new queue or frontend behavior was added in this increment. Progress
transition helpers are ready for U-02, which will validate and persist worker
progress messages. Authorized status snapshots and the recoverable UI remain
for U-03 and U-04.

## Increment P-01 — Bounded Compose worker scaling

**Status: complete.**

### Validation

- Started the second worker with
  `docker compose up -d --no-build --scale video_tool=2 video_tool`.
- Both containers use image
  `sha256:5126bfec8ab05cd5dc981878aa9dabb4c4865a3c1475620ef8ec6b7a2961a975`
  and were running at observation time.
- RabbitMQ reported two active consumers on the existing `video_queue`; both
  require acknowledgements and each has `prefetch_count=1`.
- Both containers mount the same named `image_data` and `whisper_models`
  volumes.
- `docker-compose.yaml` still has no replica override; local Compose defaults
  to one worker. No queue or dispatch contract was changed.
- Raw local smoke evidence is in
  `evaluation/evidence/phase2-p01-smoke-2026-11-17/`.

The two-replica runtime is left active for the upcoming concurrency and worker
failure checks. P-02 and P-03 remain pending.

## Pending increments

- Agreed task order (2026-11-17): finish Performance before continuing
  Usability. P-01 and U-01 are complete. Do not start U-02 through U-04 until
  P-02 and P-03 are complete.
- P-02 and P-03: batch safety, resource/failure behavior. P-01 passed its
  bounded scaling smoke check.
- Resume Usability at U-02, then U-03 and U-04 after Performance is complete.
- R-01 through R-04, M-01 through M-04, and D-01 through D-02: regression,
  final measurements and report.
