# HTTP and Observation Contract

## Project mutation protocol

Versioned project mutations must send these headers. Project creation returns its initial version.

```text
Authorization: Bearer <JWT>
X-Project-Version: <integer>
```

On success, the runner must replace its stored version with the integer in
`X-Project-Version`. A `409` response is terminal for that run and must preserve
the response JSON.

## Completion protocol

The runner polls:

```text
GET /projects/{user}/{project}/process/url
```

and currently accepts completion when the result count reaches or exceeds the
expected count (one for A, three for B). Exact counts and uniqueness for final
acceptance are por confirmar (see [audit F6](../../../docs/fase-2-auditoria.md)).

B's processing start is the earliest matching UTC brightness log timestamp across
observed worker replicas. The runner retains the matching logs and submission time.
Queue depth corroborates the observation.

## Sampling protocol

RabbitMQ management response fields:

```json
{
  "messages_ready": 0,
  "messages_unacknowledged": 0
}
```

Docker statistics use CPU percent and memory bytes. Each observation retains
per-replica values and group sums. Malformed or missing samples are recorded as
errors in the raw evidence.
