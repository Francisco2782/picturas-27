# Video capacity and elasticity evaluation

This evaluation-only harness measures contention between subtitle job A and
brightness workload B. It leaves application and deployment code unchanged.

## Prerequisites

- The PictuRAS Docker Compose stack is running, including the API, `video_queue`,
  RabbitMQ management, and the `video_tool` worker.
- Docker CLI access is available to list Compose containers and read worker logs
  and resource statistics. The account must have access to the Docker daemon.
- A premium account is available: the 177-second upload exceeds the free limit.
- The three required samples exist at the paths below. The harness rejects
  `corrupted.mp4` and `too_long_90s.mp4`; neither is part of this workload.
- Python 3, `requests`, and a locally trusted/accepted self-signed certificate
  setup. By default the runner allows the local self-signed certificate; use
  `--verify-tls` only when the certificate is trusted.

Required samples:

- `samples/video/speech_mandela_177s_1080p.webm`
- `samples/video/sample_10s_720p.mp4`
- `samples/video/sample_6s.mov`

Install dependencies and provide credentials through the environment:

```sh
pip install requests
export PICTURAS_EMAIL='premium-account@example.com'
export PICTURAS_PASSWORD='your-picturas-password'
export RABBITMQ_MANAGEMENT_PASSWORD='your-rabbitmq-password'
```

The runner also reads `RABBITMQ_MANAGEMENT_USER` (default `user`),
`COMPOSE_PROJECT_NAME` (default `picturas`) and `VIDEO_WORKER_SERVICE` (default
`video_tool`). Worker discovery uses the Docker Compose project and service labels;
container names and IDs are discovered at runtime. The API defaults to
`https://localhost:8080/api-gateway`; RabbitMQ management defaults to
`http://localhost:15672/api/queues/%2F/video_queue`.

For the fixed-replica capacity scenario, keep the controller inactive. Run one
replica for the baseline and two for the final configuration. The harness
observes the scale set by Compose or the controller:

```sh
docker compose up -d --scale video_tool=1  # baseline
docker compose up -d --scale video_tool=2  # final configuration
```

Set `COMPOSE_PROJECT_NAME` if the stack uses a Compose project name other than
`picturas`. Override `VIDEO_WORKER_SERVICE` only if the Compose service is named
differently. The runner requires at least one running worker and rejects samples
with missing or malformed resource data. Fixed-replica mode also rejects
changes in replica count.

## Run the scenario

```sh
python3 evaluation/run_scenario.py --runs 3 --warmup 1 --expected-workers 2 --output-dir evaluation/evidence/final-performance
```

Each run creates fresh projects. A uploads the 177-second speech video and uses
`subtitles`; B uploads two copies of the 10-second MP4 and one 6-second MOV and
uses `brightness`. A is submitted first; B follows after 1.5 seconds. The
runner records result completion, UTC Docker log timestamps from every replica,
queue samples, and worker CPU/memory samples. Worker containers are discovered by
the `com.docker.compose.project` and `com.docker.compose.service` labels at each
sampling interval. Each sample retains container ID/name and individual CPU and
memory values; aggregate CPU is the sum of worker CPU percentages and aggregate
memory is the sum of worker memory bytes at that timestamp. The existing
`peak_cpu_percent` and `peak_memory_bytes` metrics are the maximum of these group
sums. Per-worker peaks are retained in each `summary.json` and printed separately
by the summarizer. B's wait uses the earliest matching brightness log timestamp
found across all observed replicas minus B's submission timestamp. Queue depth is
corroborating evidence and the worker log is the processing-start measurement.
In fixed-replica mode, the run is invalid if the replica count or identity
changes, a replica cannot be observed, or a worker restarts or is OOM-killed.
The runner rejects missing queue or worker samples and gaps exceeding the
sampling interval plus five seconds for Docker stats.
It polls A and B in each round and validates exact counts and distinct source
and result IDs. Older evidence collected by polling A to completion before B
remains comparable for log-derived wait. Remeasure with the same runner before
using those older completion observations to quantify duration changes.

The evidence tree is local:

```text
evaluation/evidence/<run-id>/
├── run.json       # workload, status, timestamps, and matching worker logs
├── samples.csv    # timestamped RabbitMQ and per-replica Docker samples
└── summary.json   # status, eight group metrics and per-worker peaks (or failure)
```

