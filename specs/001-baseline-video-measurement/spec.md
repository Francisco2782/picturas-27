# Feature Specification: Video Processing Baseline Measurement

**Feature Branch**: `001-baseline-video-measurement`

**Created**: 2026-11-10

**Status**: Draft

**Input**: User description: "Create a reproducible baseline measurement harness for
video processing NFR evidence. Run a subtitles job and a brightness workload against
fresh projects, record timing, queue depth, and worker resource usage, support a
warm-up plus repeated runs, and keep all artifacts under evaluation/ without changing
application code."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Run a Reproducible Baseline Scenario (Priority: P1)

As a Phase 2 evaluator, I want one command to create fresh projects and run the
defined video workload so that I can measure the unmodified system without manual
clicking or accidentally reusing stale state.

**Why this priority**: The baseline is the reference needed to evaluate every later
refactoring claim.

**Independent Test**: With the stack running and a premium account configured outside
the repository, run the scenario command for one warm-up and three measured runs.
Verify that each measured run uses two newly created projects, starts the long job
before the short workload with a 1–2 second delay, and completes without manual
intervention.

**Acceptance Scenarios**:

1. **Given** a running stack, valid premium credentials supplied through the local
   environment, and the required sample videos, **When** the evaluator starts the
   command with three measured runs, **Then** the command performs one uncounted
   warm-up and three measured runs using fresh projects for every run.
2. **Given** a run is starting, **When** project A and project B are prepared,
   **Then** project A contains the 177-second speech video with subtitles and project
   B contains two copies of the 10-second video plus the 6-second video with
   brightness, and A processing starts before B processing.
3. **Given** a project version conflict or transient request failure occurs, **When**
   the runner handles the response, **Then** it reports the affected run and
   operation clearly and does not silently treat an incomplete run as valid.

---

### User Story 2 - Inspect Per-Run Evidence (Priority: P1)

As an evaluator, I want raw samples and a per-run summary so that I can inspect
exactly how long each workload waited and ran, and correlate timing with queue and
resource behavior.

**Why this priority**: A single aggregate number cannot demonstrate serialization or
explain a change in performance.

**Independent Test**: Complete one valid measured run and inspect its output files.
Confirm that the run contains timestamps and durations for both projects, B's
pre-processing wait, makespan, queue samples, CPU samples, memory samples, and the
specified maxima and peaks.

**Acceptance Scenarios**:

1. **Given** a valid run, **When** its evidence is inspected, **Then** it includes
   project A start, end, and duration; project B start, end, and duration; B's wait
   before its job starts; and the total makespan.
2. **Given** queue and worker observations are available, **When** the run summary is
   generated, **Then** it reports maximum ready messages, maximum unacknowledged
   messages, peak CPU, and peak memory, with the sampling timestamps retained.
3. **Given** a run fails or is incomplete, **When** the command exits, **Then** it
   marks the run invalid and explains the failure rather than including it in the
   measured statistics.

---

### User Story 3 - Compare Repeated Measurements (Priority: P2)

As a project maintainer, I want mean, minimum, and maximum across valid runs so that
baseline evidence reflects typical and boundary behavior rather than one lucky
observation.

**Why this priority**: Repeated measurements make comparison with the refactored
system defensible and expose unstable scenarios.

**Independent Test**: Run the command with at least three valid runs and verify that
the printed summary contains one row per run and aggregate mean, minimum, and
maximum for every requested timing and resource metric.

**Acceptance Scenarios**:

1. **Given** N valid measured runs, **When** the command finishes, **Then** it prints
   a readable table containing per-run values and aggregate mean, minimum, and
   maximum for A duration, B duration, B wait, makespan, maximum ready, maximum
   unacknowledged, peak CPU, and peak memory.
2. **Given** the same scenario is run against the baseline and a later refactoring,
   **When** the evaluator compares the result directories, **Then** both executions
   use the same workload definition, sampling interval, run count, and environment
   description.

### Edge Cases

- Missing sample videos MUST produce a clear failure naming the missing path before
  any run is counted.
- Missing, invalid, or non-premium credentials MUST produce a clear prerequisite
  failure; the runner MUST not claim a valid baseline.
- An unavailable stack, queue, worker, or resource observation MUST invalidate the
  affected run and identify the unavailable dependency.
- Self-signed HTTPS certificates MUST not prevent the documented local scenario from
  connecting.
- A request returning HTTP 409 due to project version state MUST be reported with
  project and operation context; stale projects MUST never be reused as a fallback.
- A worker or processing job that does not finish MUST be recorded as a failed run
  with the reason and available raw evidence.
- Fewer than the requested number of valid runs MUST be reported as insufficient
  evidence rather than summarized as if the requested sample size were met.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The evaluation harness MUST run the complete scenario from one command
  with a configurable warm-up count and measured run count.
