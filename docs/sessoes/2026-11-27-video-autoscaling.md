# Video worker elasticity

The follow-up request limits the implementation to changing the number of video
workers. The controller uses the existing Compose service and RabbitMQ queue.
The official fixed-replica QS-01 evidence provides the historical comparison.

Before implementation, `evaluation/summarize.py --runs 3` was run on the
official baseline and final capacity archives. Their mean B waits were 61.727 s
with one fixed worker and 0.123 s with two fixed workers. `docker compose ps
video_tool` and `rabbitmqctl list_queues` showed two running video workers, two
consumers and an empty queue. Docker reported 20 CPUs and 33,357,836,288 bytes
of RAM.

The controller uses the management API and Compose from the host. This keeps
Docker access out of application containers. It treats ready and unacknowledged
deliveries as busy for scale-in. The worker handles a drain request without
calling Pika inside the signal handler and closes the connection after finishing
the current callback. Resource allocation stays in the existing Compose setup.

`docker compose build video_tool` built the drain-capable image. The first
warm-up reached three workers and returned to one. Its evidence was kept as
invalid because the harness expected a legacy `id` field in Docker events.
Docker 29.9.3 emitted `Actor.ID`; the harness was corrected to read that field.
The `projects` Node suite passed 31 tests and the video worker suite passed 77.
The evaluation suite passed 15 tests, including the new controller regression.

## Measurement protocol

Use the existing `evaluation/run_scenario.py` workload: A captions the
176.621-second speech clip. B applies brightness to two copies of a ten-second
MP4 and one six-second MOV, with a 1.5-second submission gap. The clock starts
before B's process request and stops at its first brightness worker log.
The Docker start event must be between these timestamps so the measured wait
includes start-up. The controller uses min 1, max 3, a one-second poll interval,
a five-second cooldown and a ten-second idle threshold. The test starts with
the original worker and requires the same worker running at the end, with zero
messages ready or unacknowledged. A and B must yield one and three distinct
results respectively. The test downloads all four after scale-in and checks
their duration, H.264 video and AAC audio with `ffprobe`.

## Measurements

The accepted warm-up measured 3.356 s and was excluded from the mean.

| Run | B wait (s) | B submission to Docker start (s) | Docker start to B processing (s) | Return to one after both completed (s) |
| --- | ---: | ---: | ---: | ---: |
| `def3b12967ac423b9383fe7ef1bb642f` | 8.031 | 7.890 | 0.141 | 36.872 |
| `31cec259da084b009244d4e724631d50` | 7.970 | 7.857 | 0.113 | 32.802 |
| `7d823659bd364b5f9a9302f9e0fd1f40` | 7.704 | 7.565 | 0.139 | 32.857 |
| Mean | **7.902** | 7.771 | 0.131 | 34.177 |

All three measured runs reached three replicas, processed four distinct jobs
with no redeliveries and returned to one consumer. The two added replicas
received `SIGUSR1` and exited with code zero in each run. A downloaded as a
176.600-second MP4. B's three MP4s were 6, 10 and 10 seconds. All had H.264
video and AAC audio. The mean B wait met the existing QS-01 reference target of
15 s and its 30 s acceptable bound. The historical QS-01 means remain 61.727 s
with one fixed replica and 0.123 s with two ready replicas.

The same stack, worker image and account were then used for one run each with
the controller stopped. B waited **69.917 s** with one fixed replica (run
`f9ef1006142b47cea49b42f7eac4058f`) and **0.099 s** with two fixed replicas
(run `2197612d445e44c5b3d458c1da56cb0b`). These are supplementary controls
with one observation each. The original QS-01 series have three observations
per configuration.

An additional run with `VIDEO_WORKERS_MAX=2` used the final harness. It started
one added replica, returned to one worker, and verified HTTP 200 on all four
downloads. B waited **6.474 s**. This single run is outside the default-max
aggregate above.

## Regression and closeout

- Ran `node --test projects/tests/*.test.js` (31 passed),
  `.venv/bin/python -m pytest -p no:cacheprovider -q tests` from `Tools/video` (77 passed), and
  `python3 -m pytest -p no:cacheprovider evaluation/tests -q` (15 passed).
- Ran `check-drain.py` from the evidence directory with autoscaling disabled.
  It sent `SIGUSR1` to the original container after a subtitle job began and
  observed that the worker and job remained running. The same run token then
  completed with one processing start and one HTTP 200 result. The result had
  H.264/AAC and decoded to completion with `ffmpeg -xerror`. The worker exited
  with code zero after its completion log and was restarted for the regressions.
- Ran the existing `check_integrated.py` from the evidence directory on the same
  stack. Image, video, mixed processing, invalid trim, frame extraction and
  status permissions matched their expected states and HTTP responses. The
  available files downloaded successfully and the exports passed ZIP checks.
- `docker compose config -q` and `git diff --check` passed. The updated report
  compiled via the Typst 0.15.2 Python binding using the repository fonts. The
  compiled text contained the measured A/B results and the new AI-use entry.

The Compose stack was left with one running `video_tool` and an empty
`video_queue`. The controller was stopped after the measurements. The prototype
has evidence for one overlapping A/B workload at a time. Sustained load and
independent reproduction remain outside this validation.

The local archive `evaluation/evidence/video-elasticity-2026-11-27.tar.gz`
contains the experiments, instrument snapshots and environment manifest. The
file manifest and the archive's companion `.sha256` both passed `sha256sum -c`.

## Scope and conformance

- Existing Docker Compose, RabbitMQ, storage and image/video dispatch contracts
  are retained. Elasticity changes the number of video consumers and the way a
  worker exits. CPU and RAM are allocated by the operator.
- The official capacity and usability scenarios remain the two Phase 2 quality
  requirements. This complementary result uses the same B-wait definition,
  workload and reporting units as the archived capacity evidence.
- Valid, warm-up and invalid observations, controller logs and environment
  metadata are kept under `evaluation/evidence/video-elasticity-2026-11-27/`.
  Activation and reproduction commands are in the README and evaluation guide.
- Codex assisted with implementation, measurement and documentation. The
  automated checks and their limitations are recorded here and in the Typst
  report. Independent reproduction and human review are pending. The available
  V1 guidelines leave the final delivery structure to a subsequent version.
