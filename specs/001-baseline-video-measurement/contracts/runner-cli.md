# Runner CLI Contract

The planned command is:

```text
python3 evaluation/run_scenario.py \
  --runs 3 \
  --warmup 1 \
  --api-base https://localhost:8080/api-gateway \
  --email "$PICTURAS_EMAIL" \
  --password-env PICTURAS_PASSWORD \
  --rabbit-user-env RABBITMQ_MANAGEMENT_USER \
  --rabbit-password-env RABBITMQ_MANAGEMENT_PASSWORD
```

The implementation must prefer environment variables for secrets. It must not
print password values, JWTs, card data, or authorization headers.

Options must support measured run count and warm-up count, API base URL and local
certificate policy, sample paths, queue URL and name, RabbitMQ management
credentials, video container, evidence output directory, sampling interval, and
process/observation timeouts.

Exit status:

- `0`: requested warm-up and measured runs completed with the requested number of
  valid measured runs;
- non-zero: prerequisite failure, invalid/incomplete run, missing valid run, or
  summary failure.

Output must include a per-run table and an aggregate table with mean and min/max
for A duration, B duration, B wait, makespan, max ready, max unacked, peak CPU,
and peak memory.
