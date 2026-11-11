# HTTP and Observation Contract

## Project mutation protocol

Every project mutation must send:

```text
Authorization: <JWT>
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

and accepts completion only when the returned result list contains the expected
number of results. Processing start for B is estimated from the first qualifying
RabbitMQ ready-count transition after its three messages are enqueued. The
transition timestamp and sampling interval must be retained with the estimate.

## Sampling protocol

RabbitMQ management response fields:

```json
{
  "messages_ready": 0,
  "messages_unacknowledged": 0
}
```

Docker statistics must be normalized to numeric CPU percent and memory bytes.
Malformed or missing samples are errors in the raw record, not zero values.
