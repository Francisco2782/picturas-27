# Phase 2 NFR Improvement Tasks

Implementation checklist for the two requirements in [spec.md](./spec.md) and
the architecture in [plan.md](./plan.md). Tasks are dependency-ordered; do not
start application changes before the official baseline gate is complete.

## 0. Baseline already present and official baseline gate

### Existing baseline references

- Repository tag `phase2-base` is the official source checkout; resolve and
  record its commit SHA when collecting official evidence.
- `evaluation/evidence/` currently contains provisional local runs only. Preserve
  them as provisional; do not label them as the official baseline or overwrite
  their provenance.
- Official baseline measurements are not complete until tasks B-02 and B-03
  below pass. They must be captured before any application source changes.

### Baseline preparation and capture

- [ ] **B-01 — Extend evaluation worker-group observations.**
  - **Depends on:** none; evaluation tooling changes only.
  - **Components/files:** `evaluation/run_scenario.py`,
    `evaluation/summarize.py`, `evaluation/tests/`; Docker CLI observation of
    Compose service `video_tool`.
  - **Work:** discover all worker replicas by Compose service/project identity;
    collect A/B logs across the group; sample stats for each replica at the
    existing interval; retain per-container samples and calculate timestamped
    group CPU/memory sums. Keep scenario requests, eight metric names, sample
    files, dispatch delay, polling and sampling parameters unchanged.
  - **Tests:** add/run offline tests for zero/one/two replicas, changing
    container IDs, per-replica logs, missing/malformed stats, timestamp
    alignment, group sums, and warm-up/invalid filtering.
  - **Acceptance:** evaluation tests pass; one- and two-replica observations are
    attributable to every container; missing replica data fails clearly rather
    than silently sampling only `video_tool-1`; no secrets are serialized.

- [ ] **B-02 — Capture official performance baseline.**
  - **Depends on:** B-01.
  - **Components/files:** tag `phase2-base`; frozen `evaluation/` harness;
    local ignored `evaluation/evidence/` output.
  - **Work:** run one warm-up plus three valid measured runs with one
    `video_tool` replica and the prescribed A/B workload. Retain invalid and
    incomplete attempts; obtain replacement valid runs until three are valid.
  - **Tests/validation:** verify A has one expected result, B has three, all eight
    metrics are present, B wait uses the first matching brightness log, and
    queue/resource samples cover the active interval.
  - **Acceptance:** evidence records the resolved `phase2-base` SHA, harness
    revision, sample hashes, host/Docker configuration, one replica, raw runs,
    aggregate output and no credentials. Official baseline mean/range for
    `b_wait_seconds` is calculated from exactly three valid measured runs.

- [ ] **B-03 — Capture official usability baseline.**
  - **Depends on:** B-02's checkout/environment manifest; still on
    `phase2-base`, before application changes.
  - **Components/files:** existing frontend and project service; local redacted
    usability trial records under `evaluation/evidence/`.
  - **Work:** one warm-up plus three valid browser trials in Chromium at
    1280×720, using premium account, fresh Project A/B and the fixed 10-second
    speech-bearing sample. Score the four interactions and navigation/refresh
    recovery separately.
  - **Tests/validation:** confirm A's job is active during each scored action;
    a no-speech/no-audio no-op or job completing before checks is invalid and is
    retained before repeating the trial.
  - **Acceptance:** three valid baseline trials have per-action pass/fail,
    navigation and refresh outcomes, sample hash, timestamps, status
    observations and redacted notes/screenshots. Do not substitute the earlier
    source-based 0/4 estimate.

- [ ] **B-04 — Baseline gate review.**
  - **Depends on:** B-02 and B-03.
  - **Components/files:** both baseline evidence sets and environment manifests.
  - **Tests/validation:** independently replay the summarizer and inspect
    representative raw evidence for provenance and secret leakage.
  - **Acceptance:** both official baseline sets are reproducible and complete;
    team records approval before app implementation starts.

## 1. Implementation — NFR performance capacity

- [ ] **P-01 — Validate bounded Compose scaling.**
  - **Depends on:** B-04.
  - **Components/files:** Compose runtime configuration for `video_tool`,
    `Tools/video/video.py`, RabbitMQ `video_queue`; no default replica change.
  - **Work:** run baseline at `--scale video_tool=1`; final configuration at
    `--scale video_tool=2`. Keep each replica on the existing queue and QoS
    `prefetch_count=1`; do not add a subtitles queue or alter `projects` dispatch.
  - **Tests:** Compose/RabbitMQ smoke check that one and then two worker
    containers are healthy and consuming the same queue; confirm each handles at
    most one unacknowledged job.
  - **Acceptance:** exactly two observable final replicas; queue, message
    contract, shared volumes, ack-after-completion and default local scale remain
    unchanged.