- **FR-002**: The harness MUST create two new projects for every run and MUST never
  reuse a project or silently recover by using an existing project.
- **FR-003**: The harness MUST prepare project A with
  `speech_mandela_177s_1080p.webm` and the `[subtitles]` pipeline.
- **FR-004**: The harness MUST prepare project B with two uploads of
  `sample_10s_720p.mp4`, one upload of `sample_6s.mov`, and the `[brightness]`
  pipeline.
- **FR-005**: The harness MUST start processing A before B and MUST start B 1–2
  seconds after A, recording the actual timestamps.
- **FR-006**: The harness MUST record start, end, and duration for both projects,
  B's wait before its job starts, and the overall makespan.
- **FR-007**: The harness MUST sample video queue ready and unacknowledged depth at
  approximately one-second intervals while the scenario is active.
- **FR-008**: The harness MUST sample video-worker CPU and memory at approximately
  one-second intervals while the scenario is active.
- **FR-009**: The harness MUST write timestamped raw observations and a per-run
  summary containing all metrics required by FR-006 through FR-008.
- **FR-010**: The harness MUST calculate and print mean, minimum, and maximum over
  valid measured runs for every per-run summary metric.
- **FR-011**: The warm-up run MUST be excluded from aggregate statistics, and the
  harness MUST identify warm-up, valid, invalid, and incomplete runs distinctly.
- **FR-012**: The harness MUST support the same scenario and invocation against the
  baseline commit and the refactored system without application-code changes.
- **FR-013**: The harness MUST handle HTTP 409 project version conflicts explicitly,
  preserve their diagnostic context, and invalidate rather than mislabel affected
  runs.
- **FR-014**: The harness MUST support the local self-signed HTTPS certificate
  configuration required by the documented environment without weakening
  certificate handling outside that explicit local setting.
- **FR-015**: The harness MUST require premium-capable credentials for the 177-second
  video and MUST keep credentials outside versioned files.
- **FR-016**: All scripts, configuration, workload definitions, raw evidence, summary
  outputs, and environment instructions MUST be stored under `evaluation/`; no
  application source, deployment configuration, queue definitions, or frontend file
  may be changed.
- **FR-017**: Failures MUST produce non-zero completion status and a clear message
  naming the failed prerequisite, request, project, or observation.
- **FR-018**: The documented command MUST complete warm-up plus three measured runs
  without manual clicking when all prerequisites are available.

### Key Entities

- **Scenario Run**: One warm-up or measured execution using two newly created
  projects, with status, timestamps, workload identity, and validity.
- **Project Workload**: The fixed media and ordered pipeline assigned to project A or
  project B for a run.
- **Raw Observation**: A timestamped queue-depth or worker-resource sample captured
  during a run.
- **Run Summary**: Derived timing, queue, resource, and validity metrics for one run.
- **Aggregate Summary**: Mean, minimum, and maximum of each requested metric across
  valid measured runs, excluding warm-up and invalid runs.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A second person following the repository instructions can execute one
  documented command to complete one warm-up and three measured runs without manual
  clicking when the stated prerequisites are available.
- **SC-002**: Every valid measured run produces exactly one per-run summary with all
  eight requested metrics: A duration, B duration, B wait, makespan, maximum ready,
  maximum unacknowledged, peak CPU, and peak memory.
- **SC-003**: Every valid measured run retains timestamped raw observations at an
  average interval no greater than 1.5 seconds while processing is active.
- **SC-004**: Aggregate output includes mean, minimum, and maximum for all eight
  requested metrics and excludes the warm-up and invalid runs.
- **SC-005**: Across three requested measured runs, the command either produces
  three valid summaries or exits with a clear statement that the required evidence
  was not obtained; it never reports partial evidence as complete.
- **SC-006**: Repeating the scenario against baseline and refactored checkouts uses
  identical workload files, run parameters, sampling interval, and documented
  environment fields.
- **SC-007**: No repository-tracked evaluation artifact contains credentials,
  access tokens, or other secrets.

## Assumptions

- The evaluator starts the documented local stack before running the harness and has
  access to the required queue and worker observations.
- Premium credentials are supplied through an environment mechanism documented for
  local use and are not committed to the repository.
- The three named sample videos exist at the paths specified by the feature and are
  unchanged between baseline and final measurements.
- The local stack exposes the existing project, media, processing, queue, and worker
  behavior needed by the scenario; this feature does not alter those services.
- A one-to-two-second dispatch gap and approximately one-second observation interval
  are acceptable repeatability tolerances for the baseline scenario.
- Aggregate mean, minimum, and maximum are calculated across valid measured runs
  using one documented convention consistently for baseline and final measurements.
- Evaluation output may contain timing and resource data but must not contain
  credentials, tokens, or personal account information.
