# Technical Plan: Phase 2 NFR Improvement

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

Use exactly two `video_tool` replicas on the existing `video_queue`, each with
`prefetch_count=1`. Scale with `docker compose up -d --scale video_tool=2` for
the measured final configuration; use one replica for baseline. Keep the
default local Compose configuration at one replica. Do not create a
subtitle-specific queue or change the `projects` dispatch contract in this
phase. Capture logs and resource samples from both replicas.

### Consequences and affected components

Components: evaluation worker-group observation and reporting; Docker Compose
runtime scale for `video_tool`; verify `Tools/video/video.py`, RabbitMQ routing,
and the existing `projects` dispatch/reply path without changing their message
contract. Two workers may increase CPU and memory use, RabbitMQ unacked work and
shared-volume contention, and may finish jobs out of order. Validate ack timing,
unique outputs, temporary-file cleanup and result commit guards.

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

Persist recoverable project/run status through the `projects` service and show
it in a non-blocking surface that remains available across dashboard navigation.
Hydrate the surface from an authorized status snapshot after route changes and
refresh, then reconcile live WebSocket events using run tokens/timestamps. Keep
the existing process lifecycle and result semantics. Retain cancellation via
the existing API/UI path only if it remains supported; do not add cancellation
semantics.

### Consequences and affected components

Components: `frontend/app/dashboard/[pid]/page.tsx`, shared dashboard status UI,
`frontend/lib/queries/projects.ts`, `projects/models/project.js` and/or
`projects/models/process.js`, project process/status routes and RabbitMQ
progress handling in `Tools/video/video.py` / `projects`. Durable state adds
database writes and read/API coupling; status must distinguish active,
completed, failed, cancelled and stale runs. Measure status/API request counts
and subtitle duration as secondary effects.

### Functional preservation

Preserve progress percentages/events, job completion and error messages, result
refresh, and project permissions. Regression checks cover image and video
processing, navigation during jobs, refresh/reconnect recovery, and ensuring
that stale status is not shown as active or complete. Evaluate the four
specified interactions with the same workload and browser conditions before
and after.

## Detailed execution sequence and gates

### Gate 0 — Official baselines before application changes

1. Resolve tag `phase2-base` to a commit SHA and record it with host/Docker
   versions, Docker limits, image IDs, sample names/hashes, premium-account
   identifier in redacted form, Chromium version/viewport and harness revision.
2. First extend `evaluation/` observation support to discover the worker group.
   It must sample logs/stats for all `video_tool` containers, retain each
   container's samples, and calculate group CPU/memory sums at aligned
   timestamps. Keep existing API workload, metric names, dispatch delay and
   sampling interval.
3. Add offline evaluation tests for zero/one/two worker discovery, changing
   container IDs, per-container log matching, missing or malformed samples, and
   group resource aggregation. Run evaluation tests before collecting evidence.
4. On `phase2-base`, run performance with one worker (`--scale video_tool=1`):
   one uncounted warm-up plus three valid A/B runs. Preserve all invalid
   attempts and the three valid summaries.
5. On the same checkout, run the browser protocol with a separate warm-up plus
   three valid usability trials. Project A uses the same fixed 10-second clip
   containing speech and subtitles; Project B remains independent and is used
   only to exercise its toolbar. Capture all four interaction outcomes and
   navigation/refresh recovery.

**Gate condition:** do not modify application code until both baseline sets are
complete, reproducible and archived. Existing local evidence is not a substitute.

### NFR 1 — Detailed implementation and validation

#### Alternatives and final selection

- **Selected:** bounded horizontal replication of the existing worker. Both
  workers consume `video_queue`, have QoS `prefetch_count=1`, and process the
  whole video pipeline as they do now. Start the measured final configuration
  with `docker compose up -d --scale video_tool=2`; do not commit two replicas
  as the default stack size.
- **Rejected:** route subtitles to a dedicated queue/worker. It would split the
  existing whole-pipeline message and require orchestration, output ownership,
  progress and failure semantics to change in `projects`.
- **Rejected:** concurrency within one Python worker. It increases memory/CPU
  contention inside one container and complicates ack/error isolation without
  the selected replica boundary.

#### Components and sequence