- [ ] **P-02 — Verify concurrent batch result safety.**
  - **Depends on:** P-01.
  - **Components/files:** `projects/routes/projects.js`,
    `projects/utils/processBatch.js`, `projects/controllers/project.js`,
    `projects/tests/process-batch.test.js`, frame/video orchestration tests.
  - **Work:** exercise multiple videos from one project across two replicas,
    including out-of-order completion, cancellation/stale output, and a later
    dispatch failure.
  - **Tests:** existing process-batch, video-pipeline and frame-extraction Node
    suites plus targeted regression coverage for concurrent completion order.
  - **Acceptance:** all expected media results commit exactly once; no run
    commits early, stale result overwrites active result, or registered job is
    lost; rollback remains scoped to the affected batch.

- [ ] **P-03 — Check worker resource and failure behavior.**
  - **Depends on:** P-01 and P-02.
  - **Components/files:** `Tools/video/video.py`, `Tools/video/video_processor.py`,
    shared `image_data` and `whisper_models` volumes, evaluation observations.
  - **Work:** check unique per-job output paths, temporary-file cleanup, shared
    model cache, worker restart and RabbitMQ reconnect behavior with replicas.
  - **Tests:** video worker pytest suite; manual two-worker subtitle and ordinary
    video job smoke test; inspect OOM/restart and queue observations.
  - **Acceptance:** failures are visible and do not leave partial committed
    output; all resource/restart effects are captured; no artificial CPU/memory
    ceiling is added.

## 2. Implementation — NFR usability during processing

- [ ] **U-01 — Define durable run-status model and transitions.**
  - **Depends on:** B-04; can proceed independently of P-01 through P-03.
  - **Components/files:** `projects/models/project.js` and/or
    `projects/models/process.js`, `projects/routes/projects.js`.
  - **Work:** specify minimal persisted run token, lifecycle state, timestamps,
    per-video latest progress and terminal outcome; define start, progress,
    success, failure and cancellation transitions using current active/committed
    token semantics.
  - **Tests:** unit tests for transitions, terminal precedence, stale token
    rejection, monotonic progress and cleanup/retention.
  - **Acceptance:** authoritative status survives service/UI reload and cannot
    report an old run as current; existing result ownership and run tokens remain
    authoritative.

- [ ] **U-02 — Persist worker progress through the projects service.**
  - **Depends on:** U-01.
  - **Components/files:** `Tools/video/video.py`, RabbitMQ helpers,
    `projects/routes/projects.js` project-queue consumer, Process model.
  - **Work:** send a typed progress observation through the existing
    `project_queue` with source process ID, project/media IDs, run token, percent,
    preview flag and timestamp. Validate against the stored process and active
    project token; persist only monotonic integer changes; publish the existing
    browser progress event only after acceptance. Add no new queue.
  - **Tests:** consumer tests for valid, duplicate, stale, cancelled,
    wrong-project and malformed progress messages; ack/retry tests; worker
    payload tests; confirm normal result replies still route correctly.
  - **Acceptance:** progress is durable and attributable to the correct run;
    duplicate/late messages are idempotently ignored; result message and
    browser-facing event semantics remain intact.

- [ ] **U-03 — Add authorized status snapshot.**
  - **Depends on:** U-01 and U-02.
  - **Components/files:** project status route/controller, API gateway route
    forwarding if required, frontend query/API types.
  - **Work:** expose current state for a project only where existing project
    owner/share permissions permit; return run token, state, timestamps and
    per-video progress without secrets.
  - **Tests:** project API tests for owner, permitted shared viewer, unauthorized
    user, active/completed/failed/cancelled state and stale token.
  - **Acceptance:** reload can retrieve the authoritative current status;
    unauthorized users cannot infer another project's processing activity.

- [ ] **U-04 — Replace blocking page state with recoverable status UI.**
  - **Depends on:** U-03.
  - **Components/files:** `frontend/app/dashboard/[pid]/page.tsx`, shared
    dashboard/navigation component, `frontend/lib/queries/projects.ts`, UI
    types and styles.
  - **Work:** make progress non-blocking across A/B navigation; hydrate from the
    API snapshot on entry/refresh; reconcile WebSocket updates by run token and
    timestamp. Keep current progress meaning, error surface and cancel control
    if supported by the existing API. Do not start a job from Project B in the
    usability trial.
  - **Tests:** frontend tests for active status, four actions, route change,
    refresh, reconnect, stale HTTP/socket ordering, terminal states, access and
    cancellation where supported.
  - **Acceptance:** evaluator can open B, use its toolbar, return to A and see
    current status; navigation and refresh recover correct status; no false
    completion or stale active state appears; cancel keeps existing semantics.

## 3. Regression and integrated validation

- [ ] **R-01 — Project orchestration regression.**
  - **Depends on:** P-02, U-03.
  - **Components/files:** `projects/tests/`, routes/models and process
    orchestration.
  - **Tests:** `cd projects && node --test tests/video-pipeline.test.js tests/process-batch.test.js tests/frame-extraction.test.js`, plus new status/concurrency tests.
  - **Acceptance:** all suites pass; images still skip video-only tools; videos
    retain ordered pipeline, expected result counts, unique frames and token-safe
    commits.

