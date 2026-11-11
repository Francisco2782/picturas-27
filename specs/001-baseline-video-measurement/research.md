# Research: Video Processing Baseline Measurement

## Decision: Use the API gateway for all scenario control

Protected gateway requests use `Authorization: Bearer <jwt>`.

**Rationale**: The gateway exposes stable public paths under `/users`, `/projects`,
and `/subscriptions`, validates JWTs, forwards `X-Project-Version`, and returns
the project version from mutation responses. The runner must not call internal
Docker service names.

### Exact requests

1. Login: `POST /api-gateway/users/{email}/login`, JSON
   `{"password": "<password>"}`. The response is `{"user": {..., "type": ...},
   "jwt": "..."}`. Send `Authorization: <jwt>` on protected requests.
2. Create project: `POST /api-gateway/projects/{user_id}`, JSON
   `{"name": "<unique run/project name>"}`. The response is `201` and includes
   `_id` and `version`.
3. Upload each video: `POST /api-gateway/projects/{user_id}/{project_id}/video`,
   multipart field `video`, with `X-Project-Version: <current version>`. Success is
   `204`; read the new version from `X-Project-Version`.

   The gateway rejects a second upload with the same filename in one project with
   HTTP 400: `This project already has a video with that name`. Project B therefore
   uploads the second copy of `sample_10s_720p.mp4` with the multipart filename
   `sample_10s_720p_copy2.mp4`. The file contents remain identical; only the
   client-supplied upload name changes. The per-run `summary.json` records the
   uploaded filenames for each project.
4. Add a tool: `POST /api-gateway/projects/{user_id}/{project_id}/tool`, JSON
   `{"procedure": "subtitles", "params": {}}` for A or
   `{"procedure": "brightness", "params": {"brightness": 1.1}}` for B, with the
   current version header. Success is returned by the gateway as `201`, and the
   projects service supplies the new version header.
5. Start processing: `POST /api-gateway/projects/{user_id}/{project_id}/process`,
   JSON `{}`, with the current version header. Success is normally `201` and may
   return a completion object if the same pipeline was already committed; fresh
   projects prevent that shortcut.
6. Observe project: `GET /api-gateway/projects/{user_id}/{project_id}` returns the
   current version and media list. `GET .../process/url` returns committed result
   URLs. Completion is accepted only when the expected result count exists for the
   run, not merely when the process request returns.

The application accepts `brightness` as a numeric factor, while `subtitles` has no
required parameters. These formats are verified in `projects/routes/projects.js`,
`projects/utils/video.js`, `Tools/video/effects.py`, and `Tools/video/video.py`.

## Decision: Verify premium status, then use the supported user update path

The runner must first confirm `user.type == "premium"` after login. If a local
operator owns a suitable test account, no mutation is needed. The repository also
exposes `PUT /api-gateway/users/{user_id}` with `{"type": "premium"}`; it requires
the JWT and is the least secret-free way to prepare a dedicated test account. The
runner may offer this as an explicit opt-in, never as an implicit mutation.

The documented subscription route is `POST /api-gateway/subscriptions` with a
subscription object and card-shaped data, but it requires payment-like values and
would put sensitive inputs in command history or logs. It is not the default. If
premium cannot be established through the explicit user update, the command must
stop with a clear prerequisite error and must not run a free-account 177-second
upload. The runner must never commit credentials or card data.

## Decision: Use result polling for completion and container logs for B's start

The project service commits results only after all output records are stored and
then emits an `update-client-process-*` notification. The notification has no
documented completion payload, so the runner polls
`GET .../process/url` until the expected result count is reached for each project.
This avoids treating an accepted request as final output.

The runner records A and B submission timestamps immediately before their process
requests. It starts collecting:

```text
docker logs --timestamps --since <run-start> picturas-video_tool-1
```

The log timestamp is UTC. The first line matching
`[video] msg=request-... preview=False tools=['brightness']` is B's processing
start. The first line matching `preview=False tools=['subtitles']` identifies A.
The runner computes:

```text
B wait = first brightness log timestamp - B submission timestamp
```

The RabbitMQ queue samples remain useful confirmation that A and B messages were
queued and acknowledged, but they no longer estimate B's processing start.

## Decision: Sample RabbitMQ management and Docker stats on the host

Reuse the existing one-second sampling logic:

- `GET http://localhost:15672/api/queues/%2F/video_queue` with management
  Basic Auth, reading `messages_ready` and `messages_unacknowledged`.
- `docker stats --no-stream` for the configured video-worker container, parsing
  CPU percent and memory usage.

Credentials, queue username, and container name must be supplied by environment
variables or command arguments with local defaults documented, never stored in the
repository. The repository verifies `user/password` against
`evaluation/sample_baseline.sh`, and verifies the container name
`picturas-video_tool-1`. Both remain configurable by environment variable. The
worker's `basic_qos(prefetch_count=1)` and manual ack-at-end explain why
ready/unacknowledged depth is relevant.

## Decision: Treat HTTP 409 as a failed run, not an automatic retry

All mutation requests use the latest version returned by the preceding response.
If any request returns `409 Project version conflict`, record the endpoint, project,
expected version, server version, and response body. A fresh project is then
invalidated; the runner must not retry against an unknown state or reuse an old
project. This preserves the baseline's validity.

## Decision: Summaries use mean and min/max

The Portuguese scenario requires aggregate mean and minimum/maximum for the three
valid runs. The runner also retains each raw run and per-run summary. Standard
deviation from the earlier draft is not required by this plan; if later required
by the NFR, it can be added without changing collection semantics.

## Verified and unverified boundaries

Verified in source and local evaluation configuration:

- Gateway route prefixes, JWT protection, mutation headers, project version
  middleware, media upload field names, tool bodies, result URL shape, worker
  queue name and prefetch behavior, progress event fields.
- RabbitMQ management port `15672`, credentials `user/password` as used and
  validated by `evaluation/sample_baseline.sh`, container
  `picturas-video_tool-1`, and HTTPS gateway port `8080`.
- Docker Compose video limits: free accounts allow 60 seconds and 100 MB;
  premium accounts allow 600 seconds and 1024 MB. The 177-second A video
  therefore requires a premium account.

Por verificar before implementation:

- Whether configured environment variables override the source-code video limits.
