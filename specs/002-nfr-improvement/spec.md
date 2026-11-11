# NFR Improvement Specification

**Baseline:** PictuRAS Phase 1 checkout, commit to be recorded in the Phase 2 report.
**Scope:** refactoring only; existing image and video behavior remains unchanged.

## NFR 1 — Video processing performance efficiency: capacity

**ISO/IEC 25010:2011:** Performance efficiency, capacity.

### Diagnosis

`Tools/video/video.py:53-54` configures `prefetch_count=1`; `video.py:169-176`
acknowledges a message after its callback and calls the blocking consumer. The
callback runs `process_video` synchronously (`video.py:150-155`). The Compose
service `video_tool` is a single worker by default (`docker-compose.yaml:255-260`)
and has no configured replica count. `Tools/video/subtitles.py:15-21, 60-63`
loads Faster-Whisper on CPU and transcribes inside that same processing path.
Consequently, a subtitle job occupies the only video worker while queued video
jobs wait.

Stakeholder impact: anonymous and free users face the same serialization for
short permitted videos; premium users can submit longer jobs and experience a
larger queue delay; operators have no independent capacity control for speech
recognition versus ordinary video effects.

### Quantification

- **Scale/unit:** B's queue wait in seconds, defined by the evaluation harness as
  first matching brightness-worker log timestamp minus B submission timestamp.
- **Method:** `evaluation/run_scenario.py --runs 3 --warmup 1`, unchanged samples,
  dispatch gap, host, Docker limits and sampling interval; report mean and range
  of the three valid measured runs.
- **Baseline:** 65.7 s mean (62.6–70.1 s) in the three valid local evidence runs
  currently under `evaluation/evidence/`. Re-capture against the identified
  baseline commit before changing application code.
- **Target:** mean B wait no greater than 15 s.
- **Minimum acceptable:** mean B wait no greater than 30 s, with three valid runs.

The target allows the 1.5-second intentional dispatch offset plus worker startup
and one-second sampling/logging variation, while requiring a substantial
reduction from observed serialization. The target and minimum are project
acceptance thresholds, not ISO-prescribed values.

## NFR 2 — Usability: operability during processing

**ISO/IEC 25010:2011:** Usability, operability.

### Diagnosis

`frontend/app/dashboard/[pid]/page.tsx:89-94` holds processing and progress only
in component state. At `page.tsx:894-904`, `processing` displays a fixed,
full-viewport dark overlay (`absolute ... h-screen w-screen ... z-50`) containing
the progress card. The overlay prevents interaction with the rest of the
application until processing state is cleared; a page reload also discards the
component's in-memory state. This couples the user's ability to work to the
duration of a batch.

Stakeholder impact: anonymous and free users cannot continue ordinary editing
while a batch runs; premium users can be blocked for longer jobs, including
subtitles; operators receive more user-visible friction and avoidable support
requests about progress that disappeared after navigation or refresh.

### Quantification

- **Scale/unit:** percentage of a fixed set of four independent interactions
  that succeed while a project batch is active: open another project, use its
  toolbar, return to the running project, and identify current progress/status.
- **Method:** run the same scripted/manual scenario on the baseline and refactored
  UI, with one 10-second video and one subtitle job; record pass/fail for each
  interaction and whether status survives navigation and page refresh.
- **Baseline:** 0/4 interactions available while the full-screen overlay is
  shown (0%); progress is held in component state, so it is not restored after a
  reload. This is a source-based baseline and must be confirmed in the baseline
  browser run before refactoring.
- **Target:** at least 4/4 interactions available and processing status restored
  after navigation and refresh.
- **Minimum acceptable:** at least 3/4 interactions available and status
  recoverable after navigation, without falsely reporting completion.

The thresholds are project acceptance criteria. The scenario and browser,
viewport, user type, and workload must be held constant between measurements.

## Functional boundary

Preserve pipeline order, project-wide video processing, image behavior, progress
meaning, cancellation semantics where present, result counts, and output bytes or
documented codec behavior. No new user-facing processing capability is in scope.
