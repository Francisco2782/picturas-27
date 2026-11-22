# Quickstart: Baseline Video Measurement

Follow the [evaluation guide](../../evaluation/README.md) for sample files, local
credentials, Compose configuration, commands and evidence output. Use one worker
for the baseline and two for the final capacity scenario. Keep workload and
observation settings comparable.

To summarize existing evidence from the repository root, pass the number of
required valid measured runs.

```sh
python3 evaluation/summarize.py path/to/evidence --runs 3
```

B's processing start comes from the earliest matching brightness log across the
observed worker replicas. RabbitMQ queue samples corroborate the observation.
See the [Phase 2 specification](../002-nfr-improvement/spec.md) for the official
measurement and acceptance criteria.
