# Implementation Plan: Video Processing Baseline Measurement

**Branch**: `001-baseline-video-measurement` | **Date**: 2026-11-10 |
**Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/001-baseline-video-measurement/spec.md`

**Scope**: Evaluation-only Python runner and documentation. No application files,
Docker Compose files, queue definitions, or service code are changed.

## Summary

Create a repeatable command that provisions fresh projects, uploads the fixed long
and short video workloads, applies their pipelines, dispatches A before B, observes
completion and worker contention, and writes raw and aggregate evidence. The design
uses the existing HTTP gateway for control, RabbitMQ management HTTP for queue depth,
Docker CLI statistics for worker resources, and video-worker logs for B's
processing-start timestamp. RabbitMQ queue depth is retained as confirmation only.

## Technical Context

**Language/Version**: Python 3, standard library plus `requests`.

**Primary Dependencies**: Python standard library, `requests`, Docker CLI, and
RabbitMQ management HTTP.

**Storage**: Versioned scripts and documentation under `evaluation/`; each execution
writes an ignored or operator-selected evidence directory containing JSON/CSV data.

**Testing**: Offline unit tests for request construction, version propagation, run
state, summary statistics, and failure handling; a stack-running smoke scenario for
the end-to-end harness.

**Target Platform**: Linux host running the Docker Compose stack, with Python 3 and
Docker CLI available.

**Project Type**: Evaluation CLI and evidence collector for an existing web system.

**Performance Goals**: Dispatch B 1–2 seconds after A; sample queue and worker
resources approximately every second; complete warm-up plus three valid runs without
manual interaction.

**Constraints**: Fresh projects per run; premium account; no application changes;
self-signed local HTTPS; explicit HTTP 409 handling; no secrets in versioned files;
exclude `corrupted.mp4` and `too_long_90s.mp4`.

**Scale/Scope**: Two projects and four video uploads per run, one warm-up plus three
valid runs by default, one video worker log stream and queue, and one aggregate
summary with mean, minimum, and maximum.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Gate | Status | Evidence |
|---|---|---|
| Refactoring-only scope | PASS | All deliverables are under `evaluation/` and plan artifacts; no application behavior changes. |
| Baseline before change and repeatable final method | PASS | Fixed workload, parameters, sampling interval, and environment record are specified. |
| Quantified NFR evidence | PASS | Timing, queue, CPU, and memory units and derivations are defined in the design artifacts. |
| Reproducible evidence | PASS | Runner, summarizer, README, raw schema, and environment capture are versioned. |
| Existing conventions and simplicity | PASS | Python standard library plus `requests`; reuses the existing sampling endpoint and gateway. |
| AI use documented and human validated | PASS | Human review is required before committing evaluation code and evidence. |

No gate violations require complexity justification.

**Post-Design Recheck**: PASS. The design keeps all implementation in
`evaluation/`, uses a fixed baseline method, records quantified evidence and
uncertainty, avoids secrets, and introduces no application or deployment changes.

## Project Structure

### Documentation (this feature)

```text
specs/001-baseline-video-measurement/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
└── tasks.md             # Created by /speckit-tasks
```

### Source Code (repository root)

```text
evaluation/
├── run_scenario.py
├── summarize.py
├── README.md
├── sample_baseline.sh
└── tests/
    ├── test_run_scenario.py
    └── test_summarize.py
```

**Structure Decision**: The deliverable is an evaluation CLI under `evaluation/`.
The feature directory contains design and contract documentation only; implementation
tasks will create the runner, summarizer, README, and focused tests in the existing
evaluation area. Existing application directories are read-only inputs.

## Complexity Tracking

No constitution violations.
