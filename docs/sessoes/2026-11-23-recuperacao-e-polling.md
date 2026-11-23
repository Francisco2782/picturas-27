# Phase 2 follow-up — Infrastructure recovery and status polling

## Context and first observations

- QS-03 is a supplementary regression scenario for DA-1 (QS-01). The two-consumer configuration should preserve batch behavior if a consumer or the broker is interrupted. The checks cover redelivery, output availability and staging cleanup. The selected Phase 2 requirements remain QS-01 and QS-02.
- Reviewed the previous closeout, D-01 evidence and the P-03 implementation record. P-03 checked that video workers resumed consuming after a broker restart. Its notes also report a manual restart of `projects`. QS-03 exercises an already-active workload and checks its final result and staging files.
- `docker compose ls`, `docker ps` and `curl -ksS https://localhost:8080/` showed that the validation stack had stopped dependencies. Started its RabbitMQ, three MongoDB containers, frontend and nginx. The first recovery invocation stopped before submitting a job when account creation returned HTTP 500. Restarted the validation `users`, `subscriptions` and WebSocket gateway services after their dependencies became available.
- `python3 evaluation/run_video_recovery.py --fault worker --output evaluation/evidence/phase2-followup-2026-11-23/worker-initial.json` interrupted the worker after it opened its staging directory. The other replica started the same message 0.630 s after the first start. The same run completed with one downloadable MP4 containing video and audio. A caption stage directory and a `.part.mp4` remained on `image_data`, so the check failed.
- `python3 evaluation/run_video_recovery.py --fault broker --output evaluation/evidence/phase2-followup-2026-11-23/broker-initial.json` interrupted RabbitMQ during a second caption job. Both video workers subscribed again, with zero ready and unacknowledged video deliveries. The active job showed one start and no terminal state within 180 s. `rabbitmqctl -q list_queues name messages_ready messages_unacknowledged consumers` also showed zero `project_queue` consumers after the restart.

## Changes and verification setup

- Each video output now has its own staging directory on the shared filesystem. An advisory directory lock serializes attempts for that output. A retry clears abandoned staging data while holding the lock. Frame extraction still publishes its generation outside the staging directory.
- Confirmed video dispatches are persistent. The worker confirms persistent terminal replies before acknowledging the job. The `projects` consumer resubscribes after connection, channel or consumer loss and leaves deliveries unsettled when their channel goes down.
- Added a worker regression for isolated cleanup and an integrated probe for each interruption. The probe uses the dedicated `picturas-validation` stack, two idle workers, real MongoDB and object storage, a 177 s caption workload, and `ffprobe` on the downloaded MP4. A separate instrument alternates the same 10 s caption workload with and without a 1 Hz status observer for a shared four-second window. It records incremental HTTP requests, decoded response body bytes and client-observed request latency.
- Ran the video pytest suite (**77 passed**, existing Pillow warning), `node --test projects/tests/*.test.js frontend/tests/processing-status.test.mjs` (**38 passed**), evaluation pytest (**14 passed**) and `git diff --check`. Built local worker and orchestrator images from the prior validation images with `docker build --network none`. Applied only those images to the dedicated stack with `docker compose … up -d --no-deps --no-build --scale video_tool=2 video_tool projects` and the archived validation, storage and local image overrides.

## Evidence

The earlier Phase 2 measurements retain their frozen configuration. This follow-up uses new runs under `evaluation/evidence/phase2-followup-2026-11-23/`.

| Fault | First retry started after interruption request | Outcome | Newly orphaned staging artifacts |
|---|---:|---|---:|
| Active video worker restarted | 0.042 s | Same run completed, HTTP 200, video and audio | 0 |
| RabbitMQ restarted | 3.513 s | Same run completed, HTTP 200, video and audio | 0 |

Both `worker-fixed.json` and `broker-fixed.json` recorded exactly two starts with the same message ID, two video consumers and one project consumer at the end. Both downloads were 13,082,890 bytes and had the same SHA-256 as the completed download in the original worker interruption attempt. The broker run retained the same `projects` process through both disconnection and reconnection.

Hardened workspace creation against another delivery removing the directory between a failed `mkdir` and the open. Rebuilt and restarted the two validation workers. The first readiness check imported the script without `PYTHONPATH=evaluation` and stopped before submitting jobs. The corrected readiness check passed. Reran the video suite (77 passed) and both interruptions. `worker-recheck.json` and `broker-recheck.json` each passed with zero new artifacts and the same MP4 hash. The first retries started 0.203 s and 2.946 s after the interruption requests, respectively.

Ran `python3 evaluation/measure_status_polling.py --output evaluation/evidence/phase2-followup-2026-11-23/polling.json`. After two warm-ups, four pairs alternated the test order. The polling arm made four incremental requests and received 1,048 bytes of decoded response bodies per window. The control made zero incremental requests. Across 16 periodic requests, median latency was 7.75 ms (6.87–9.88 ms). Mean observed completion was 6.726 s with periodic requests and 6.799 s in the control. Individual paired differences changed sign. The experiment did not establish a completion-time effect or measure isolated database CPU, memory or performance with multiple clients.

Ran a separate API regression with the tracked 10 s MP4 and 6 s MOV, applying `extract_frames` with two PNGs per video. The project completed and produced four distinct downloadable PNG results from two source IDs. The observed result sizes are in `frame-regression.json`.

Updated `AGENTS.md`, the application and evaluation guides, the explanatory document and the Typst draft. Compiled the updated 33-page draft, reviewed the changed pages with Poppler and saved it at `evaluation/evidence/picturas-phase2-relatorio-rascunho.pdf`. The existing D-01 hash still matches and the archived measurements recount to their previous values.

Rechecked the inherited quota issue F8 in `projects/routes/projects.js`. Dispatch charges `adv_ops + vid_ops`. The project stores only `adv_ops` in `pendingAdvancedOps`, and cancellation uses that field for the refund. This is a separate billing-rule change from the recovery and operability follow-up. The source inspection confirms the mismatch for video operations and does not supply a new integration observation for free accounts.

## Handoff

QS-03 passed both fault cases on the updated stack, and one observer's incremental HTTP cost is measured. The previous campaign and D-01 archive remain the frozen reference for the two original targets. Independent reproduction, human review and submission confirmation remain with the team. The validation stack was left available with the corrected worker and orchestrator images.
