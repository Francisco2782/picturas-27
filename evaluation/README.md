# Video baseline evaluation

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

For a measured baseline, run one replica; for the final capacity configuration,
run two replicas. The harness does not change Compose scaling:

```sh
docker compose up -d --scale video_tool=1  # baseline
docker compose up -d --scale video_tool=2  # final configuration
```

Set `COMPOSE_PROJECT_NAME` if the stack uses a Compose project name other than
`picturas`. Override `VIDEO_WORKER_SERVICE` only if the Compose service is named
differently. The runner requires at least one running worker and fails a sample if
the number of replicas changes during the run or any replica has missing or
malformed resource data.

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
If the worker replica count changes, or a replica cannot be observed, the run is
invalid. The runner also checks worker identity, start time, restart count and
OOM status before and after the run. It rejects missing queue or worker samples
and gaps exceeding the sampling interval plus five seconds for Docker stats.
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

## Infrastructure recovery and status polling

Use the dedicated `picturas-validation` Compose stack at `https://localhost:8080` with two idle video workers, real MongoDB and object storage, an initialized Whisper cache and the updated `video_tool` and `projects` images. The host needs Docker CLI access, Python with `requests`, and `ffprobe`. Run these sequentially. The recovery probe restarts one validation worker or the validation broker during a live test job. It checks redelivery of the same message, one downloadable output with video and audio, restored consumers and no new staging artifacts.

```sh
python3 evaluation/run_video_recovery.py --fault worker --output evaluation/evidence/qs03-worker.json
python3 evaluation/run_video_recovery.py --fault broker --output evaluation/evidence/qs03-broker.json
python3 evaluation/measure_status_polling.py --output evaluation/evidence/polling.json
```

The polling test needs the exact 10 s input from the official usability baseline in the D-01 archive. It compares one active status observer at 1 Hz against zero periodic requests in a matched four-second window, with identical probes at the window boundaries and after it. Response size is the decoded HTTP body. Timing is measured from the local client. The test measures marginal HTTP cost for this observer and workload.
