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
| `projects` | object | Workload projects keyed by label A and B. |
| `log_matches` | list | Matching UTC worker logs with replica identity. |

A valid run has two workload project records and many resource samples. Host and
stack metadata for the official baseline are recorded in its separate manifest.

## WorkloadProject

Represents project A or B created exclusively for one run.

| Field | Type | Rules |
|---|---|---|
| `label` | enum | `A` or `B`. |
| `project_id` | string | Must be newly returned by project creation. |
| `version` | integer | Replace after every successful mutation. |
| `submission_at` | UTC timestamp | Immediately around the process request. |
| `processing_start_at` | nullable UTC timestamp | B only. UTC timestamp of the earliest matching brightness log. |
| `finished_at` | nullable UTC timestamp | The result endpoint returns at least the expected count. |
| `expected_results` | integer | A: 1; B: 3. |
| `duration_seconds` | nullable number | `finished_at - submission_at`. |
| `wait_seconds` | nullable number | Reserved on the project record. The runner calculates B's wait in `summary.json`. |

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
| `cpu_percent` | number | Sum of Docker CPU percentages across the worker group. |
| `memory_bytes` | integer | Sum of memory usage in bytes across the worker group. |

The `workers` field contains the observed container IDs, names, CPU and memory.
The sampling target is approximately one second. Missing observations are recorded
as errors. Queue samples corroborate B's log-based start marker.

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
| `peak_cpu_percent` | number | Maximum worker-group CPU sum across valid samples. |
| `peak_memory_bytes` | integer | Maximum worker-group memory sum across valid samples. |
| `status` | enum | Valid only when all required timestamps/results exist. |

The summary also retains per-worker CPU and memory peaks.

## AggregateSummary

Computed only over valid measured runs, excluding warm-up and invalid runs.
For each metric, retain `mean`, `minimum`, `maximum`, and `count`; fail the
command if the requested count of valid runs was not obtained.