- [ ] **R-02 — Video worker regression.**
  - **Depends on:** P-03, U-02.
  - **Components/files:** `Tools/video/`.
  - **Tests:** `cd Tools/video && .venv/bin/python -m pytest -q tests/`.
  - **Acceptance:** all tests pass for probe, effects, trim/speed, previews,
    subtitles, audio/no-audio handling, extraction and cleanup; progress
    reporting does not change output/result behavior.

- [ ] **R-03 — Frontend and end-to-end regression.**
  - **Depends on:** U-04.
  - **Components/files:** `frontend/`, running Compose stack, project API and
    WebSocket path.
  - **Tests:** frontend lint/type/build checks available in the repository;
    manual image/video batch, A/B toolbar, navigation, refresh/reconnect and
    cancel-if-supported checks.
  - **Acceptance:** frontend builds; core interactions and permissions work;
    progress, result refresh, errors and cancellation behavior remain correct.

- [ ] **R-04 — Evaluation harness regression.**
  - **Depends on:** B-01, P-01, U-02 if shared event observations changed.
  - **Components/files:** `evaluation/tests/`, runner and summarizer.
  - **Tests:** `python3 -m pytest evaluation/tests/ -q`.
  - **Acceptance:** all offline tests pass; warm-up/invalid records are excluded;
    group resources and log-derived wait are repeatable; secrets are redacted.

## 4. Final measurements

- [ ] **M-01 — Freeze integrated final configuration.**
  - **Depends on:** R-01 through R-04.
  - **Components/files:** final commit/image manifest, evaluation harness,
    Compose runtime configuration.
  - **Work:** record final commit and image IDs, same host/Docker limits, samples,
    premium account identifier (redacted), Chromium version/viewport and harness
    revision; start exactly two video workers.
  - **Acceptance:** configuration matches baseline except for the selected NFR
    refactorings and two-replica final scale; manifest contains no secrets.

- [ ] **M-02 — Capture final performance measurements.**
  - **Depends on:** M-01.
  - **Components/files:** `evaluation/run_scenario.py`, evidence output.
  - **Work:** one warm-up plus three valid A/B runs; retain invalid attempts.
  - **Tests/validation:** summarize all eight metrics and compare per-run and
    aggregate values with B-02.
  - **Acceptance:** target mean `b_wait_seconds` ≤15 s; ≤30 s meets only the
    minimum. Report group/per-worker CPU and memory, queue maxima, duration,
    failures, OOMs and restarts; no loss of expected results.

- [ ] **M-03 — Capture final usability measurements.**
  - **Depends on:** M-01.
  - **Components/files:** frontend/project status flow and redacted trial records.
  - **Work:** one warm-up plus three valid A/B trials in Chromium 1280×720; retain
    invalid attempts; score all four actions and navigation/refresh recovery.
  - **Acceptance:** target 12/12 actions and 3/3 navigation plus refresh
    recoveries; minimum at least 3/4 per trial and 3/3 recoveries for each path,
    with no false completion. Report subtitle duration, API/status request count,
    stale/duplicate events.

- [ ] **M-04 — Compare integrated side effects.**
  - **Depends on:** M-02 and M-03.
  - **Components/files:** baseline/final evidence sets and summary tables.
  - **Validation:** compare same metrics/conditions; explain outliers, invalid
    attempts, changed CPU/memory/queue behavior, status/API traffic and any
    regression against other NFRs.
  - **Acceptance:** each NFR is reported separately against its baseline, target
    and minimum; all secondary effects and limitations are explicit.

## 5. Report and evidence documentation

- [ ] **D-01 — Archive reproducibility package.**
  - **Depends on:** B-04, M-04.
  - **Components/files:** ignored `evaluation/evidence/`, measurement manifests,
    report references.
  - **Work:** retain raw run JSON/CSV/logs, summaries/tables, replica/resource
    observations, usability scores/screenshots/notes, commit and environment
    manifests. Keep generated evidence local and credentials outside the repo.
  - **Acceptance:** a reviewer can reproduce both measurements; no secret or
    generated evidence is committed.

- [ ] **D-02 — Document analysis and AI use in the report.**
  - **Depends on:** M-04.
  - **Components/files:** Phase 2 report and any project-required code notes.
  - **Work:** explain each diagnosis, ISO classification, alternatives/decision,
    implementation, baseline/final comparison, side effects, unmet thresholds,
    functional regression evidence and limitations. List AI tools/agents,
    skills, delegated tasks, suggestions accepted/rejected and human validation.
  - **Acceptance:** report addresses all six guideline steps for both NFRs and
    states that the team manually verified tests and reproducibility.

## Dependency summary

```text
B-01 → B-02 ─┐
      → B-03 ├→ B-04 → implementation (P-01..03 and U-01..04)
             └───────────────────────────────────────────────┘
P-02 + U-03 → R-01; P-03 + U-02 → R-02; U-04 → R-03; B-01 → R-04
R-01..R-04 → M-01 → M-02 + M-03 → M-04 → D-01 + D-02
```
