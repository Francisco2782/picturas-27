# NFR Improvement Specification

**Baseline checkout:** repository tag `phase2-base`. Record the resolved commit SHA
in each evidence set and in the Phase 2 report. Existing files in
`evaluation/evidence/` are provisional and are not accepted as baseline results.

**Scope:** refactor the existing system while preserving its functional behavior.
The usability improvement may change the visible processing experience because
operability during processing is the subject of that NFR; it must not add unrelated
product functionality.

## Shared measurement conditions

Use the same host machine and Docker engine/base dependencies, Docker resource
limits, media samples, premium account, Chromium browser, 1280×720 viewport, and
harness parameters for baseline and final measurements. The controlled application
change is the specified refactoring; record each application commit and built
image identity. Record versions and configuration so that a second person can
reproduce the runs. Do not record credentials, JWTs, authorization headers, or
other secrets.

For each measurement set, execute one uncounted warm-up followed by three valid
measured runs. Use the same harness parameters and samples in the baseline and
final performance runs. A failed or incomplete run is retained as invalid evidence
and replaced until there are three valid measured runs; do not silently omit its
record. Archive all raw and derived evidence described below.

## NFR 1 — Video processing performance efficiency: capacity

**ISO/IEC 25010:2011:** Performance efficiency, capacity.

### Diagnosis

`Tools/video/video.py:53-54` configures `prefetch_count=1`; `video.py:169-176`
acknowledges a message after its callback and calls the blocking consumer. The
callback runs `process_video` synchronously (`video.py:150-155`). The Compose
service `video_tool` runs one worker by default (`docker-compose.yaml:255-260`).
`Tools/video/subtitles.py:15-21, 60-63` loads Faster-Whisper on CPU and transcribes
inside that same processing path. A subtitle job therefore occupies a worker
while other jobs on `video_queue` wait.

Anonymous and free users face the serialization for permitted video workloads;
premium users can submit longer jobs and experience a larger queue delay. Operators
currently have no additional video-worker capacity by default.

### Decision and scope

Run two `video_tool` replicas consuming the existing `video_queue`, with one
message at a time per replica. Do not introduce a subtitle-specific queue or change
the `projects` dispatch contract in this phase. The baseline uses one replica; the
refactored measurement uses two. This is bounded replica capacity for this
evaluation, not a claim of automatic/dynamic autoscaling.

### Measurement protocol

- **Scenario and load:** use the fixed A/B workload in `evaluation/run_scenario.py`:
  A submits the speech sample with `subtitles`; B submits the two 10-second MP4s
  and one 6-second MOV with `brightness`. The runner submits A before B using its
  configured dispatch gap. Create fresh projects for every warm-up and measured
  run.
- **Baseline:** check out tag `phase2-base`, resolve and record its commit SHA, run
  one warm-up plus three valid measured runs with one worker replica.
- **Final:** use the same application commit plus the refactoring, same host,
  Docker limits, samples, premium account and harness parameters, with exactly two
  `video_tool` replicas on the existing queue. Record the application commit and
  worker image identity.
- **Primary scale/unit:** `b_wait_seconds`, in seconds: first matching brightness
  worker log timestamp minus B's recorded submission timestamp, as derived by the
  evaluation harness. Include the individual three-run values, mean, minimum and
  maximum. Apply the same calculation to both configurations.
- **Baseline value:** provisional only: existing local evidence reports a 65.7 s
  mean (62.6–70.1 s range). It is not accepted as the official baseline. The
  official baseline value is the mean and range from the new three-valid-run
  measurement on `phase2-base`.
- **Target:** final mean B wait at most 15 seconds.
- **Minimum acceptable:** final mean B wait at most 30 seconds, based on three
  valid measured runs.

The 15-second target and 30-second minimum are project acceptance thresholds, not
values prescribed by ISO. They must be compared to the measured official baseline;
the expected benefit is that a second replica can begin B while A occupies the
other replica.

### Acceptance and secondary effects

The NFR is accepted when three valid final runs are produced and the final mean
`b_wait_seconds` meets the 15-second target. A result above 15 seconds but at or
below 30 seconds meets only the minimum; above 30 seconds fails the minimum.
Report the baseline and final per-run values and mean/min/max for all eight harness
metrics: `a_duration_seconds`, `b_duration_seconds`, `b_wait_seconds`,
`makespan_seconds`, `max_ready`, `max_unacked`, `peak_cpu_percent`, and
`peak_memory_bytes`.

CPU and memory are secondary effects, not independent hard ceilings. Report their
three-run peaks and ranges for both configurations, alongside queue ready and
unacknowledged maxima. Also record the number of worker replicas, host/Docker
capacity, worker restarts, out-of-memory events, processing failures and invalid
runs. Any worker crash, OOM event, or loss of a result invalidates that run and
must be reported; do not hide it by reporting only successful samples. No
artificial CPU or memory limit beyond available host/Docker capacity is introduced
by this specification.

Before collecting the official baseline, update the evaluation harness's
observation scope to discover and sample the `video_tool` worker group. Use that
same harness revision and measurement definitions for baseline and final. Collect
matching worker logs from either replica. Sample Docker stats for all replicas at
the harness's one-second interval; retain per-container values and calculate
group CPU as the sum of replica CPU percentages and group memory as the sum of
replica memory bytes at each sample timestamp, then report peak group values and
individual worker peaks. RabbitMQ queue maxima are shared queue observations.
The current single-container setting alone does not establish group resource
usage. Keep the workload, dispatch delay, polling and sampling parameters
unchanged between the baseline and final runs.

