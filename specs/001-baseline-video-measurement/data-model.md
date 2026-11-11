# Data Model: Video Processing Baseline Measurement

## ScenarioRun

Represents one warm-up or measured execution.

| Field | Type | Rules |
|---|---|---|
| `run_id` | string | Unique and filesystem-safe. |
| `kind` | enum | `warmup` or `measured`. |
| `status` | enum | `running`, `valid`, `invalid`, or `incomplete`. |
| `started_at` | UTC timestamp | Set before project creation. |
| `ended_at` | UTC timestamp | Set on completion or failure. |
| `error` | nullable string/object | Required for invalid or incomplete runs. |
| `environment` | object | Host, stack reference, sampling interval, queue, container, and tool versions; no secrets. |

Relationships: one run owns exactly two `WorkloadProject` records and many
`ResourceSample` records.

## WorkloadProject

Represents project A or B created exclusively for one run.

| Field | Type | Rules |
|---|---|---|
| `label` | enum | `A` or `B`. |
| `project_id` | string | Must be newly returned by project creation. |
| `version` | integer | Replace after every successful mutation. |
| `submission_at` | UTC timestamp | Immediately around the process request. |
| `processing_start_at` | nullable UTC timestamp | Timestamp of the first qualifying queue transition for B; unavailable for A. |
| `finished_at` | nullable UTC timestamp | Results satisfy expected count. |
| `expected_results` | integer | A: 1; B: 3. |
| `duration_seconds` | nullable number | `finished_at - submission_at`. |
| `wait_seconds` | nullable number | B only: `processing_start_at - submission_at`; includes sampling uncertainty. |

Validation: A must contain one named long video and `subtitles`; B must contain
two uploads of the 10-second MP4, one 6-second MOV, and `brightness`. A and B
must have distinct project IDs.

## ResourceSample

Timestamped observation while either process is active.

| Field | Type | Rules |
|---|---|---|
| `timestamp` | UTC timestamp | Monotonic collection order plus wall clock. |
| `ready` | integer | RabbitMQ `messages_ready`, non-negative. |
| `unacked` | integer | RabbitMQ `messages_unacknowledged`, non-negative. |
| `cpu_percent` | number | Parsed Docker CPU percentage. |
| `memory_bytes` | integer | Parsed memory usage converted to bytes. |

Sampling target is approximately one second; missing observations are recorded,
not silently filled. B's start marker is the first ready-count decrease after B's
three messages are enqueued while A is still the active unacknowledged job.

## RunSummary

Derived record written after a valid or invalid run.

| Field | Type | Derivation |
|---|---|---|
| `a_duration_seconds` | number | A finish minus A submission. |
| `b_duration_seconds` | number | B finish minus B submission. |
| `b_wait_seconds` | number | B processing start minus B submission. |
| `makespan_seconds` | number | Max(A finish, B finish) minus A submission. |
| `max_ready` | integer | Maximum valid resource sample `ready`. |
| `max_unacked` | integer | Maximum valid resource sample `unacked`. |
| `peak_cpu_percent` | number | Maximum valid CPU sample. |
| `peak_memory_bytes` | integer | Maximum valid memory sample. |
| `status` | enum | Valid only when all required timestamps/results exist. |

## AggregateSummary

Computed only over valid measured runs, excluding warm-up and invalid runs.
For each metric, retain `mean`, `minimum`, `maximum`, and `count`; fail the
command if the requested count of valid runs was not obtained.
