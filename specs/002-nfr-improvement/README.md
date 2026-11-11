# Phase 2: Improve two non-functional requirements

This proposal focuses on video processing capacity and the ability to use the
application while processing runs.

**Performance efficiency — capacity** (ISO/IEC 25010:2011) matters because the
baseline has one video worker. A CPU-heavy subtitle job occupies it while
ordinary video jobs wait. The evaluation harness currently records a mean B wait
of 65.7 seconds over three valid local runs. The planned refactoring separates
subtitle work or safely increases capacity, with a target mean wait of at most
15 seconds and a minimum acceptable mean of 30 seconds.

**Usability — operability** matters because the dashboard shows a full-screen
processing overlay and keeps progress in component state. Users cannot use the
rest of the app during the overlay, and a reload loses the visible state. The
planned refactoring makes progress non-blocking and recoverable across
navigation/reload. Success is measured by four repeatable interactions, with a
target of all four available and a minimum of three plus recoverable status.

Both changes are refactorings. Existing media behavior, pipeline order, progress
meaning, and result handling must remain intact. Baselines are captured before
code changes; identical conditions and regression tests are used afterward.
See [spec.md](./spec.md), [plan.md](./plan.md), and [tasks.md](./tasks.md) for
diagnoses, decisions, measurement procedures and acceptance criteria.