The summarizer excludes warm-up, invalid, and incomplete runs. It prints each
valid measured run and mean/min/max for `a_duration_seconds`,
`b_duration_seconds`, `b_wait_seconds`, `makespan_seconds`, `max_ready`,
`max_unacked`, `peak_cpu_percent`, and `peak_memory_bytes`. The command exits
non-zero if it cannot obtain the requested number of valid measured runs. To
summarize existing evidence independently, use
`python3 evaluation/summarize.py evaluation/evidence --runs 3`.

No evidence files, credentials, JWTs, or authorization headers are committed.
Keep generated evidence under `evaluation/evidence/`; it is ignored by Git.

For the Phase 2 delivery archive, see the [reproduction guide](phase2-reproduction.md).

## Video worker elasticity

Use a dedicated validation stack with empty video and project queues, the same
three inputs, a warmed Whisper cache, a premium account and `ffprobe` on the
host. Start with a single `video_tool` and run the optional controller from the
[scaling instructions](../README.md#automatic-video-worker-scaling-optional).
Keep the controller output with the run records. In a separate terminal, export
the credentials above and run:

```sh
python3 evaluation/run_scenario.py --elastic --expected-workers 1 \
  --runs 3 --warmup 1 --process-timeout 240 \
  --output-dir evaluation/evidence/video-elasticity/dynamic
```

Use the same 1.5-second dispatch gap, workload, account and stack for fixed
controls. Stop the controller with `Ctrl+C` after it returns to one replica.
With the queue idle, set the desired fixed count and run the same command
without `--elastic`, using `--expected-workers 1` or `--expected-workers 2` and a
different output directory for each. Keep the archived official QS-01 results
as historical references. The supplementary controls on 27 November used
`--runs 1 --warmup 0` for each fixed count, after the elastic series.

Elastic mode requires B's first brightness job to start on a worker that starts
after B is submitted, while A is still pending. B wait is measured from
submission to first processing start, including broker observation and worker
startup. Each run requires four distinct video jobs, no worker crash or OOM,
clean exits of the added replicas, the original worker still running and an
empty queue with one consumer. After scale-in it downloads all four results,
checks unique IDs, codecs and durations, and records SHA-256 digests and Docker
lifecycle events. The optional controller's default maximum remains three.

## Infrastructure recovery and status polling

Use the dedicated `picturas-validation` Compose stack at `https://localhost:8080` with two idle video workers, real MongoDB and object storage, an initialized Whisper cache and the updated `video_tool` and `projects` images. The host needs Docker CLI access, Python with `requests`, and `ffprobe`. Run these sequentially. The recovery probe restarts one validation worker or the validation broker during a live test job. It checks redelivery of the same message, one downloadable output with video and audio, restored consumers and no new staging artifacts.

```sh
python3 evaluation/run_video_recovery.py --fault worker --output evaluation/evidence/qs03-worker.json
python3 evaluation/run_video_recovery.py --fault broker --output evaluation/evidence/qs03-broker.json
python3 evaluation/measure_status_polling.py --output evaluation/evidence/polling.json
```

The polling test needs the exact 10 s input from the official usability baseline in the D-01 archive. It compares one active status observer at 1 Hz against zero periodic requests in a matched four-second window, with identical probes at the window boundaries and after it. Response size is the decoded HTTP body. Timing is measured from the local client. The test measures marginal HTTP cost for this observer and workload.

## Project concurrency regressions

Run from the repository root against the updated `projects` image on the dedicated validation stack. The test creates synthetic projects in the `picturas_concurrency_test` MongoDB database and removes those documents after the checks.

```sh
docker exec -i --workdir /app/tests picturas-validation-projects-1 node \
  < projects/tests/project-concurrency.integration.js
```

The checks cover progress from two videos delivered out of order and edits that were read before a worker completed or failed the run. They also replay a completion after its result was recorded and race two copies of the same reply. The replay and race use real MongoDB writes and simulated uploads, and check that the surviving record references the retained upload. [F2 and F3 verification](../docs/sessoes/2026-11-23-f2-f3.md) · [Redelivery regression](../docs/sessoes/2026-11-24-reentrega-resultados.md)
