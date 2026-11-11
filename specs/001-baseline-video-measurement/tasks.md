---
description: "Task list for the video processing baseline measurement harness"
---

# Tasks: Video Processing Baseline Measurement

**Input**: Design documents from
`specs/001-baseline-video-measurement/`

**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md),
[research.md](./research.md), [data-model.md](./data-model.md),
[contracts/](./contracts/), and [quickstart.md](./quickstart.md)

**Tests**: Offline unit tests and an end-to-end smoke scenario are required by the
implementation plan. No application code may be changed.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Establish the evaluation-only files, configuration conventions, and
safe evidence-output boundaries.

- [X] T001 Create the evaluation harness file layout in `evaluation/run_scenario.py`, `evaluation/summarize.py`, `evaluation/README.md`, and `evaluation/tests/`
- [X] T002 [P] Define environment-variable and CLI configuration defaults, including API base, sample paths, RabbitMQ URL, `RABBITMQ_MANAGEMENT_USER`, `RABBITMQ_MANAGEMENT_PASSWORD`, and `VIDEO_WORKER_CONTAINER`, in `evaluation/run_scenario.py`
- [X] T003 [P] Add ignored/local evidence-output guidance and secret-handling rules to `evaluation/README.md`
- [X] T004 [P] Create the offline test entry points in `evaluation/tests/test_run_scenario.py` and `evaluation/tests/test_summarize.py`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Implement shared domain structures and I/O helpers required by every
user story.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T005 Define `ScenarioRun`, `WorkloadProject`, `ResourceSample`, `RunSummary`, and `AggregateSummary` representations in `evaluation/run_scenario.py`, preserving the data-model enums and required fields
- [X] T006 Implement UTC wall-clock and monotonic timestamp helpers plus JSON/CSV serialization without emitting passwords, JWTs, authorization headers, card data, or other secrets in `evaluation/run_scenario.py`
- [X] T007 Implement an HTTP client with local self-signed-certificate support, JSON/multipart requests, timeout handling, non-zero failure propagation, and explicit HTTP 409 diagnostics in `evaluation/run_scenario.py`
- [X] T008 [P] Implement RabbitMQ management sampling of `messages_ready` and `messages_unacknowledged` from `/api/queues/%2F/video_queue` in `evaluation/run_scenario.py`
- [X] T009 [P] Implement Docker resource sampling for `picturas-video_tool-1`, parsing CPU percent and memory bytes while allowing the container name to be overridden by `VIDEO_WORKER_CONTAINER`, in `evaluation/run_scenario.py`
- [X] T010 [P] Implement timestamped `docker logs --timestamps --since <run-start> <container>` collection and parsing for A (`tools=['subtitles']`) and B (`tools=['brightness']`) in `evaluation/run_scenario.py`
- [X] T011 Implement sample-file validation, exclusion checks for `corrupted.mp4` and `too_long_90s.mp4`, and premium-account prerequisite validation in `evaluation/run_scenario.py`

**Checkpoint**: Shared configuration, safe serialization, HTTP version handling,
RabbitMQ sampling, Docker stats/log parsing, and prerequisites are available for
all user stories.

---

## Phase 3: User Story 1 - Run a Reproducible Baseline Scenario (Priority: P1) 🎯 MVP

**Goal**: Execute one warm-up and N measured runs using fresh projects and the
fixed A/B workload, without manual clicking.

**Independent Test**: With the stack running, premium credentials supplied through
the environment, RabbitMQ reachable, and the three allowed sample files present,
run `python3 evaluation/run_scenario.py --warmup 1 --runs 3`. Verify that every
run creates two new projects, prepares the required uploads and tools, submits A
before B by 1–2 seconds, and exits non-zero if three valid measured runs cannot be
obtained.

### Tests for User Story 1

- [X] T012 [P] [US1] Test login, project creation, upload, tool, and process request construction and response-version propagation in `evaluation/tests/test_run_scenario.py`
- [X] T013 [P] [US1] Test fresh-project enforcement, A/B workload definitions, 1–2 second dispatch ordering, warm-up exclusion, and HTTP 409 invalidation in `evaluation/tests/test_run_scenario.py`
- [X] T014 [P] [US1] Test missing-file, non-premium, certificate, timeout, and secret-redaction failures in `evaluation/tests/test_run_scenario.py`

### Implementation for User Story 1

