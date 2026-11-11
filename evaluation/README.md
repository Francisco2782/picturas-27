# Video baseline evaluation

This evaluation-only harness measures contention between subtitle job A and
brightness workload B. It leaves application and deployment code unchanged.

## Prerequisites

- The PictuRAS Docker Compose stack is running, including the API, `video_queue`,
  RabbitMQ management, and the `video_tool` worker.
- Docker CLI access is available to read worker logs and resource statistics.
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

The runner also reads `RABBITMQ_MANAGEMENT_USER` (default `user`) and
`VIDEO_WORKER_CONTAINER` (default `picturas-video_tool-1`). The API defaults to
`https://localhost:8080/api-gateway`; RabbitMQ management defaults to
`http://localhost:15672/api/queues/%2F/video_queue`.

## Run the scenario

```sh
python3 evaluation/run_scenario.py --runs 3 --warmup 1
```

Each run creates fresh projects. A uploads the 177-second speech video and uses
`subtitles`; B uploads two copies of the 10-second MP4 and one 6-second MOV and
uses `brightness`. A is submitted first; B follows after 1.5 seconds. The
runner records result completion, UTC Docker log timestamps, queue samples, and
worker CPU/memory samples. B's wait uses the first matching brightness log
timestamp minus B's submission timestamp. Queue depth is corroborating evidence
and the worker log is the processing-start measurement.

The evidence tree is local:

```text
evaluation/evidence/<run-id>/
├── run.json       # workload, status, timestamps, and matching worker logs
├── samples.csv    # timestamped RabbitMQ and Docker samples
└── summary.json   # status and the eight per-run metrics (or failure reason)
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
