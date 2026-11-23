# AGENTS.md

Guidance for AI coding agents (and humans) working on this repository. `README.md` is the
user-facing documentation; this file is the short version an agent needs before changing code.

## Phase 2 status and next steps

- The official baseline is recorded. Compose defaults to one video worker. The capacity scenario uses two.
- P-02 preserved two distinct, downloadable results in the local race regression and in the two-replica check with MongoDB and real storage. [P-02 evidence](docs/sessoes/2026-11-22-p02.md)
- U-04 passed the Chromium A/B and F5 acceptance checks. R-01 through R-04 passed with 128 automated tests and the production frontend build. M-01 through M-04 met both targets: 0.113 s mean B wait, 12/12 usability actions and 3/3 recoveries for navigation, reload and reconnect. [Validation log](docs/sessoes/2026-11-22-fecho-fase-2.md) · [B wait definition and comparison](docs/sessoes/2026-11-23-espera-b.md)
- Still open: independent reproduction from the evidence package, team review of the report and AI record, and confirmation of submission or deadline extension. Recovery from a mid-job infrastructure interruption (QS-03) needs its own test. The campaigns did not isolate polling costs.
- The exercise templates were re-checked against the baseline sources on 23/11/2026. Three broken evidence citations were corrected (`frames.py` → `frame_extraction.py`, `video.py:169-176` → `video.py:170`, `processBatch.js:88-142` → `projects/routes/projects.js:1564-1671`), `EV-09` was repointed at the actual `rejectUnauthorized` sites, and the non-existent `process_completed` event was replaced by `process-update`. `docs/exercicios/check_citations.py` now checks every citation mechanically and runs in CI. [Review log](docs/sessoes/2026-11-23-revisao-exercicios.md)
- Next, in order: (1) inventory and package the evidence for D-01, then have another team member reproduce both measurements, (2) complete D-02 using the verified evidence, (3) confirm submission status and the applicable deadline with the team. See the [handoff](docs/sessoes/2026-11-22-fecho-fase-2.md#session-handoff).
- Resume D-01 from the repository root with `PYTHONDONTWRITEBYTECODE=1 python3 evaluation/summarize.py evaluation/evidence/phase2-final-2026-11-22/performance-retry --runs 3`. The evidence is local and Git-ignored.

## What the app is

PictuRAS is a web editor for images and videos, built as Docker Compose microservices. Users
create **projects**, add media (images and videos), build an ordered **pipeline** of effects,
and apply it to every media item of the project in one batch. The pipeline belongs to the project, not to each item.

Profiles: **anonymous** (images only, limited), **free** (`FREE_DAILY_OP` = 5 operations per day)
and **premium** (unlimited). `subscriptions` means paid plans/billing, not event subscriptions.

## Architecture

All traffic enters through nginx at `https://localhost:8080`:

| Path            | Target                                                       |
| --------------- | ------------------------------------------------------------ |
| `/`             | `frontend/`: Next.js 15 + React 19 + TypeScript (bun)        |
| `/api-gateway/` | `apiGateway/`: Express; checks the JWT and forwards requests |
| `/socket.io`    | `wsGateway/`: Socket.IO; pushes `ws_queue` events to the UI  |
| `/s3/`          | SeaweedFS (S3-compatible object storage)                     |

Behind the gateway:

- `users/`: accounts, login (JWT), profiles and the daily operations quota (MongoDB).
- `projects/`: orchestrator. Owns projects, media, pipelines and processing (MongoDB).
- `subscriptions/`: plans and mock payments (MongoDB).
- `imageStorageService/`: S3 façade with the stages `src`, `out`, `preview`, `preview_cache`.
- `Tools/<tool>/`: one Python microservice per effect, consuming `<tool>_queue` on the
  `picturas` direct exchange (RabbitMQ) and reading/writing the shared `image_data` volume.
  - Image tools (PIL): `binarization`, `border`, `brightness`, `contrast`, `cut`, `resize`,
    `rotate`, `saturation`; `watermark` runs from a pre-built public image.
  - AI tools: `bg_remove_ai`, `cut_ai`, `expand_ai` (uses `generative-mock/`), `obj_ai`,
    `people_ai`, `text_ai`, `upgrade_ai`.
  - `Tools/utils/`: shared RabbitMQ, image I/O and message helpers.
  - `Tools/video/` (`video_tool`): one worker service, with one replica by default.
- `rabbitMQ/definitions.json`: queues, exchange and bindings.
- `docker-compose.yaml`: the single source of truth for services and configuration.

### Processing flow

- **Images**: `projects` sends one message per (image, tool) step and advances the chain when
  the tool replies on `project_queue`. Progress goes to the browser through `ws_queue`.
- **Videos**: `projects` sends **one** message per video carrying the whole pipeline to
  `video_queue`. The worker probes with ffprobe and shares one decode/encode pass across
  contiguous frame effects (`Tools/video/effects.py`). Ordinary video output is MP4/H.264 + AAC
  with audio retained. The worker reports typed progress to `project_queue`.
  For an active run, `projects` persists accepted updates and publishes them to
  `ws_queue`. The worker acks at the end and removes partial output on failure. Preview mode
  renders only the first `VIDEO_PREVIEW_SECONDS` (3 s).

### Media types

- Images are uploaded to `POST /:user/:project/img`, videos to `POST /:user/:project/video`;
  each endpoint rejects the other kind. Videos are stored with `media_type: "video"`.
- Video validation (container, codec, duration, size, resolution) and the orchestrator's video
  logic live in `projects/utils/video.js`. Limits are env vars of `projects`
  (`VIDEO_FREE_*`, `VIDEO_PREMIUM_*`): free 60 s / 100 MB, premium 600 s / 1 GB.
- `trim` (`start`/`end` in seconds) and `speed` (`factor` 0.25–5) are video-only and apply to
  one video (`params.imgId`); every other effect applies to all media. Images skip video-only
  tools. Each effect on a video counts as one operation.
- `subtitles` is video-only and project-wide (no `imgId`): Faster-Whisper CPU/int8
  detects the spoken language and burns captions into the MP4. No audio/speech is a no-op.
  It runs as an ordered stage inside the existing video worker; contiguous ordinary
  effects still share one decode/encode pass. Models persist in `whisper_models`.
- `extract_frames` is video-only and project-wide, terminal and unique. It reuses the
  video worker: count (1–100) or interval, PNG/JPEG, max100 images per video. Full output
  is a frame manifest; preview is a contact sheet across the edited timeline. The
  orchestrator saves each frame as a separate image Result with the source `img_id`
  and unique result ID/name. Register all batch Process records before dispatch.
- In projects with videos the frontend hides image-only tools (AI, watermark) and PDF export.

## Running and testing

```bash
docker compose up -d --build                 # first build: 15-30 min, ~15 GB disk, 8+ GB RAM
docker compose up -d --build <service>       # rebuild one service after a change
docker compose restart nginx                 # after rebuilding the frontend (avoids 502)
docker compose logs -f <service>
docker compose down [-v]                     # stop (-v also wipes all data)
```

Replacing an older (e.g. Phase 1) checkout: it shares the Compose project name `picturas` and
its volumes, whose S3 layout (one bucket per user) is incompatible. Run
`docker compose down -v --remove-orphans` once before the first `up`.

Video worker tests run on the host (needs ffmpeg/ffprobe on the PATH, no Docker):

```bash
cd Tools/video && python3 -m venv .venv && .venv/bin/pip install -r requirements-dev.txt
.venv/bin/python -m pytest -q tests
```

- Open `https://localhost:8080` (https, port 8080) and accept the self-signed certificate.
- `users`, `subscriptions` and `apiGateway` bind-mount their source and reload with nodemon.
  The frontend is a production build and Python tools have no bind mount: rebuild them.
- RabbitMQ management: `http://localhost:15672` (`user` / `password`).
- Sample videos for manual tests: `samples/video/` (see its README).

## Conventions

- Code, comments, identifiers and user-facing messages in English.
- Extend the existing design instead of rewriting it; change base behaviour only when needed.
- Small commits with descriptive subjects (under 72 characters).
- Keep each file's existing line endings: some files are stored with CRLF. Do not reformat
  unrelated code.
- Never commit secrets, `.env`, `node_modules/`, generated media or `backups/`.
- To add a tool: create `Tools/<tool>/` from a simple tool (e.g. `border`), register its queue in
  `rabbitMQ/definitions.json`, add the service to `docker-compose.yaml`
  (`depends_on: rabbitmq: service_healthy`, `image_data` volume), then expose it in `projects`
  and in the frontend toolbar.

## Documenting changes

- For every task that changes the repository, keep one session log at
  `docs/sessoes/YYYY-MM-DD-<task>.md`. Update it as work progresses.
- Record decisions and their rationale, the commands actually run and their
  results, and anything still unverified or blocked. For pending checks, include
  the commands or steps needed to reproduce them. Record only observed results.
- Close the log with a short summary of what changed, the evidence, what remains
  unverified, and the next steps. Update any existing documentation affected by
  the change and keep the Phase 2 status above current when relevant.

## Reviews and checks

A review task is finished when every checkable claim has been confronted with its
source and the answer is written down. Write the report; do not keep digging.
Before opening another line of inquiry, ask whether it can change the answer: if it
cannot, record what you already know and move on.

Evidence citations in `docs/exercicios/` point at a repository file, sometimes with a
line range. Verify them mechanically:

```bash
python3 docs/exercicios/check_citations.py                     # all exercise documents
python3 -m pytest -p no:cacheprovider docs/exercicios/tests/ -q
```

Cite `file:lines` that resolve at the commit you name, and say which commit that is
(`git show <commit>:<file>`). The evidence register describes the baseline, so cite the
baseline commit's line numbers — they differ from HEAD where the file changed. A
citation that points at a file or range that does not exist is a broken claim, not a
shorthand.

## Known pitfalls

- `JWT_SECRET_KEY` must be the same in `users`, `api_gateway` and `ws_gateway`.
- Keep `NEXT_PUBLIC_API_BASE_URL` relative (`/api-gateway/`) and do not remap port 8080.
- Internal service-to-service TLS certificates are expired and not validated
  (`rejectUnauthorized: false`); several secrets are committed. Known issues, not patterns.
- RabbitMQ consumers must survive broker restarts.
- The image tools auto-acknowledge messages and swap `messageId`/`correlationId` in their error
  replies, so their errors do not reach the user.
- The users service answers errors with a non-standard 701 status (including "daily limit
  reached"); `projects` maps that case to 403 before replying.
- Image/video handling is branched in the orchestrator, PIL effects are duplicated in
  `Tools/video/effects.py`.