- [X] T015 [US1] Implement login and premium verification using `POST /users/{email}/login`, requiring `user.type == "premium"` before the 177-second upload in `evaluation/run_scenario.py`
- [X] T016 [US1] Implement fresh project creation with unique names and capture each returned project ID and initial integer version in `evaluation/run_scenario.py`
- [X] T017 [US1] Implement versioned multipart uploads for A's `speech_mandela_177s_1080p.webm` and B's two `sample_10s_720p.mp4` plus one `sample_6s.mov` using the `video` field and `X-Project-Version` in `evaluation/run_scenario.py`
- [X] T018 [US1] Implement versioned tool setup with A `{"procedure":"subtitles","params":{}}` and B `{"procedure":"brightness","params":{"brightness":1.1}}` in `evaluation/run_scenario.py`
- [X] T019 [US1] Implement versioned process submission, recording A and B submission timestamps and enforcing A-first dispatch with a configurable 1–2 second delay in `evaluation/run_scenario.py`
- [X] T020 [US1] Implement one uncounted warm-up followed by the requested measured runs, ensuring each run creates new projects and never reuses stale state in `evaluation/run_scenario.py`
- [X] T021 [US1] Implement run-level failure states, clear prerequisite/request/project/observation messages, non-zero exit status, and invalidation on HTTP 409 in `evaluation/run_scenario.py`

**Checkpoint**: User Story 1 is independently runnable and produces valid/invalid
run records without changing application code.

---

## Phase 4: User Story 2 - Inspect Per-Run Evidence (Priority: P1)

**Goal**: Capture raw logs, queue confirmations, worker resources, completion
timestamps, and the derived metrics for each run.

**Independent Test**: Complete one measured run and inspect its evidence directory.
Verify that raw log lines identify A and B by pipeline, queue/resource samples have
timestamps, result polling reaches the expected counts, and the per-run summary
contains all eight requested metrics.

### Tests for User Story 2

- [X] T022 [P] [US2] Test UTC Docker log parsing and selection of the first A subtitles line and first B brightness line in `evaluation/tests/test_run_scenario.py`
- [X] T023 [P] [US2] Test B wait calculation as `first brightness log timestamp - B submission timestamp`, including missing-log failure and queue-only confirmation in `evaluation/tests/test_run_scenario.py`
- [X] T024 [P] [US2] Test result polling, expected result counts A=1 and B=3, makespan, queue maxima, CPU peak, and memory peak derivations in `evaluation/tests/test_run_scenario.py`

### Implementation for User Story 2

- [X] T025 [US2] Implement result polling through `GET /projects/{user}/{project}/process/url`, accepting completion only at expected result counts A=1 and B=3 in `evaluation/run_scenario.py`
- [X] T026 [US2] Implement concurrent or interleaved one-second queue and Docker resource sampling while either project is active, retaining raw samples and malformed-sample errors in `evaluation/run_scenario.py`
- [X] T027 [US2] Implement Docker log collection from `picturas-video_tool-1` with UTC `--timestamps`, matching A `preview=False tools=['subtitles']` and B `preview=False tools=['brightness']` in `evaluation/run_scenario.py`
- [X] T028 [US2] Implement per-run timing derivation for A duration, B duration, B log-based wait, and makespan, preserving the raw submission and log timestamps in `evaluation/run_scenario.py`
- [X] T029 [US2] Implement per-run summary output for A duration, B duration, B wait, makespan, max ready, max unacked, peak CPU, and peak memory in `evaluation/run_scenario.py`
- [X] T030 [US2] Implement raw evidence files for HTTP metadata, project version transitions, Docker log matches, queue samples, resource samples, and run status under the configured evaluation output directory in `evaluation/run_scenario.py`

**Checkpoint**: User Story 2 is independently inspectable from one run's raw
evidence and summary, including an explicit log-derived answer for B's wait.

---

## Phase 5: User Story 3 - Compare Repeated Measurements (Priority: P2)

**Goal**: Produce per-run rows and aggregate mean, minimum, and maximum across
valid measured runs only.

**Independent Test**: Supply at least three valid measured-run summaries to the
summarizer and verify that it excludes warm-up/invalid runs and prints mean,
minimum, and maximum for all eight metrics.

### Tests for User Story 3

- [ ] T031 [P] [US3] Test aggregate filtering, required valid-run count, and warm-up exclusion in `evaluation/tests/test_summarize.py`
- [ ] T032 [P] [US3] Test mean/minimum/maximum calculations and stable table output for all eight metrics in `evaluation/tests/test_summarize.py`