### Evidence to archive

Under the ignored local `evaluation/evidence/` directory, preserve for both
baseline and final configurations:

- `run.json`, `samples.csv`, and `summary.json` for warm-up and every measured or
  invalid run;
- the printed per-run and aggregate tables;
- a non-secret environment manifest with tag/commit SHA, harness revision, sample
  filenames and hashes, host and Docker versions/limits, worker image identity,
  replica count, sampling interval, dispatch delay, and run timestamps;
- Docker worker logs and container/resource/restart observations sufficient to
  substantiate failures and secondary effects.

Do not commit evidence or credentials.

## NFR 2 — Usability: operability during processing

**ISO/IEC 25010:2011:** Usability, operability.

### Diagnosis

`frontend/app/dashboard/[pid]/page.tsx:89-94` holds processing and progress in
component state. At `page.tsx:894-904`, `processing` displays a full-viewport
overlay containing the progress card. This blocks the project view during a batch;
the component state is not sufficient to restore current progress after a page
reload.

Anonymous and free users are affected during supported image/video processing;
premium users can be blocked for longer video and subtitle jobs. Operators face
support friction when users cannot continue work or recover progress after
navigation/reload.

### Decision and scope

The scenario uses two independent projects in one premium account session:

- **Project A:** one 10-second video with `subtitles` processing in progress.
- **Project B:** a separate project left available for toolbar interaction.

The usability change must let the evaluator move between these projects and
recover accurate processing status. Test cancellation only if it is supported by
the existing API and remains supported after refactoring; this specification does
not require introducing cancellation.

### Measurement protocol

Use the shared conditions above: baseline at `phase2-base`, same premium account,
Chromium, 1280×720 viewport, host and Docker conditions. For each configuration,
run one warm-up and three valid measured trials with fresh projects and the same
10-second sample containing intelligible speech and the same pipeline. Record
the sample filename/hash; a no-audio or no-speech subtitle no-op does not count as
an active trial. Record screen capture or timestamped observation notes for each
interaction; do not capture credentials or tokens.

For each trial:

1. Start subtitles processing on Project A and wait until an active processing
   state/progress is observable.
2. Open Project B while A is still processing.
3. Use B's toolbar: open it, select a tool and its controls. Do not apply a second
   processing job as part of this usability trial.
4. Return to Project A and verify the displayed processing state/progress.
5. Navigate away and return, then refresh the page and verify that A's current
   status is recovered accurately. Record navigation and refresh outcomes
   separately. If A completes before the active-state checks, mark the trial
   invalid/incomplete and repeat it; retain its record.

The four scored interactions are: (1) open B, (2) use B's toolbar, (3) return to
A, and (4) confirm A's current progress/status. Score each pass only when the
action completes during A's active processing window. The progress/status shown
after return or refresh must match the latest state available to the UI; a stale
active state after completion or a false completion is a failure. Also report
navigation recovery and refresh recovery as separate pass/fail outcomes.

### Quantification and acceptance

- **Scale/unit:** successful scored interactions per trial (0–4) and success
  percentage across the three valid trials; navigation-recovery and
  refresh-recovery pass rate (0–3 each).
- **Baseline:** not yet measured. Do not substitute the earlier source-based 0/4
  estimate. Measure it on `phase2-base` using the exact protocol above before
  application changes.
- **Target:** all four interactions pass in all three valid trials (12/12), and
  both navigation and refresh recover the correct current status in all three
  trials (3/3 each).
- **Minimum acceptable:** at least 3/4 interactions pass in every valid trial,
  and correct current status is recovered after both navigation and refresh in
  all three trials. No false completion may be displayed.

These are project acceptance thresholds, not ISO-prescribed values. Record the
baseline and final counts, per-trial results, and percentages; do not report only
an aggregate score that hides a failed trial.

### Secondary effects and evidence to archive

Report subtitle job duration and completion/failure for each trial so that the UI
change is not credited if it prevents or delays processing. Record the number of
status/API requests made during each trial and any duplicate/stale progress events
or status mismatches as secondary effects; do not impose an arbitrary request or
CPU limit in this specification. Preserve a redacted trial record containing the
configuration, sample identity, start/end times, four interaction outcomes,
navigation/refresh outcomes, observed status/progress, subtitle result, and
timestamped notes or screenshots. Archive these artifacts beside the relevant
baseline/final evidence without credentials or session tokens.

## Functional preservation

The refactoring must preserve existing image and video pipelines, ordering,
result counts, permissions, error reporting, and progress meaning. Regression
evidence must include the existing image and video automated suites and manual
confirmation of the two measurement scenarios. Confirm that the same valid input
still produces results, subtitle processing retains existing audio/output
behavior, and worker errors or UI refresh do not report false completion.

The team must document in the Phase 2 report the AI tools/agents and skills used,
tasks delegated, changes accepted or rejected, and human validation performed.
The team is responsible for manually confirming test results and measurement
reproducibility. Do not include secrets in source, reports, or archived evidence.