1. `evaluation/run_scenario.py`: discover containers by Compose project/service
   labels rather than assuming a single `picturas-video_tool-1` name. Associate
   Docker log timestamps with A/B by pipeline as before, searching every worker.
   Record container ID/name with each observation.
2. Resource sampling: query Docker stats for all discovered replicas once per
   sample interval. Keep per-worker CPU/memory. For each aligned timestamp,
   calculate group CPU as sum of percentages and group memory as sum of bytes;
   derive group peaks without replacing the existing metric names. Missing a
   replica during an active run invalidates the resource observation/run.
3. `evaluation/summarize.py`: aggregate the unchanged eight metrics over valid
   measured runs; ensure evidence manifests identify the worker count. Keep
   warm-up and invalid runs excluded from aggregates but present in raw evidence.
4. Compose runtime: baseline one replica and final two replicas, same image
   build, host, Docker limits and volumes. Confirm both replicas use the same
   `video_queue`, `image_data`, and `whisper_models` volumes. Do not edit queue
   definitions or project dispatch.
5. `Tools/video/video.py`: leave ack-after-completion, callback behavior and
   `prefetch_count=1` intact unless the validation reveals a narrowly scoped
   observability defect. Each log entry must be attributable to its container.
6. Run functional regressions and a multi-video same-project batch under two
   workers. Specifically force/observe out-of-order completion and verify that
   registration barriers, tokens and result commits still yield every expected
   result exactly once.
7. On the integrated final application commit, run one warm-up plus three valid
   performance runs with two replicas. Compare per-run values, mean/min/max,
   target/minimum and all secondary measures to the official baseline.

#### Risks and mitigations

- Two simultaneous jobs may exceed available host capacity. Do not introduce an
  artificial CPU/memory ceiling; report per-worker and group peaks, host limits,
  OOMs and restarts. Worker crash, OOM or missing result invalidates that run.
- Parallel videos from one project may complete out of order. Validate batch
  registration, unique output paths, run-token commit guards and rollback; do
  not rely on RabbitMQ delivery order for completion order.
- Workers share media/model volumes. Verify distinct per-job paths and safe
  model cache use; check failed jobs leave no partial output.
- Container names can change on restart. Use Compose service labels/IDs, and
  fail measurement clearly if the expected worker set is not observable.
- Two replicas may move the bottleneck to RabbitMQ, storage or CPU. Report
  ready/unacked maxima, group/per-worker resources, processing duration and
  failures; interpret the wait metric together with those observations.

#### Functional preservation and test evidence

- Run project Node regression suites, especially
  `video-pipeline.test.js`, `process-batch.test.js`, and `frame-extraction.test.js`.
- Run all `Tools/video/tests`, including audio/no-audio subtitles, frame
  extraction, failure cleanup, trim/speed and preview.
- Run the full app image-processing regression coverage. Compare result counts,
  media IDs, output types and pipeline order before/after.
- Manually process multiple videos in one project with two replicas and confirm
  all outputs are committed once, no stale worker result overwrites the active
  run, and queue routing remains `video_queue`.
- Run evaluation offline tests, then final warm-up plus three valid runs. Archive
  raw logs, samples, summaries, environment manifest, printed tables, worker
  identities, restarts and invalid attempts under ignored `evaluation/evidence/`.

### NFR 2 — Detailed implementation and validation

#### Alternatives and final selection

- **Selected:** store a minimal authoritative run-status projection in
  `projects`; serve a permission-checked status snapshot on page entry/refresh;
  continue live updates through the existing WebSocket transport; render a
  non-blocking status surface across dashboard navigation.
- **Rejected:** remove the overlay but keep state only in the dashboard
  component. It fails refresh recovery.
- **Rejected:** browser storage as the status source. It cannot reliably
  distinguish active, completed, failed, cancelled or stale server work.
- **Rejected:** minimize-only modal. It keeps the blocking state and does not
  recover after reload.

#### Status flow and affected components

1. `projects/routes/projects.js` remains the authority for process start,
   completion, failure and cancellation. Reuse its process records and
   `activeToken`/`committedToken` checks. Add only the minimal durable projection
   needed to identify run state, timestamps and each video's latest progress.