### Implementation for User Story 3

- [ ] T033 [US3] Implement independent loading and validation of per-run summaries in `evaluation/summarize.py`, rejecting incomplete or invalid records
- [ ] T034 [US3] Implement aggregate mean, minimum, and maximum over valid measured runs for A duration, B duration, B wait, makespan, max ready, max unacked, peak CPU, and peak memory in `evaluation/summarize.py`
- [ ] T035 [US3] Implement per-run and aggregate terminal tables, including valid-run count and the clear conclusion whether B waited and by how many seconds, in `evaluation/summarize.py`
- [ ] T036 [US3] Integrate `run_scenario.py` with `summarize.py` so warm-up is excluded, exactly the requested valid-run count is required, and insufficient evidence exits non-zero in `evaluation/run_scenario.py`

**Checkpoint**: User Story 3 independently summarizes existing evidence and
supports baseline-versus-refactored comparison without rerunning collection.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Complete reproducibility, documentation, and end-to-end validation.

- [ ] T037 [P] Document prerequisites, premium requirement, environment variables, self-signed certificate behavior, configurable RabbitMQ/container settings, excluded files, and the warm-up plus three-run command in `evaluation/README.md`
- [ ] T038 [P] Document the exact API requests, log matching rule, UTC timestamp arithmetic, queue confirmation role, raw-output layout, and aggregate mean/min/max semantics in `evaluation/README.md`
- [ ] T039 [P] Add a local evidence-output policy and verify no generated evidence or credentials are committed in `evaluation/README.md`
- [ ] T040 Run the offline tests in `evaluation/tests/test_run_scenario.py` and `evaluation/tests/test_summarize.py`, then record the commands and results in the implementation handoff
- [ ] T041 Run the documented warm-up plus three-run smoke scenario from `evaluation/README.md` against the baseline checkout and verify the printed per-run and aggregate tables
- [ ] T042 Repeat T041 against the refactored checkout with identical workload, run parameters, sampling interval, and environment fields, then compare the evidence directories

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies; can start immediately.
- **Foundational (Phase 2)**: Depends on Setup; blocks all user stories.
- **User Story 1 (Phase 3)**: Depends on Foundational; provides the runnable
  scenario and is the MVP.
- **User Story 2 (Phase 4)**: Depends on Foundational and the dispatch flow from
  User Story 1; adds evidence collection and per-run derivation.
- **User Story 3 (Phase 5)**: Depends on the per-run summary shape from User Story
  2; adds independent aggregate analysis.
- **Polish (Phase 6)**: Depends on all required user stories.

### User Story Dependencies

- **US1 (P1)**: Foundational only.
- **US2 (P1)**: Foundational plus US1's request orchestration; its parser and
  derivation tests can begin once the shared models exist.
- **US3 (P2)**: US2 per-run summary output; summarizer unit tests can begin from
  the data-model contract.

### Parallel Opportunities

- T002–T004 can run in parallel after T001.
- T008–T010 can run in parallel after T006.
- T012–T014 can run in parallel after T006.
- T022–T024 can run in parallel after T006.
- T031–T032 can run in parallel after the data-model contract is available.
- T037–T039 can run in parallel after the output schema is stable.
- US1 request tests and US2 parser tests can be developed in parallel; the complete
  US2 smoke path still depends on US1 orchestration.

## Parallel Example: User Story 1

```text
Task T012: Request-construction and version-propagation tests
Task T013: Fresh-project, ordering, warm-up, and 409 tests
Task T014: Prerequisite, timeout, certificate, and redaction tests
```

## Parallel Example: User Story 2

```text
Task T022: UTC Docker log parsing tests
Task T023: B wait and queue-confirmation tests
Task T024: Completion and metric-derivation tests
```

## Parallel Example: User Story 3

```text
Task T031: Aggregate filtering and valid-run-count tests
Task T032: Mean/min/max and table-output tests
```

## Implementation Strategy

1. **MVP**: Complete Setup, Foundational, and User Story 1 so the evaluator can
   run the fixed workload reproducibly and fail safely.
2. **Evidence completeness**: Add User Story 2, making Docker logs authoritative
   for B's wait and RabbitMQ queue depth confirmatory only.
3. **Comparison output**: Add User Story 3 for reusable aggregate analysis.
4. **Release readiness**: Complete documentation, offline tests, baseline smoke
   evidence, and refactored-system repeatability checks.
