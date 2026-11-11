# Video baseline evaluation

This directory contains the evaluation-only scenario runner. It does not modify
the application, Docker Compose, RabbitMQ, or frontend code.

## Prerequisites

Start the PictuRAS stack and ensure the account used by the runner is premium.
The 177-second subtitle video exceeds the free-account duration limit. The
sample files must be present at their default paths:

- `samples/video/speech_mandela_177s_1080p.webm`
- `samples/video/sample_10s_720p.mp4`
- `samples/video/sample_6s.mov`

The runner uses the local self-signed HTTPS certificate without verification by
default. RabbitMQ management is sampled through `localhost:15672`, and Docker
logs/stats are read from `picturas-video_tool-1` by default.

## Warm-up command

The current implementation is intentionally limited to Setup, Foundational,
US1, and US2. Run exactly one uncounted warm-up and stop before the three valid
runs with:

```sh
export PICTURAS_EMAIL='premium-account@example.com'
export PICTURAS_PASSWORD='your-picturas-password'
export RABBITMQ_MANAGEMENT_PASSWORD='password'
python3 evaluation/run_scenario.py --warmup 1 --runs 3 --stop-after-warmup
```

Do not replace the quoted values with credentials committed to a file. The
runner reads passwords only from environment variables and writes local
evidence to `evaluation/evidence/`, which is ignored by Git.

Required variables:

- `PICTURAS_EMAIL`: premium PictuRAS account email.
- `PICTURAS_PASSWORD`: password for that account.
- `RABBITMQ_MANAGEMENT_PASSWORD`: RabbitMQ management password (default user:
  `user`).

Optional variables:

- `PICTURAS_API_BASE` (default: `https://localhost:8080/api-gateway`)
- `RABBITMQ_MANAGEMENT_URL` (default:
  `http://localhost:15672/api/queues/%2F/video_queue`)
- `RABBITMQ_MANAGEMENT_USER` (default: `user`)
- `VIDEO_WORKER_CONTAINER` (default: `picturas-video_tool-1`)

The `--stop-after-warmup` flag is required for this increment. Aggregate
summaries and the valid-run phase belong to User Story 3 and are not implemented
yet.