2. `Tools/video/video.py` currently publishes progress directly to `ws_queue`.
   Route typed progress observations through the existing `project_queue` so
   `projects` can validate and persist them before emitting the existing
   `video-progress` client event to `ws_queue`. Carry originating process
   message ID, project/media IDs, run token, percent, preview flag and timestamp.
   Preserve the browser-facing event meaning and do not add a new queue.
3. The existing `projects` Rabbit consumer must distinguish progress events from
   worker result replies before result handling. Verify ack/retry behavior;
   reject unknown, stale, cancelled or token-mismatched events. Persist only
   monotonic integer percent changes to avoid a database write per frame.
4. Add an authorized status read in the project service only if existing project
   and result reads cannot provide the active lifecycle. It returns current run
   state/progress without credentials and applies the same owner/share access
   checks as the project read.
5. `frontend/lib/queries/projects.ts` and API types load that snapshot on route
   entry and refresh. Reconcile it against WebSocket events by run token and
   update timestamp; late HTTP responses or duplicate events must not roll
   progress back.
6. Replace the full-screen blocking overlay in
   `frontend/app/dashboard/[pid]/page.tsx` with a non-blocking status surface in
   the shared dashboard shell. Opening B and using its toolbar must not submit a
   second processing job. Returning to A restores the latest status.
7. Preserve the current cancel endpoint, version protocol and button if the API
   is present at baseline. Mark the run terminal and reject late updates using
   the current token semantics. Do not create cancellation behavior if absent.

#### Risks and mitigations

- Progress events can duplicate, arrive out of order or race completion. Make
  updates idempotent and monotonic; terminal states take precedence; reject
  mismatched run tokens. Test delayed, duplicate and post-cancel events.
- New durable status creates DB and RabbitMQ load. Persist only percent changes;
  measure API/status request counts, subtitle duration and queue/resource
  metrics. Do not add an arbitrary rate threshold.
- Status endpoints/events may leak another user's work. Reuse project owner,
  runner and share authorization checks; test owner, authorized shared viewer
  and unauthorized viewer.
- Navigation, refresh and reconnect race with event delivery. Hydrate from the
  server snapshot and reconcile by token/timestamp; do not trust local state as
  authoritative.
- Lifecycle state may remain active after worker or API failure. Define and test
  transitions for start, progress, success, failure and cancel; ensure terminal
  outcomes are durable and stale runs are not displayed as active.
- UI change may affect cancellation. Preserve the existing API/UI path and
  confirm that late worker outputs cannot overwrite cancelled/committed results.

#### Functional preservation and test evidence

- Add projects tests for status state transitions, permissions, token matching,
  progress monotonicity, terminal precedence and idempotency.
- Add frontend tests for status hydration, navigation, refresh, snapshot/socket
  races, error/complete states, toolbar usability and cancel behavior where
  supported.
- Run the existing project Node suites, all video worker pytest tests, and the
  frontend type/lint/build checks. Confirm image processing and result handling
  remain unchanged.
- Run the specified three-trial browser protocol: A subtitles on the 10-second
  speech clip; B toolbar without applying; return to A; navigation recovery and
  refresh recovery. Record each scored action and status/API request count.
- On the integrated final commit, repeat the performance scenario too, since
  durable progress writes may affect project/RabbitMQ processing. Use two
  replicas and the same frozen harness revision/conditions as baseline.

## Integrated completion gate

1. Both official baselines exist on the `phase2-base` commit, each with one
   warm-up and three valid runs/trials; raw invalid attempts are retained.
2. Both NFRs are implemented on one recorded final commit. No subtitle queue or
   changed `projects` dispatch contract is introduced.
3. Automated image, project, video and frontend regression checks pass; manual
   preservation checks and the two measurement protocols are recorded.
4. Final performance and usability sets use the shared conditions, same
   measurement definitions, one warm-up and three valid runs. Invalid attempts
   remain archived and excluded from aggregation.
5. Results report baseline/final metrics, targets/minimums, side effects,
   failures and limitations. The report also records AI tools/agents, skills,
   delegated tasks, accepted/rejected suggestions and human validation.
6. Evidence remains local under ignored `evaluation/evidence/`; no credentials,
   tokens or generated evidence are committed.
